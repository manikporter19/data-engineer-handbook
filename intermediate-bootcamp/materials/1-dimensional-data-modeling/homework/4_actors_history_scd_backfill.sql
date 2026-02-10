-- Backfill query for actors_history_scd
-- Populates the entire SCD table in a single query using window functions
--
-- Key improvements:
-- 1. Null-safe change detection using IS DISTINCT FROM
-- 2. Deterministic actor name selection using FIRST_VALUE (or MAX as fallback)

INSERT INTO actors_history_scd (actor, actorid, quality_class, is_active, start_date, end_date)
WITH with_previous AS (
    SELECT 
        actor,
        actorid,
        current_year,
        quality_class,
        is_active,
        -- Null-safe change detection using IS DISTINCT FROM
        -- This correctly handles NULL values (if they ever occur despite NOT NULL constraints)
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
            OVER (PARTITION BY actorid ORDER BY current_year) as streak_identifier
    FROM with_previous
)
SELECT 
    -- Actor name: Use MAX as simple aggregation (or FIRST_VALUE for deterministic choice)
    -- Since actor is not tracked in SCD, this picks a representative name per streak
    MAX(actor) as actor,
    actorid,
    quality_class,
    is_active,
    MIN(current_year) as start_date,
    MAX(current_year) as end_date
FROM with_streaks
GROUP BY actorid, streak_identifier, quality_class, is_active;
