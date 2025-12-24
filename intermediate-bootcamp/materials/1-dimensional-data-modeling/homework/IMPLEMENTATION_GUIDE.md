# Dimensional Data Modeling Implementation Guide

## Table of Contents
1. [Overview](#overview)
2. [Target Platforms](#target-platforms)
3. [Parameterization Strategies](#parameterization-strategies)
4. [Data Model Semantics](#data-model-semantics)
5. [Testing Guide](#testing-guide)
6. [Deployment Patterns](#deployment-patterns)
7. [Performance Considerations](#performance-considerations)

---

## Overview

This guide provides comprehensive documentation for implementing Type 2 Slowly Changing Dimension (SCD) patterns for actor dimension modeling. The solution supports both PostgreSQL and Snowflake platforms with production-ready features including null safety, idempotency, and parameterization.

### Key Features
- **Null-safe comparisons**: All change detection uses `IS DISTINCT FROM`
- **Idempotent operations**: Safe to re-run with `ON CONFLICT` / `MERGE`
- **Fully parameterized**: No hardcoded years
- **Platform support**: PostgreSQL 10+ and Snowflake
- **Type 1 actor names**: Always reflects current spelling
- **Closed range semantics**: Inclusive start and end dates

---

## Target Platforms

### PostgreSQL
- **Version**: PostgreSQL 10 or higher
- **Required features**: 
  - `IS DISTINCT FROM` (9.3+)
  - `ON CONFLICT` (9.5+)
  - Composite types and arrays
  - Window functions

### Snowflake
- **Edition**: Standard or higher
- **Required features**:
  - `MERGE` statement
  - Session variables
  - VARIANT type support
  - Task parameters (for orchestration)

---

## Parameterization Strategies

### PostgreSQL with psql

**Session Variables:**
```bash
psql -v prev_year=1970 -v this_year=1971 -f 2_actors_cumulative_query.sql
```

**In SQL:**
```sql
-- Reference variables with colon prefix
WHERE current_year = :prev_year
```

**Function Wrapper (Alternative):**
```sql
CREATE OR REPLACE FUNCTION build_actors_cumulative(p_prev_year INT, p_this_year INT)
RETURNS void AS $$
BEGIN
  INSERT INTO actors (actorid, actor, films, quality_class, is_active, current_year)
  -- ... rest of query using p_prev_year and p_this_year
END;
$$ LANGUAGE plpgsql;

-- Execute
SELECT build_actors_cumulative(1970, 1971);
```

### dbt (Both PostgreSQL and Snowflake)

**dbt_project.yml:**
```yaml
vars:
  prev_year: 1970
  this_year: 1971
```

**In SQL models:**
```sql
-- Use Jinja template syntax
WHERE current_year = {{ var('prev_year') }}
AND year = {{ var('this_year') }}
```

**Runtime override:**
```bash
dbt run --models actors_cumulative \
  --vars '{"prev_year": 1970, "this_year": 1971}'
```

### Snowflake Session Variables

**Set variables:**
```sql
SET prev_year = 1970;
SET this_year = 1971;
```

**Reference in queries:**
```sql
WHERE current_year = $prev_year
AND year = $this_year
```

### Airflow / Orchestration

**Pass as parameters:**
```python
# Airflow DAG
from datetime import datetime

sql_params = {
    'prev_year': 1970,
    'this_year': 1971
}

postgres_operator = PostgresOperator(
    task_id='build_actors',
    sql='sql/2_actors_cumulative_query.sql',
    params=sql_params
)
```

**SQL with Airflow params:**
```sql
-- Use named parameters
WHERE current_year = %(prev_year)s
AND year = %(this_year)s
```

---

## Data Model Semantics

### Range Semantics

**Inclusive Start and End:**
- `start_date`: First year the actor had this quality_class/is_active combination
- `end_date`: Last year the actor had this quality_class/is_active combination
- Both dates are **inclusive** (closed range)

**Example:**
```
actorid | quality_class | is_active | start_date | end_date
--------|---------------|-----------|------------|----------
A1      | star          | true      | 1970       | 1972
A1      | good          | true      | 1973       | 1975
```
- Actor A1 was "star" in years 1970, 1971, and 1972
- Actor A1 was "good" in years 1973, 1974, and 1975

### Actor Name Handling (Type 1)

**Type 1 Semantics:**
- Actor name is **NOT tracked** as a changing attribute in SCD
- Actor name is always updated to reflect current spelling
- Name corrections/changes do NOT create new SCD records

**Implementation:**
```sql
-- In incremental update: update actor name to current
UPDATE actors_history_scd scd
SET end_date = :this_year,
    actor = this_year.actor  -- Always use current spelling
FROM actors this_year
WHERE scd.actorid = this_year.actorid
  AND scd.end_date = :prev_year
  AND scd.quality_class IS NOT DISTINCT FROM this_year.quality_class
  AND scd.is_active IS NOT DISTINCT FROM this_year.is_active;
```

**Alternative (Type 2 for Actor):**
If you need to track actor name changes, add to change detection:
```sql
-- Would create new SCD record on name change
WHERE ... OR scd.actor IS DISTINCT FROM this_year.actor
```

### Year-by-Year Processing Assumption

**Critical Assumption:**
The cumulative actors process **must run year-by-year without gaps**.

**Valid sequence:**
```
Year 1: Process 1970 data
Year 2: Process 1971 data (depends on 1970)
Year 3: Process 1972 data (depends on 1971)
```

**Invalid sequence (will break):**
```
Year 1: Process 1970 data
Year 2: Process 1972 data (skips 1971) ❌
```

**Protection (optional):**
```sql
-- Add validation
DO $$
DECLARE
  max_year INT;
BEGIN
  SELECT MAX(current_year) INTO max_year FROM actors;
  
  IF :this_year != max_year + 1 THEN
    RAISE EXCEPTION 'Year gap detected. Expected %, got %', 
      max_year + 1, :this_year;
  END IF;
END $$;
```

### Inactive Actor Handling

**Business Rule:**
When an actor has no films in a year (is_active = false), the quality_class from the previous year is **carried forward**.

**Rationale:**
- Preserves last known quality for dormant actors
- Simplifies SCD logic (fewer state transitions)
- Allows tracking of "inactive" periods

**Alternative:**
If you prefer to null quality_class when inactive:
```sql
CASE 
  WHEN ty.year IS NULL OR ty.is_active = false THEN NULL::quality_class
  WHEN AVG(rating) > 8 THEN 'star'::quality_class
  ...
END
```

---

## Testing Guide

### Sample Dataset

**Create test data:**
```sql
-- Source table
CREATE TABLE actor_films_test (
  actor TEXT,
  actorid TEXT,
  film TEXT,
  year INT,
  votes INT,
  rating REAL,
  filmid TEXT
);

-- Actor A: Star → Good → Inactive
INSERT INTO actor_films_test VALUES
  ('Actor A', 'A1', 'Film1', 1970, 100, 9.0, 'F1'),
  ('Actor A', 'A1', 'Film2', 1970, 150, 8.5, 'F2'),  -- Avg: 8.75 (star)
  ('Actor A', 'A1', 'Film3', 1971, 80, 7.5, 'F3'),
  ('Actor A', 'A1', 'Film4', 1971, 90, 7.2, 'F4'),   -- Avg: 7.35 (good)
  -- 1972: No films (inactive)
  ('Actor A', 'A1', 'Film5', 1973, 100, 8.2, 'F5');  -- Avg: 8.2 (star)

-- Actor B: Good → Retired → Returned
INSERT INTO actor_films_test VALUES
  ('Actor B', 'B1', 'Film6', 1970, 200, 7.8, 'F6'),  -- Avg: 7.8 (good)
  -- 1971-1972: No films (retired)
  ('Actor B', 'B1', 'Film7', 1973, 180, 7.5, 'F7');  -- Avg: 7.5 (good)

-- Actor C: New in 1971
INSERT INTO actor_films_test VALUES
  ('Actor C', 'C1', 'Film8', 1971, 120, 6.5, 'F8'),  -- Avg: 6.5 (average)
  ('Actor C', 'C1', 'Film9', 1972, 130, 6.8, 'F9');  -- Avg: 6.8 (average)
```

### Expected SCD Output

**After backfill (1970-1973):**
```
actorid | actor    | quality_class | is_active | start_date | end_date
--------|----------|---------------|-----------|------------|----------
A1      | Actor A  | star          | true      | 1970       | 1970
A1      | Actor A  | good          | true      | 1971       | 1971
A1      | Actor A  | good          | false     | 1972       | 1972
A1      | Actor A  | star          | true      | 1973       | 1973
B1      | Actor B  | good          | true      | 1970       | 1970
B1      | Actor B  | good          | false     | 1971       | 1972
B1      | Actor B  | good          | true      | 1973       | 1973
C1      | Actor C  | average       | true      | 1971       | 1972
```

### Validation Queries

**Count of SCD records by actor:**
```sql
SELECT actorid, COUNT(*) as scd_records
FROM actors_history_scd
GROUP BY actorid
ORDER BY actorid;

-- Expected: A1=4, B1=3, C1=1
```

**Verify no gaps in date ranges:**
```sql
WITH ranges AS (
  SELECT 
    actorid,
    start_date,
    end_date,
    LEAD(start_date) OVER (PARTITION BY actorid ORDER BY start_date) as next_start
  FROM actors_history_scd
)
SELECT *
FROM ranges
WHERE next_start IS NOT NULL 
  AND end_date + 1 != next_start;

-- Should return 0 rows (no gaps)
```

**Verify null safety:**
```sql
-- Test with NULL values
INSERT INTO actors (actorid, actor, quality_class, is_active, current_year)
VALUES ('N1', 'Null Actor', NULL, NULL, 1970);

-- Run incremental
-- Should handle without errors and create SCD record with NULLs
```

### Performance Testing

**Large dataset test:**
```sql
-- Generate 100K actors over 50 years
INSERT INTO actor_films_test
SELECT 
  'Actor ' || actor_id as actor,
  'A' || actor_id as actorid,
  'Film ' || film_id as film,
  year_val as year,
  (random() * 1000)::int as votes,
  (random() * 4 + 6)::real as rating,  -- 6.0-10.0
  'F' || film_id as filmid
FROM 
  generate_series(1, 100000) as actor_id,
  generate_series(1970, 2020) as year_val,
  generate_series(1, 3) as film_id
WHERE random() > 0.3;  -- ~70% active rate

-- Time backfill
\timing on
INSERT INTO actors_history_scd ...
-- Should complete in < 5 minutes for 100K actors
```

---

## Deployment Patterns

### Initial Setup (One-time)

**1. Create types and tables:**
```sql
-- Run 1_actors_table_ddl.sql
-- Run 3_actors_history_scd_ddl.sql
```

**2. Historical backfill:**
```sql
-- Run 4_actors_history_scd_backfill.sql
-- Processes all historical years at once
```

### Incremental Updates (Daily/Weekly/Yearly)

**1. Update cumulative actors table:**
```bash
psql -v prev_year=2023 -v this_year=2024 \
  -f 2_actors_cumulative_query.sql
```

**2. Update SCD table:**
```bash
psql -v prev_year=2023 -v this_year=2024 \
  -f 5_actors_history_scd_incremental.sql
```

### dbt Workflow

**models/schema.yml:**
```yaml
models:
  - name: actors_cumulative
    description: "Cumulative actors dimension with films array"
    config:
      materialized: incremental
      unique_key: ['actorid', 'current_year']
      on_schema_change: sync_all_columns
    
  - name: actors_history_scd
    description: "Type 2 SCD for actor quality tracking"
    config:
      materialized: incremental
      unique_key: ['actorid', 'start_date']
      on_schema_change: sync_all_columns
```

**Run order:**
```bash
# Full refresh (initial load)
dbt run --full-refresh --models actors_cumulative actors_history_scd_backfill

# Incremental (daily)
dbt run --models actors_cumulative actors_history_scd_incremental \
  --vars '{"prev_year": 2023, "this_year": 2024}'
```

### Airflow DAG

```python
from airflow import DAG
from airflow.providers.postgres.operators.postgres import PostgresOperator
from datetime import datetime, timedelta

default_args = {
    'owner': 'data-eng',
    'depends_on_past': True,
    'start_date': datetime(1970, 1, 1),
    'retries': 2,
    'retry_delay': timedelta(minutes=5),
}

with DAG(
    'actors_scd_pipeline',
    default_args=default_args,
    schedule_interval='@yearly',
    catchup=True,
) as dag:
    
    # Calculate years from execution date
    prev_year = "{{ execution_date.year - 1 }}"
    this_year = "{{ execution_date.year }}"
    
    update_cumulative = PostgresOperator(
        task_id='update_actors_cumulative',
        sql='sql/2_actors_cumulative_query.sql',
        params={'prev_year': prev_year, 'this_year': this_year}
    )
    
    update_scd = PostgresOperator(
        task_id='update_actors_scd',
        sql='sql/5_actors_history_scd_incremental.sql',
        params={'prev_year': prev_year, 'this_year': this_year}
    )
    
    update_cumulative >> update_scd
```

---

## Performance Considerations

### Array Growth Management

**Problem:**
The `films` array grows unbounded over years, potentially causing:
- Large row sizes (affects I/O and caching)
- Slow array operations
- Index bloat

**Solutions:**

**Option 1: Store only current year films**
```sql
-- In cumulative query, replace concatenation with current year only
films = ty.films  -- Instead of ly.films || ty.films
```

**Option 2: Separate filmography table**
```sql
CREATE TABLE actor_filmography (
  actorid TEXT NOT NULL,
  filmid TEXT NOT NULL,
  film TEXT,
  year INT,
  votes INT,
  rating REAL,
  PRIMARY KEY (actorid, filmid)
);

-- actors table stores only metadata
CREATE TABLE actors (
  actorid TEXT NOT NULL,
  actor TEXT NOT NULL,
  quality_class quality_class NOT NULL,
  is_active BOOLEAN NOT NULL,
  current_year INT NOT NULL,
  PRIMARY KEY (actorid, current_year)
);
```

**Option 3: Limit array size**
```sql
-- Keep only top N films by votes
films = ARRAY(
  SELECT ROW(film, votes, rating, filmid)::films
  FROM UNNEST(ly.films || ty.films) as f(film, votes, rating, filmid)
  ORDER BY votes DESC
  LIMIT 100
)
```

### Film Deduplication

**Problem:**
Same film might appear in multiple years (re-releases, corrections).

**Solution:**
```sql
-- Dedupe by filmid, keeping highest votes
WITH deduped_films AS (
  SELECT DISTINCT ON (filmid)
    ROW(film, votes, rating, filmid)::films as film_data
  FROM UNNEST(ly.films || ty.films) as f(film, votes, rating, filmid)
  ORDER BY filmid, votes DESC
)
SELECT ARRAY_AGG(film_data) as films
FROM deduped_films;
```

### Index Strategy

**Recommended indexes:**
```sql
-- actors table
CREATE INDEX idx_actors_actorid ON actors(actorid);
CREATE INDEX idx_actors_quality ON actors(quality_class) 
  WHERE is_active = true;

-- actors_history_scd table
CREATE INDEX idx_scd_actorid_end ON actors_history_scd(actorid, end_date);
CREATE INDEX idx_scd_dates ON actors_history_scd(start_date, end_date);
CREATE INDEX idx_scd_quality ON actors_history_scd(quality_class, is_active)
  WHERE end_date = (SELECT MAX(current_year) FROM actors);
```

### Query Optimization

**Effective-dating queries:**
```sql
-- Find current quality for actors as of specific year
SELECT actorid, actor, quality_class, is_active
FROM actors_history_scd
WHERE :query_year BETWEEN start_date AND end_date;

-- Uses idx_scd_dates efficiently
```

**Aggregate over time periods:**
```sql
-- Count years actor was "star"
SELECT 
  actorid,
  actor,
  SUM(end_date - start_date + 1) as years_as_star
FROM actors_history_scd
WHERE quality_class = 'star'
GROUP BY actorid, actor;
```

---

## Troubleshooting

### Common Issues

**1. Primary key violation on retry:**
```
ERROR:  duplicate key value violates unique constraint
```
**Solution:** Ensure `ON CONFLICT DO NOTHING` is present:
```sql
INSERT INTO actors_history_scd (...)
VALUES (...)
ON CONFLICT (actorid, start_date) DO NOTHING;
```

**2. NULL comparison unexpected behavior:**
```sql
-- Wrong: NULL <> 'star' returns NULL (not true!)
WHERE quality_class <> 'star'

-- Correct: Use IS DISTINCT FROM
WHERE quality_class IS DISTINCT FROM 'star'
```

**3. Type already exists error:**
```
ERROR:  type "quality_class" already exists
```
**Solution:** Use `CREATE TYPE IF NOT EXISTS` or run DDL once.

**4. Year gap detected:**
```
-- If you skip years, COALESCE might produce wrong year
COALESCE(ty.year, ly.current_year + 1)  -- Assumes no gaps!
```
**Solution:** Add validation or use explicit year parameters.

---

## Migration to Snowflake

See `snowflake/` directory for Snowflake-compliant versions with:
- `MERGE` instead of `UPDATE` + `INSERT`
- Session variable syntax (`$prev_year`)
- VARIANT type for flexible array storage
- Snowflake-specific optimizations

---

## References

- [PostgreSQL IS DISTINCT FROM Documentation](https://www.postgresql.org/docs/current/functions-comparison.html)
- [PostgreSQL ON CONFLICT Documentation](https://www.postgresql.org/docs/current/sql-insert.html)
- [dbt Variables Documentation](https://docs.getdbt.com/docs/building-a-dbt-project/building-models/using-variables)
- [Snowflake MERGE Documentation](https://docs.snowflake.com/en/sql-reference/sql/merge.html)
- [Type 2 SCD Best Practices](https://en.wikipedia.org/wiki/Slowly_changing_dimension#Type_2:_add_new_row)

---

**Last Updated:** 2024-12-24
**Version:** 1.0.0
**Authors:** Data Engineering Team
