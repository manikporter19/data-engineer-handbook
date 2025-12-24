-- DDL for actors_history_scd table
-- Implements Type 2 Slowly Changing Dimension to track changes in quality_class and is_active
-- This is a non-snapshot SCD: rows are extended/updated in place, not re-inserted each year

CREATE TABLE actors_history_scd (
    actor TEXT,
    actorid TEXT NOT NULL,
    quality_class quality_class,
    is_active BOOLEAN,
    start_date INTEGER NOT NULL,
    end_date INTEGER NOT NULL,
    PRIMARY KEY (actorid, start_date)
);
