-- Backfill query for actors_history_scd
-- Populates the entire SCD table in a single query using window functions

INSERT INTO actors_history_scd (actor, actorid, quality_class, is_active, start_date, end_date)
WITH with_previous AS (
    SELECT 
        actor,
        actorid,
        current_year,
        quality_class,
        is_active,
        LAG(quality_class, 1) OVER (
            PARTITION BY actorid ORDER BY current_year
        ) <> quality_class 
        OR LAG(is_active, 1) OVER (
            PARTITION BY actorid ORDER BY current_year
        ) <> is_active
        OR LAG(quality_class, 1) OVER (
            PARTITION BY actorid ORDER BY current_year
        ) IS NULL
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
    MAX(actor) as actor,  -- Use MAX to pick a representative actor name per streak
    actorid,
    quality_class,
    is_active,
    MIN(current_year) as start_date,
    MAX(current_year) as end_date
FROM with_streaks
GROUP BY actorid, streak_identifier, quality_class, is_active;
