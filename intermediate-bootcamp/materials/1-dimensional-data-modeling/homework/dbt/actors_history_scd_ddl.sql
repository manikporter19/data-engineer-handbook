-- dbt model: actors_history_scd table DDL
-- File: models/actors_history_scd_ddl.sql
--
-- This creates the SCD table structure in dbt

{{ config(
    materialized='table',
    schema='analytics'
) }}

-- Create empty structure for the SCD table
SELECT 
    NULL::TEXT as actor,
    NULL::TEXT as actorid,
    NULL::quality_class as quality_class,
    NULL::BOOLEAN as is_active,
    NULL::INTEGER as start_date,
    NULL::INTEGER as end_date
WHERE FALSE

-- Post-hook to add constraints and indexes
-- {{ config(
--     post_hook=[
--         "ALTER TABLE {{ this }} 
--          ADD CONSTRAINT pk_actors_history_scd PRIMARY KEY (actorid, start_date),
--          ALTER COLUMN actorid SET NOT NULL,
--          ALTER COLUMN quality_class SET NOT NULL,
--          ALTER COLUMN is_active SET NOT NULL,
--          ALTER COLUMN start_date SET NOT NULL,
--          ALTER COLUMN end_date SET NOT NULL,
--          ADD CONSTRAINT chk_date_range CHECK (start_date <= end_date)",
--         "CREATE INDEX IF NOT EXISTS idx_actors_history_scd_effective_date 
--          ON {{ this }}(actorid, end_date)"
--     ]
-- ) }}

-- Macro for creating constraints (macros/add_scd_constraints.sql):
{% macro add_scd_constraints(table_name) %}
    ALTER TABLE {{ table_name }} 
    ADD CONSTRAINT IF NOT EXISTS pk_actors_history_scd PRIMARY KEY (actorid, start_date),
    ALTER COLUMN actorid SET NOT NULL,
    ALTER COLUMN quality_class SET NOT NULL,
    ALTER COLUMN is_active SET NOT NULL,
    ALTER COLUMN start_date SET NOT NULL,
    ALTER COLUMN end_date SET NOT NULL,
    ADD CONSTRAINT IF NOT EXISTS chk_date_range CHECK (start_date <= end_date);
    
    CREATE INDEX IF NOT EXISTS idx_actors_history_scd_effective_date 
    ON {{ table_name }}(actorid, end_date);
{% endmacro %}

-- Run with: dbt run-operation add_scd_constraints --args '{table_name: analytics.actors_history_scd}'
