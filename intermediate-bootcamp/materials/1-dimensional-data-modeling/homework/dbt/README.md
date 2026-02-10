# Dimensional Data Modeling - Enhanced SQL & dbt Versions

This directory contains production-ready SQL queries and dbt models for dimensional data modeling with actors data, implementing cumulative tables and Type 2 Slowly Changing Dimensions.

## Overview

All improvements requested in code review have been implemented:
- ✅ Null-safe comparisons using `IS DISTINCT FROM`
- ✅ Parameterized queries (ready for psql variables or dbt)
- ✅ Idempotency via `ON CONFLICT DO NOTHING`
- ✅ Additional constraints (NOT NULL, CHECK, indexes)
- ✅ Transaction safety documentation
- ✅ Type 1 semantics for actor names
- ✅ Enhanced documentation and comments

## File Structure

### SQL Files (PostgreSQL)
Located in the parent `homework/` directory:

1. **1_actors_table_ddl.sql** - Actors table DDL
   - Creates custom types: `films`, `quality_class`
   - Adds NOT NULL constraints on all appropriate columns
   - Includes CHECK constraint for year range (1800-9999)
   - Creates index on `actorid` for efficient lookups
   - Documents array growth considerations

2. **2_actors_cumulative_query.sql** - Cumulative table generation
   - Parameterized years (replace hardcoded 1969/1970)
   - ON CONFLICT for idempotency
   - Uses NUMERIC for rating precision
   - Documents business rules (quality_class carry-forward)
   - Comments on film deduplication considerations

3. **3_actors_history_scd_ddl.sql** - SCD table DDL
   - NOT NULL constraints on quality_class and is_active
   - CHECK constraint: `start_date <= end_date`
   - Index on `(actorid, end_date)` for effective-dating queries
   - Documents open-ended vs closed range decision
   - Optional exclusion constraint to prevent overlapping intervals

4. **4_actors_history_scd_backfill.sql** - SCD backfill
   - Null-safe change detection using `IS DISTINCT FROM`
   - Proper first-row handling with `ROW_NUMBER() = 1`
   - Uses MAX(actor) for representative name per streak
   - Fixed grouping to avoid splitting on actor name changes

5. **5_actors_history_scd_incremental.sql** - SCD incremental updates
   - Parameterized years throughout
   - IS NOT DISTINCT FROM for null-safe equality checks
   - ON CONFLICT for idempotency
   - Type 1 actor name updates in UPDATE clause
   - Transaction wrapper documentation
   - Data model assumptions documented

### dbt Models
Located in the `dbt/` subdirectory:

- **dbt_project.yml** - Project configuration with vars and model configs
- **macros.sql** - Reusable macros for type creation and constraint management
- **actors_table_ddl.sql** - dbt version of table creation
- **actors_cumulative.sql** - dbt incremental model
- **actors_history_scd_ddl.sql** - dbt SCD table creation
- **actors_history_scd_backfill.sql** - dbt backfill model
- **actors_history_scd_incremental.sql** - dbt incremental SCD model

## Usage

### PostgreSQL (psql)

Set variables and run:
```bash
psql -v prev_year=1970 -v this_year=1971 -f 2_actors_cumulative_query.sql
```

Or use interactive variables:
```sql
\set prev_year 1970
\set this_year 1971
\i 2_actors_cumulative_query.sql
```

### dbt

1. Install dependencies:
```bash
dbt deps
```

2. Run with variables:
```bash
# Initial backfill
dbt run --models actors_history_scd_backfill --full-refresh

# Incremental updates
dbt run --models actors_cumulative actors_history_scd_incremental \
  --vars '{"prev_year": 1970, "this_year": 1971}'
```

3. Run custom macros:
```bash
# Add constraints after table creation
dbt run-operation add_scd_constraints --args '{table_name: analytics.actors_history_scd}'
dbt run-operation add_actors_constraints --args '{table_name: analytics.actors_cumulative}'
```

## Key Improvements

