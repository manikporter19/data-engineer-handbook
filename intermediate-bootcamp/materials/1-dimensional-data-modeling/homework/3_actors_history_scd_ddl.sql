-- DDL for actors_history_scd table
-- Implements Type 2 Slowly Changing Dimension to track changes in quality_class and is_active

CREATE TABLE actors_history_scd (
    actor TEXT,
    actorid TEXT,
    quality_class quality_class,
    is_active BOOLEAN,
    start_date INTEGER,
    end_date INTEGER,
    current_year INTEGER,
    PRIMARY KEY (actorid, start_date)
);
