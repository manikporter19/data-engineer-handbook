-- Incremental query for actors_history_scd
-- Combines previous year's SCD data with new incoming data from actors table
-- This implements a non-snapshot SCD: extends unchanged records, closes and creates new records for changes

-- Note: Create this type once in a separate DDL script, or use CREATE TYPE IF NOT EXISTS
-- CREATE TYPE IF NOT EXISTS scd_type AS (
--     quality_class quality_class,
--     is_active BOOLEAN,
--     start_date INTEGER,
--     end_date INTEGER
-- );

-- Update existing unchanged records by extending their end_date
UPDATE actors_history_scd scd
SET end_date = 1971  -- Replace with actual year variable (e.g., :this_year)
FROM actors this_year
WHERE scd.actorid = this_year.actorid
  AND scd.end_date = 1970  -- Replace with actual year variable (e.g., :prev_year)
  AND scd.quality_class = this_year.quality_class
  AND scd.is_active = this_year.is_active
  AND this_year.current_year = 1971;  -- Replace with actual year variable

-- Insert new records for changed attributes (close old record, insert new)
INSERT INTO actors_history_scd (actor, actorid, quality_class, is_active, start_date, end_date)
WITH last_year_scd AS (
    SELECT * FROM actors_history_scd
    WHERE end_date = 1970  -- Replace with actual year variable (e.g., :prev_year)
),
this_year_data AS (
    SELECT * FROM actors
    WHERE current_year = 1971  -- Replace with actual year variable (e.g., :this_year)
),
changed_actors AS (
    -- Only actors who existed last year AND have changed attributes
    SELECT 
        ty.actor,
        ty.actorid,
        ty.quality_class,
        ty.is_active,
        ty.current_year
    FROM this_year_data ty
    JOIN last_year_scd ly
        ON ty.actorid = ly.actorid
    WHERE ty.quality_class <> ly.quality_class
        OR ty.is_active <> ly.is_active
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
FROM new_actors;
