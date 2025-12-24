-- dbt model: actors_history_scd backfill
-- File: models/actors_history_scd_backfill.sql
--
-- This populates the SCD table in one shot from the actors table
-- Run once to backfill historical data

{{ config(
    materialized='table',
    schema='analytics',
    alias='actors_history_scd',
    full_refresh=true
) }}

WITH with_previous AS (
    SELECT 
        actor,
        actorid,
        current_year,
        quality_class,
        is_active,
        (ROW_NUMBER() OVER (PARTITION BY actorid ORDER BY current_year) = 1)
        OR (LAG(quality_class) OVER (PARTITION BY actorid ORDER BY current_year) IS DISTINCT FROM quality_class)
        OR (LAG(is_active) OVER (PARTITION BY actorid ORDER BY current_year) IS DISTINCT FROM is_active)
        AS did_change
    FROM {{ ref('actors_cumulative') }}
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
    MAX(actor) as actor,
    actorid,
    quality_class,
    is_active,
    MIN(current_year) as start_date,
    MAX(current_year) as end_date
FROM with_streaks
GROUP BY actorid, streak_identifier, quality_class, is_active

-- Usage:
-- dbt run --models actors_history_scd_backfill --full-refresh
