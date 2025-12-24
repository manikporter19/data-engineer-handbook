-- Snowflake DDL for actors table
-- This table tracks actors with their films, quality class, and active status
--
-- Snowflake Notes:
-- - Uses VARIANT for films array (flexible schema)
-- - Uses VARCHAR with CHECK constraint instead of ENUM
-- - Session variables use $ prefix: $prev_year, $this_year

-- Films are stored as VARIANT array of objects
-- Each object: {film: string, votes: number, rating: number, filmid: string}

CREATE TABLE IF NOT EXISTS actors (
    actor VARCHAR(500) NOT NULL,  -- Display name, considered mutable (Type 1)
    actorid VARCHAR(100) NOT NULL,
    films VARIANT NOT NULL DEFAULT ARRAY_CONSTRUCT(),  -- Array of film objects
    quality_class VARCHAR(20) NOT NULL CHECK (quality_class IN ('star', 'good', 'average', 'bad')),
    is_active BOOLEAN NOT NULL DEFAULT FALSE,  -- FALSE when no films in current year
    current_year NUMBER(4,0) NOT NULL CHECK (current_year >= 1800 AND current_year <= 9999),
    PRIMARY KEY (actorid, current_year)
);

-- Index to speed up lookups by actorid alone (without year)
CREATE INDEX IF NOT EXISTS idx_actors_actorid ON actors(actorid);

-- Clustering key for better partition pruning
ALTER TABLE actors CLUSTER BY (actorid, current_year);

-- Performance note: The films VARIANT can grow large. Consider:
-- 1. Keeping only current year's films in this table
-- 2. Storing cumulative filmography in a separate table
-- 3. Using a separate film_actor junction table for large datasets

-- Example film VARIANT structure:
-- [
--   {"film": "Movie 1", "votes": 100, "rating": 8.5, "filmid": "F1"},
--   {"film": "Movie 2", "votes": 200, "rating": 7.8, "filmid": "F2"}
-- ]
