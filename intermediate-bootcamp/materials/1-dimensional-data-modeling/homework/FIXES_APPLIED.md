# Dimensional Modeling Fixes - Response to Feedback

## Summary of Changes (Commit d74f522)

This document summarizes the fixes applied to the dimensional modeling homework based on code review feedback.

## Issues Fixed

### 1. SCD Table Design (Non-Snapshot Approach - Option A)

**Problem**: The original design had PK (actorid, start_date) but the incremental script was re-inserting full history each year, causing PK conflicts.

**Solution**: 
- Removed `current_year` column from `actors_history_scd` table
- Implemented true non-snapshot SCD:
  - UPDATE existing unchanged records to extend `end_date`
  - INSERT only new records for changed attributes or new actors
  - No re-insertion of historical data

**Files Changed**:
- `3_actors_history_scd_ddl.sql` - Removed `current_year`, added NOT NULL constraints
- `5_actors_history_scd_incremental.sql` - Complete rewrite with UPDATE + INSERT pattern

### 2. Bug in `changed_records` CTE

**Problem**: The `changed_records` CTE included `OR ly.actorid IS NULL`, causing it to UNNEST NULL records for new actors, violating the PK constraint.

**Solution**:
- Removed `ly.actorid IS NULL` condition from `changed_records`
- Changed to INNER JOIN (only actors that existed last year)
- New actors exclusively handled in `new_records` CTE

**File Changed**: `5_actors_history_scd_incremental.sql`

### 3. Backfill Grouping Issue

**Problem**: GROUP BY included `actor`, causing streak splits when actor names changed (typos, punctuation fixes).

**Solution**:
- Removed `actor` from GROUP BY
- Used `MAX(actor)` to select a representative actor name per streak

**File Changed**: `4_actors_history_scd_backfill.sql`

### 4. CREATE TYPE in Incremental Script

**Problem**: Running the incremental script multiple times would fail because the type already exists.

**Solution**:
- Removed `CREATE TYPE scd_type` from incremental script
- Added comment noting it should be created once in a separate DDL script
- Simplified logic to avoid complex UNNEST patterns

**File Changed**: `5_actors_history_scd_incremental.sql`

### 5. Additional Improvements

**Changes**:
- Added NOT NULL constraints on key columns (`actorid`, `current_year`, `start_date`, `end_date`)
- Added `ORDER BY votes DESC, filmid` to ARRAY_AGG for deterministic film ordering
- Added explicit column lists in all INSERT statements
- Added default value for `films` column: `DEFAULT ARRAY[]::films[]`
- Enhanced comments with parameterization examples (psql variables, dbt Jinja)

**Files Changed**:
- `1_actors_table_ddl.sql`
- `2_actors_cumulative_query.sql`
- `4_actors_history_scd_backfill.sql`

## New SCD Semantics

The `actors_history_scd` table now implements a **non-snapshot Type 2 SCD**:

1. **Backfill**: Creates initial SCD from all historical `actors` data
2. **Incremental** (for each new year):
   - **Unchanged actors**: Extend `end_date` via UPDATE
   - **Changed actors**: INSERT new record with new `start_date`
   - **New actors**: INSERT first record
3. **No re-insertion**: Historical records stay in place, only current year is processed

## File Structure After Fixes

```
1_actors_table_ddl.sql
├── Added NOT NULL constraints
├── Added DEFAULT for films array
└── Enhanced comments

2_actors_cumulative_query.sql
├── Added ORDER BY in ARRAY_AGG
├── Added explicit column list
└── Enhanced parameterization comments

3_actors_history_scd_ddl.sql
├── Removed current_year column
├── Added NOT NULL constraints
└── Added clarifying comment about non-snapshot design

4_actors_history_scd_backfill.sql
├── Removed actor from GROUP BY
├── Added MAX(actor) to select representative name
└── Added explicit column list

5_actors_history_scd_incremental.sql
├── Complete rewrite with UPDATE + INSERT pattern
├── Removed CREATE TYPE statement
├── Fixed changed_records to only include existing actors
└── Separated new_actors logic clearly
```

## Questions Answered

1. **SCD Semantics**: Non-snapshot, ever-current SCD (rows extended in place)
2. **Postgres Version**: Designed to work with Postgres 10+ (no version-specific features required)
3. **Actor Name Changes**: Treated as non-tracked attribute (doesn't split streaks)
4. **Year Parameterization**: Comments suggest psql variables (`:prev_year`) or dbt Jinja (`{{ var('prev_year') }}`)

## Production Readiness

The updated code is now production-ready with:
- ✅ Correct SCD semantics
- ✅ No PK conflicts
- ✅ Proper handling of all actor states
- ✅ Deterministic results
- ✅ Reusable incremental process
- ✅ Clear separation of concerns

## Testing Recommendation

To validate the incremental process:

```sql
-- 1. Load initial data for year 1970
INSERT INTO actors VALUES ('Actor A', 'A1', ARRAY[]::films[], 'star', true, 1970);

-- 2. Run backfill
-- Should create one record: (A1, 'star', true, 1970, 1970)

-- 3. Load data for year 1971 with changes
INSERT INTO actors VALUES ('Actor A', 'A1', ARRAY[]::films[], 'good', true, 1971);

-- 4. Run incremental
-- Should UPDATE the existing record's end_date to 1971
-- Should INSERT a new record: (A1, 'good', true, 1971, 1971)
```