### 1. Null Safety
All comparison operations use `IS DISTINCT FROM` / `IS NOT DISTINCT FROM` instead of `<>` / `=` to handle NULL values correctly.

**Before:**
```sql
WHERE quality_class <> ly.quality_class
```

**After:**
```sql
WHERE quality_class IS DISTINCT FROM ly.quality_class
```

### 2. Idempotency
All INSERT statements include `ON CONFLICT DO NOTHING` to prevent errors on retry.

**Example:**
```sql
INSERT INTO actors (...)
SELECT ...
ON CONFLICT (actorid, current_year) DO NOTHING;
```

### 3. Parameterization
All hardcoded years replaced with variables.

**psql:**
```sql
WHERE current_year = :prev_year
```

**dbt:**
```sql
WHERE current_year = {{ var('prev_year') }}
```

### 4. Enhanced Constraints
- NOT NULL on all appropriate columns
- CHECK constraints for valid ranges
- Indexes for performance
- Foreign key considerations documented

### 5. Type 1 Actor Names
Actor names are updated in place (Type 1) in the UPDATE statement:
```sql
UPDATE actors_history_scd scd
SET end_date = :this_year,
    actor = this_year.actor  -- Type 1 update
```

## Data Model Notes

### Assumptions
1. **Year-by-year processing**: Queries assume no gaps between years
2. **Always present**: actors table contains all actors every year (with is_active=false when no films)
3. **Closed ranges**: SCD uses closed date ranges (both start_date and end_date set)
4. **Actor names**: Type 1 semantics (always current spelling, not tracked in SCD)

### Schema Evolution
**Enum types** (`quality_class`) complicate schema evolution. To add new values:
```sql
ALTER TYPE quality_class ADD VALUE 'legendary' AFTER 'star';
```

Consider using a lookup table + FK instead:
```sql
CREATE TABLE quality_classes (
    class_name TEXT PRIMARY KEY,
    min_rating NUMERIC,
    max_rating NUMERIC
);

ALTER TABLE actors 
  DROP COLUMN quality_class,
  ADD COLUMN quality_class TEXT REFERENCES quality_classes(class_name);
```

### Performance Considerations
**Films array**: Can grow very large over many years
- Monitor table size with `pg_table_size()`
- Consider splitting into separate fact table
- Or keep only recent N years in main table

**Indexes**: The queries benefit from:
- `idx_actors_actorid` - for lookups without year
- `idx_actors_history_scd_effective_date` - for point-in-time queries

## Transaction Safety

Wrap UPDATE + INSERT operations in transactions:
```sql
BEGIN;
  -- Run 5_actors_history_scd_incremental.sql
COMMIT;
```

In dbt, models run in transactions automatically.

## Testing

Validate with sample data:
```sql
-- Year 1970
INSERT INTO actor_films VALUES 
  ('Actor A', 'A1', 'Film1', 1970, 100, 8.5, 'F1'),
  ('Actor B', 'B1', 'Film2', 1970, 200, 7.2, 'F2');

-- Year 1971 (A1 unchanged, B1 changed, C1 new)
INSERT INTO actor_films VALUES 
  ('Actor A', 'A1', 'Film3', 1971, 150, 8.6, 'F3'),
  ('Actor B', 'B1', 'Film4', 1971, 180, 6.8, 'F4'),
  ('Actor C', 'C1', 'Film5', 1971, 120, 7.5, 'F5');
```

Expected SCD results:
- A1: (1970, 1971, 'star', true) - extended
- B1: (1970, 1970, 'good', true) - closed
- B1: (1971, 1971, 'average', true) - new
- C1: (1971, 1971, 'good', true) - new

## Postgres Version Requirements

- **Minimum**: Postgres 9.5+ (for ON CONFLICT)
- **Recommended**: Postgres 10+ (for full window function support)
- **CREATE TYPE IF NOT EXISTS**: Postgres 9.3+

## Questions?

See [FIXES_APPLIED.md](../FIXES_APPLIED.md) for detailed documentation of all changes made in response to code review feedback.
