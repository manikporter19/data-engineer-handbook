{% macro create_custom_types() %}
    {# Macro to create custom PostgreSQL types needed for the actors models #}
    
    CREATE TYPE IF NOT EXISTS films AS (
        film TEXT,
        votes INTEGER,
        rating REAL,
        filmid TEXT
    );
    
    CREATE TYPE IF NOT EXISTS quality_class AS ENUM ('star', 'good', 'average', 'bad');
    
    {{ log('Custom types (films, quality_class) created successfully', info=true) }}
{% endmacro %}


{% macro add_scd_constraints(table_name) %}
    {# Macro to add constraints and indexes to the SCD table #}
    
    ALTER TABLE {{ table_name }} 
    ADD CONSTRAINT IF NOT EXISTS pk_actors_history_scd PRIMARY KEY (actorid, start_date);
    
    ALTER TABLE {{ table_name }}
    ALTER COLUMN actorid SET NOT NULL,
    ALTER COLUMN quality_class SET NOT NULL,
    ALTER COLUMN is_active SET NOT NULL,
    ALTER COLUMN start_date SET NOT NULL,
    ALTER COLUMN end_date SET NOT NULL;
    
    ALTER TABLE {{ table_name }}
    ADD CONSTRAINT IF NOT EXISTS chk_date_range CHECK (start_date <= end_date);
    
    CREATE INDEX IF NOT EXISTS idx_actors_history_scd_effective_date 
    ON {{ table_name }}(actorid, end_date);
    
    {{ log('Constraints and indexes added to ' ~ table_name, info=true) }}
{% endmacro %}


{% macro add_actors_constraints(table_name) %}
    {# Macro to add constraints and indexes to the actors table #}
    
    ALTER TABLE {{ table_name }}
    ALTER COLUMN actor SET NOT NULL,
    ALTER COLUMN actorid SET NOT NULL,
    ALTER COLUMN films SET NOT NULL,
    ALTER COLUMN films SET DEFAULT ARRAY[]::films[],
    ALTER COLUMN quality_class SET NOT NULL,
    ALTER COLUMN is_active SET NOT NULL,
    ALTER COLUMN is_active SET DEFAULT FALSE,
    ALTER COLUMN current_year SET NOT NULL;
    
    ALTER TABLE {{ table_name }}
    ADD CONSTRAINT IF NOT EXISTS chk_year_range 
    CHECK (current_year >= 1800 AND current_year <= 9999);
    
    CREATE INDEX IF NOT EXISTS idx_actors_actorid ON {{ table_name }}(actorid);
    
    {{ log('Constraints and indexes added to ' ~ table_name, info=true) }}
{% endmacro %}
