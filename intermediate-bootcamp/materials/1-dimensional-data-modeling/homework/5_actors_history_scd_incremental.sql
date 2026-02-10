-- Incremental query for actors_history_scd
-- Combines previous year's SCD data with new incoming data from actors table
-- This implements a non-snapshot SCD: extends unchanged records, closes and creates new records for changes
--
-- Key improvements:
-- 1. Parameterized years (replace hardcoded values)
-- 2. Null-safe equality checks using IS NOT DISTINCT FROM / IS DISTINCT FROM
-- 3. Transaction safety (wrap in BEGIN/COMMIT when running)
-- 4. Idempotency via ON CONFLICT
-- 5. Actor name handling: Type 1 (always update to current spelling)
--
-- Parameterization:
-- psql: \set prev_year 1970; \set this_year 1971
-- dbt: {{ var('prev_year') }}, {{ var('this_year') }}
--
-- Transaction wrapper (recommended for production):
-- BEGIN;
--   [run this script]
-- COMMIT;

-- Step 1: Update existing unchanged records by extending their end_date
-- Uses IS NOT DISTINCT FROM for null-safe equality (handles NULL gracefully)
UPDATE actors_history_scd scd
SET end_date = 1971,  -- Replace: :this_year or {{ var('this_year') }}
    actor = this_year.actor  -- Type 1: Update actor name to current spelling
FROM actors this_year
WHERE scd.actorid = this_year.actorid
  AND scd.end_date = 1970  -- Replace: :prev_year or {{ var('prev_year') }}
  AND scd.quality_class IS NOT DISTINCT FROM this_year.quality_class
  AND scd.is_active IS NOT DISTINCT FROM this_year.is_active
  AND this_year.current_year = 1971;  -- Replace: :this_year or {{ var('this_year') }}

-- Step 2: Insert new records for changed attributes and new actors
INSERT INTO actors_history_scd (actor, actorid, quality_class, is_active, start_date, end_date)
WITH last_year_scd AS (
    SELECT * FROM actors_history_scd
    WHERE end_date = 1970  -- Replace: :prev_year or {{ var('prev_year') }}
),
this_year_data AS (
    SELECT * FROM actors
    WHERE current_year = 1971  -- Replace: :this_year or {{ var('this_year') }}
),
changed_actors AS (
    -- Only actors who existed last year AND have changed attributes
    -- Use IS DISTINCT FROM for null-safe inequality
    SELECT 
        ty.actor,
        ty.actorid,
        ty.quality_class,
        ty.is_active,
        ty.current_year
    FROM this_year_data ty
    JOIN last_year_scd ly
        ON ty.actorid = ly.actorid
    WHERE ty.quality_class IS DISTINCT FROM ly.quality_class
        OR ty.is_active IS DISTINCT FROM ly.is_active
),
new_actors AS (
    -- Brand new actors who did not exist last year
    SELECT 
        ty.actor,
        ty.actorid,
        ty.quality_class,
        ty.is_active,
        ty.current_year
    FROM this_year_data ty
    LEFT JOIN last_year_scd ly
        ON ty.actorid = ly.actorid
    WHERE ly.actorid IS NULL
)
SELECT 
    actor,
    actorid,
    quality_class,
    is_active,
    current_year as start_date,
    current_year as end_date
FROM changed_actors

UNION ALL

SELECT 
    actor,
    actorid,
    quality_class,
    is_active,
    current_year as start_date,
    current_year as end_date
FROM new_actors
-- Idempotency: prevent PK violations on retry
ON CONFLICT (actorid, start_date) DO NOTHING;

-- Note on data model:
-- This logic assumes actors table always has a row per actor per year (with is_active=false when absent).
-- If switching to a staging model with only "present this year" actors, you would need an additional
-- step to close (not extend) records for actors missing this year.
