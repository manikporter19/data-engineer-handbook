-- Snowflake version of SCD backfill query
-- Populates actors_history_scd table from scratch using all actors history
--
-- Uses null-safe IS DISTINCT FROM for change detection

INSERT INTO actors_history_scd (actor, actorid, quality_class, is_active, start_date, end_date)
WITH with_previous AS (
    SELECT
        actor,
        actorid,
        current_year,
        quality_class,
        is_active,
        -- Null-safe change detection using IS DISTINCT FROM
        (ROW_NUMBER() OVER (PARTITION BY actorid ORDER BY current_year) = 1)
        OR (LAG(quality_class) OVER (PARTITION BY actorid ORDER BY current_year) IS DISTINCT FROM quality_class)
        OR (LAG(is_active) OVER (PARTITION BY actorid ORDER BY current_year) IS DISTINCT FROM is_active)
        AS did_change
    FROM actors
),
with_streaks AS (
    SELECT
        actor,
        actorid,
        current_year,
        quality_class,
        is_active,
        SUM(CASE WHEN did_change THEN 1 ELSE 0 END) 
            OVER (PARTITION BY actorid ORDER BY current_year) AS streak_identifier
    FROM with_previous
)
SELECT
    MAX(actor) AS actor,  -- Representative actor name (Type 1 - not tracked in SCD)
    actorid,
    quality_class,
    is_active,
    MIN(current_year) AS start_date,
    MAX(current_year) AS end_date
FROM with_streaks
GROUP BY actorid, streak_identifier, quality_class, is_active
ORDER BY actorid, start_date;

-- Notes:
-- 1. IS DISTINCT FROM handles NULL values correctly (NULL IS DISTINCT FROM 'star' = TRUE)
-- 2. Actor name: MAX(actor) picks representative name per streak
--    - Actor name changes don't split streaks (Type 1 semantic)
--    - Alternative: FIRST_VALUE(actor) OVER ... for deterministic selection
-- 3. Processes all years at once (historical backfill)
-- 4. For incremental updates, use 5_actors_history_scd_incremental_snowflake.sql
