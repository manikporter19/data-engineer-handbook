# Snowflake Implementation

This directory contains Snowflake-compliant versions of the dimensional modeling homework with platform-specific optimizations.

## Key Differences from PostgreSQL

### 1. Data Types
- `TEXT` → `VARCHAR` (with appropriate lengths)
- `REAL` → `FLOAT` or `NUMBER(10,2)`
- `INTEGER` → `NUMBER(38,0)` (Snowflake default)
- Composite types → `VARIANT` or separate tables
- Arrays → `ARRAY` (Snowflake native) or `VARIANT`

### 2. Syntax Changes
- `IS DISTINCT FROM` → Works in Snowflake
- `IS NOT DISTINCT FROM` → Works in Snowflake
- `ON CONFLICT` → Use `MERGE` instead
- `CREATE TYPE` → Not supported (use VARCHAR with CHECK constraints)
- `::type` casting → Use `CAST(x AS type)` or `::`

### 3. Session Variables
```sql
-- Set variables
SET prev_year = 1970;
SET this_year = 1971;

-- Reference with $ prefix
WHERE current_year = $prev_year
```

### 4. MERGE Statement Pattern
```sql
MERGE INTO target_table t
USING source_query s
  ON t.key = s.key
WHEN MATCHED THEN
  UPDATE SET t.col = s.col
WHEN NOT MATCHED THEN
  INSERT (col1, col2) VALUES (s.col1, s.col2);
```

## File Mapping

| PostgreSQL File | Snowflake File | Notes |
|----------------|----------------|-------|
| `1_actors_table_ddl.sql` | `1_actors_table_ddl_snowflake.sql` | VARIANT for films array |
| `2_actors_cumulative_query.sql` | `2_actors_cumulative_snowflake.sql` | MERGE instead of INSERT + ON CONFLICT |
| `3_actors_history_scd_ddl.sql` | `3_actors_history_scd_ddl_snowflake.sql` | VARCHAR for enum |
| `4_actors_history_scd_backfill.sql` | `4_actors_history_scd_backfill_snowflake.sql` | Same logic, syntax adjusted |
| `5_actors_history_scd_incremental.sql` | `5_actors_history_scd_incremental_snowflake.sql` | MERGE for update + insert |

## Usage Examples

### Session Variables
```sql
SET prev_year = 1970;
SET this_year = 1971;

-- Run script
!source 2_actors_cumulative_snowflake.sql
```

### Snowflake Tasks
```sql
CREATE OR REPLACE TASK actors_cumulative_task
  WAREHOUSE = COMPUTE_WH
  SCHEDULE = 'USING CRON 0 2 1 1 * America/Los_Angeles' -- Yearly on Jan 1
AS
BEGIN
  SET prev_year = YEAR(CURRENT_DATE()) - 1;
  SET this_year = YEAR(CURRENT_DATE());
  
  -- Run cumulative update
  MERGE INTO actors ...
END;
```

### Stored Procedure
```sql
CREATE OR REPLACE PROCEDURE update_actors_scd(prev_year NUMBER, this_year NUMBER)
  RETURNS VARCHAR
  LANGUAGE SQL
AS
$$
BEGIN
  -- Cumulative update
  MERGE INTO actors t
  USING (
    WITH last_year AS (...)
    SELECT ...
  ) s
  ON t.actorid = s.actorid AND t.current_year = s.current_year
  WHEN MATCHED THEN UPDATE SET ...
  WHEN NOT MATCHED THEN INSERT ...;
  
  -- SCD incremental
  MERGE INTO actors_history_scd ...;
  
  RETURN 'Success';
END;
$$;

-- Execute
CALL update_actors_scd(1970, 1971);
```

## Performance Optimizations

### 1. Clustering Keys
```sql
ALTER TABLE actors 
  CLUSTER BY (actorid, current_year);

ALTER TABLE actors_history_scd 
  CLUSTER BY (actorid, end_date);
```

### 2. Search Optimization
```sql
ALTER TABLE actors_history_scd 
  ADD SEARCH OPTIMIZATION ON EQUALITY(actorid, quality_class);
```

### 3. Materialized Views
```sql
CREATE MATERIALIZED VIEW current_actor_quality AS
SELECT 
  actorid,
  actor,
  quality_class,
  is_active
FROM actors_history_scd
WHERE end_date = (SELECT MAX(current_year) FROM actors);
```

### 4. Result Caching
Snowflake automatically caches query results for 24 hours. Identical queries return instantly from cache.

## Cost Optimization

### 1. Warehouse Sizing
```sql
-- Use appropriate warehouse for workload
-- Cumulative updates: X-SMALL to SMALL
-- Backfill: MEDIUM to LARGE

ALTER WAREHOUSE COMPUTE_WH SET
  AUTO_SUSPEND = 60  -- seconds
  AUTO_RESUME = TRUE
  WAREHOUSE_SIZE = 'SMALL';
```

### 2. Partition Pruning
```sql
-- Year-based pruning
SELECT * 
FROM actors_history_scd
WHERE start_date >= 2020  -- Prunes older micro-partitions
```

## Migration Checklist

- [ ] Convert composite types to VARIANT or separate tables
- [ ] Replace ON CONFLICT with MERGE
- [ ] Update session variable syntax ($ prefix)
- [ ] Remove PostgreSQL-specific functions (e.g., `pg_typeof`)
- [ ] Test ARRAY operations (syntax may differ)
- [ ] Add clustering keys for performance
- [ ] Set up tasks for automation
- [ ] Configure warehouse auto-suspend
- [ ] Enable result caching
- [ ] Test with Snowflake's query profiler

## Testing in Snowflake

```sql
-- Create test database
CREATE DATABASE actors_test;
USE DATABASE actors_test;
CREATE SCHEMA dimensional_modeling;
USE SCHEMA dimensional_modeling;

-- Run DDL scripts
!source 1_actors_table_ddl_snowflake.sql
!source 3_actors_history_scd_ddl_snowflake.sql

-- Load test data
-- (Same test data as PostgreSQL version)

-- Run backfill
!source 4_actors_history_scd_backfill_snowflake.sql

-- Validate
SELECT * FROM actors_history_scd ORDER BY actorid, start_date;
```

## Monitoring

### Query Performance
```sql
-- View query history
SELECT *
FROM TABLE(INFORMATION_SCHEMA.QUERY_HISTORY())
WHERE QUERY_TEXT ILIKE '%actors%'
  AND START_TIME >= DATEADD(hour, -24, CURRENT_TIMESTAMP())
ORDER BY TOTAL_ELAPSED_TIME DESC;
```

### Cost Tracking
```sql
-- Warehouse usage
SELECT
  WAREHOUSE_NAME,
  SUM(CREDITS_USED) as total_credits,
  SUM(TOTAL_ELAPSED_TIME) / 1000 / 60 as minutes_used
FROM SNOWFLAKE.ACCOUNT_USAGE.WAREHOUSE_METERING_HISTORY
WHERE START_TIME >= DATEADD(day, -7, CURRENT_TIMESTAMP())
GROUP BY WAREHOUSE_NAME;
```

## Additional Resources

- [Snowflake SQL Reference](https://docs.snowflake.com/en/sql-reference.html)
- [MERGE Statement Guide](https://docs.snowflake.com/en/sql-reference/sql/merge.html)
- [Tasks and Scheduling](https://docs.snowflake.com/en/user-guide/tasks-intro.html)
- [Clustering Keys](https://docs.snowflake.com/en/user-guide/tables-clustering-keys.html)
- [Query Optimization](https://docs.snowflake.com/en/user-guide/performance-query.html)
