-- dbt model: actors table DDL
-- File: models/actors_table_ddl.sql
--
-- Configuration:
-- {{ config(
--     materialized='table',
--     pre_hook=[
--         "CREATE TYPE IF NOT EXISTS films AS (film TEXT, votes INTEGER, rating REAL, filmid TEXT)",
--         "CREATE TYPE IF NOT EXISTS quality_class AS ENUM ('star', 'good', 'average', 'bad')"
--     ]
-- ) }}
--
-- dbt_project.yml configuration:
-- models:
--   my_project:
--     actors:
--       +pre-hook:
--         - "CREATE TYPE IF NOT EXISTS films AS (film TEXT, votes INTEGER, rating REAL, filmid TEXT)"
--         - "CREATE TYPE IF NOT EXISTS quality_class AS ENUM ('star', 'good', 'average', 'bad')"

-- This is a DDL-only file. In dbt, you would typically create this via a macro or pre-hook.
-- See below for the recommended approach.

-- Option 1: Create via macro (macros/create_custom_types.sql)
{% macro create_custom_types() %}
    CREATE TYPE IF NOT EXISTS films AS (
        film TEXT,
        votes INTEGER,
        rating REAL,
        filmid TEXT
    );
    
    CREATE TYPE IF NOT EXISTS quality_class AS ENUM ('star', 'good', 'average', 'bad');
{% endmacro %}

-- Option 2: Use on-run-start in dbt_project.yml
-- on-run-start:
--   - "{{ create_custom_types() }}"

-- The actual table creation in dbt:
{{ config(
    materialized='table',
    schema='analytics'
) }}

-- For initial creation, you can use a dbt run-operation:
-- dbt run-operation create_actors_table

-- Alternatively, create an ephemeral model that returns the structure:
SELECT 
    NULL::TEXT as actor,
    NULL::TEXT as actorid,
    ARRAY[]::films[] as films,
    NULL::quality_class as quality_class,
    FALSE::BOOLEAN as is_active,
    NULL::INTEGER as current_year
WHERE FALSE

-- After first run, alter table to add constraints:
-- ALTER TABLE {{ this }} 
--   ADD CONSTRAINT pk_actors PRIMARY KEY (actorid, current_year),
--   ALTER COLUMN actor SET NOT NULL,
--   ALTER COLUMN actorid SET NOT NULL,
--   ALTER COLUMN films SET NOT NULL,
--   ALTER COLUMN films SET DEFAULT ARRAY[]::films[],
--   ALTER COLUMN quality_class SET NOT NULL,
--   ALTER COLUMN is_active SET NOT NULL,
--   ALTER COLUMN is_active SET DEFAULT FALSE,
--   ALTER COLUMN current_year SET NOT NULL,
--   ADD CONSTRAINT chk_year_range CHECK (current_year >= 1800 AND current_year <= 9999);

-- Create index:
-- CREATE INDEX IF NOT EXISTS idx_actors_actorid ON {{ this }}(actorid);
