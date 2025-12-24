-- DDL for actors table
-- This table tracks actors with their films, quality class, and active status

CREATE TYPE films AS (
    film TEXT,
    votes INTEGER,
    rating REAL,
    filmid TEXT
);

CREATE TYPE quality_class AS ENUM ('star', 'good', 'average', 'bad');

CREATE TABLE actors (
    actor TEXT,
    actorid TEXT NOT NULL,
    films films[] NOT NULL DEFAULT ARRAY[]::films[],
    quality_class quality_class,
    is_active BOOLEAN,
    current_year INTEGER NOT NULL,
    PRIMARY KEY (actorid, current_year)
);
