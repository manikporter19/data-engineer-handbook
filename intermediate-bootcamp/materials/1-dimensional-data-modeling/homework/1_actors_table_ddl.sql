-- DDL for actors table
-- This table tracks actors with their films, quality class, and active status
-- 
-- Note on CREATE TYPE: In orchestrated environments (dbt), place these in a dedicated
-- pre-run schema change step (e.g., pre-hook or separate migration) to ensure they
-- execute before table creation.
--
-- Enum evolution: Adding new quality classes requires ALTER TYPE. Consider using a
-- lookup table + FK or CHECK constraint for more flexible schema evolution.

CREATE TYPE films AS (
    film TEXT,
    votes INTEGER,
    rating REAL,  -- Consider DOUBLE PRECISION or NUMERIC for better precision
    filmid TEXT
);

CREATE TYPE quality_class AS ENUM ('star', 'good', 'average', 'bad');

CREATE TABLE actors (
    actor TEXT NOT NULL,  -- Display name, considered mutable (Type 1)
    actorid TEXT NOT NULL,
    films films[] NOT NULL DEFAULT ARRAY[]::films[],
    quality_class quality_class NOT NULL,  -- Derived from rating, always set
    is_active BOOLEAN NOT NULL DEFAULT FALSE,  -- FALSE when no films in current year
    current_year INTEGER NOT NULL CHECK (current_year >= 1800 AND current_year <= 9999),
    PRIMARY KEY (actorid, current_year)
);

-- Index to speed up lookups by actorid alone (without year)
-- Useful for joining to other tables where year is not in the join key
CREATE INDEX idx_actors_actorid ON actors(actorid);

-- Performance note: The films array can grow large over many years. Consider:
-- 1. Keeping only current year's films in this table
-- 2. Storing cumulative filmography in a separate derived table
-- 3. Using a separate film_actor junction table for large datasets
