-- Snowflake version of incremental SCD update
-- Updates actors_history_scd for one new year
--
-- Parameterization:
--   SET prev_year = 1970; SET this_year = 1971;
--   Then run this script
--
-- Uses MERGE for idempotency (safe to re-run)

-- Step 1: Extend unchanged actors (UPDATE via MERGE)
MERGE INTO actors_history_scd scd
USING (
    SELECT actorid, actor, quality_class, is_active
    FROM actors
    WHERE current_year = $this_year
) this_year
ON scd.actorid = this_year.actorid
   AND scd.end_date = $prev_year
   AND scd.quality_class IS NOT DISTINCT FROM this_year.quality_class
   AND scd.is_active IS NOT DISTINCT FROM this_year.is_active
WHEN MATCHED THEN
    UPDATE SET
        scd.end_date = $this_year,
        scd.actor = this_year.actor;  -- Type 1: update to current spelling

-- Step 2: Insert changed and new actors (MERGE for idempotency)
MERGE INTO actors_history_scd scd
USING (
    WITH this_year_data AS (
        SELECT actorid, actor, quality_class, is_active
        FROM actors
        WHERE current_year = $this_year
    ),
    last_year_scd AS (
        SELECT actorid, actor, quality_class, is_active
        FROM actors_history_scd
        WHERE end_date = $prev_year
    ),
    -- Changed actors: existed last year but attributes changed
    changed_actors AS (
        SELECT 
            ty.actorid,
            ty.actor,
            ty.quality_class,
            ty.is_active
        FROM this_year_data ty
        INNER JOIN last_year_scd ly
            ON ty.actorid = ly.actorid
        WHERE ty.quality_class IS DISTINCT FROM ly.quality_class
           OR ty.is_active IS DISTINCT FROM ly.is_active
    ),
    -- New actors: didn't exist last year
    new_actors AS (
        SELECT 
            ty.actorid,
            ty.actor,
            ty.quality_class,
            ty.is_active
        FROM this_year_data ty
        LEFT JOIN last_year_scd ly
            ON ty.actorid = ly.actorid
        WHERE ly.actorid IS NULL
    ),
    -- Union changed and new
    actors_to_insert AS (
        SELECT * FROM changed_actors
        UNION ALL
        SELECT * FROM new_actors
    )
    SELECT
        actorid,
        actor,
        quality_class,
        is_active,
        $this_year AS start_date,
        $this_year AS end_date
    FROM actors_to_insert
) s
ON scd.actorid = s.actorid AND scd.start_date = s.start_date
WHEN NOT MATCHED THEN
    INSERT (actorid, actor, quality_class, is_active, start_date, end_date)
    VALUES (s.actorid, s.actor, s.quality_class, s.is_active, s.start_date, s.end_date);

-- Notes:
-- 1. Two-step process:
--    a) Extend unchanged actors (update end_date)
--    b) Insert changed and new actors
-- 2. Null-safe comparisons using IS DISTINCT FROM / IS NOT DISTINCT FROM
-- 3. MERGE provides idempotency (safe to re-run)
-- 4. Actor name is Type 1 (always updated to current spelling)
-- 5. Assumes year-by-year processing without gaps
-- 6. Transaction safety: Snowflake MERGE is atomic
--
-- Data model assumption:
-- The actors table always has a row per actor per year (with is_active=false
-- when absent). If you switch to a staging table with only "present" actors,
-- add logic to close SCD records for missing actors.
