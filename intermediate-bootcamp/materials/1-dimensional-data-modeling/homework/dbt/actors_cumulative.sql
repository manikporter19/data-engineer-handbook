-- dbt model: actors cumulative table generation
-- File: models/actors_cumulative.sql
--
-- Configuration in model file:
{{ config(
    materialized='incremental',
    unique_key=['actorid', 'current_year'],
    on_schema_change='fail',
    schema='analytics'
) }}

-- Variables (set in dbt_project.yml or via --vars):
-- dbt run --vars '{"prev_year": 1969, "this_year": 1970}'

{% set prev_year = var('prev_year', 1969) %}
{% set this_year = var('this_year', 1970) %}

WITH last_year AS (
    SELECT * FROM {{ this }}
    WHERE current_year = {{ prev_year }}
    {% if is_incremental() %}
        -- Only look at previous year when running incrementally
    {% endif %}
),
this_year AS (
    SELECT 
        actor,
        actorid,
        ARRAY_AGG(ROW(film, votes, rating, filmid)::films ORDER BY votes DESC, filmid) as films,
        AVG(rating::numeric) as avg_rating,
        year
    FROM {{ source('raw', 'actor_films') }}
    WHERE year = {{ this_year }}
    GROUP BY actor, actorid, year
)
SELECT
    COALESCE(ty.actor, ly.actor) as actor,
    COALESCE(ly.actorid, ty.actorid) as actorid,
    COALESCE(ly.films, ARRAY[]::films[]) || 
        CASE WHEN ty.year IS NOT NULL THEN ty.films 
        ELSE ARRAY[]::films[] END as films,
    CASE 
        WHEN ty.year IS NOT NULL THEN
            CASE 
                WHEN ty.avg_rating > 8 THEN 'star'
                WHEN ty.avg_rating > 7 THEN 'good'
                WHEN ty.avg_rating > 6 THEN 'average'
                ELSE 'bad'
            END::quality_class
        ELSE ly.quality_class
    END as quality_class,
    CASE 
        WHEN ty.year IS NOT NULL THEN TRUE
        ELSE FALSE
    END as is_active,
    COALESCE(ty.year, ly.current_year + 1) as current_year
FROM last_year ly
FULL OUTER JOIN this_year ty
    ON ly.actorid = ty.actorid

-- dbt_project.yml entry:
-- models:
--   my_project:
--     actors_cumulative:
--       +materialized: incremental
--       +unique_key: ['actorid', 'current_year']
--       +on_schema_change: fail
