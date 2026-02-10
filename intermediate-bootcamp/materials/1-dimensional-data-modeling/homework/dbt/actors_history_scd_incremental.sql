-- dbt model: actors_history_scd incremental
-- File: models/actors_history_scd_incremental.sql
--
-- This incrementally updates the SCD table
-- Run daily/yearly to process new actor data

{{ config(
    materialized='incremental',
    unique_key=['actorid', 'start_date'],
    on_schema_change='fail',
    schema='analytics',
    alias='actors_history_scd'
) }}

{% set prev_year = var('prev_year') %}
{% set this_year = var('this_year') %}

-- Step 1: Update unchanged records (extends end_date)
-- This happens as a pre-hook
{{ config(
    pre_hook=[
        "UPDATE {{ this }} scd
         SET end_date = {{ this_year }},
             actor = this_year.actor
         FROM {{ ref('actors_cumulative') }} this_year
         WHERE scd.actorid = this_year.actorid
           AND scd.end_date = {{ prev_year }}
           AND scd.quality_class IS NOT DISTINCT FROM this_year.quality_class
           AND scd.is_active IS NOT DISTINCT FROM this_year.is_active
           AND this_year.current_year = {{ this_year }}"
    ]
) }}

-- Step 2: Insert changed and new actors
WITH last_year_scd AS (
    SELECT * FROM {{ this }}
    WHERE end_date = {{ prev_year }}
    {% if is_incremental() %}
        -- Only process last year's records incrementally
    {% endif %}
),
this_year_data AS (
    SELECT * FROM {{ ref('actors_cumulative') }}
    WHERE current_year = {{ this_year }}
),
changed_actors AS (
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

-- Usage:
-- dbt run --models actors_history_scd_incremental --vars '{"prev_year": 1970, "this_year": 1971}'
