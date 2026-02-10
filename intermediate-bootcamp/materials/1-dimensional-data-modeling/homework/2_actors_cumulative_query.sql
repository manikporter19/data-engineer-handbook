-- Cumulative table generation query for actors table
-- Populates the actors table one year at a time using FULL OUTER JOIN pattern
--
-- Assumptions:
-- 1. Runs year-by-year without gaps (current_year = prev_year + 1)
-- 2. Idempotent: can be re-run for the same year safely (ON CONFLICT)
-- 3. Actor name is Type 1 (always reflects current spelling)
-- 4. quality_class carried forward for inactive actors (can be changed if needed)
--
-- Parameterization:
-- psql: \set prev_year 1969; \set this_year 1970
-- dbt: {{ var('prev_year') }}, {{ var('this_year') }}

INSERT INTO actors (actor, actorid, films, quality_class, is_active, current_year)
WITH last_year AS (
    SELECT * FROM actors
    WHERE current_year = 1969  -- Replace: :prev_year or {{ var('prev_year') }}
),
this_year AS (
    SELECT 
        actor,
        actorid,
        -- Order by votes DESC, filmid for deterministic results
        -- Consider DISTINCT ON (filmid) if films can appear in multiple years
        ARRAY_AGG(ROW(film, votes, rating, filmid)::films ORDER BY votes DESC, filmid) as films,
        -- Use NUMERIC for better precision stability across aggregates
        AVG(rating::numeric) as avg_rating,
        year
    FROM actor_films
    WHERE year = 1970  -- Replace: :this_year or {{ var('this_year') }}
    GROUP BY actor, actorid, year
)
SELECT
    -- Actor name: Type 1 semantics (always current spelling)
    COALESCE(ty.actor, ly.actor) as actor,
    COALESCE(ly.actorid, ty.actorid) as actorid,
    -- Films: cumulative array concatenation
    -- Note: If filmid can repeat across years, consider deduping with DISTINCT
    COALESCE(ly.films, ARRAY[]::films[]) || 
        CASE WHEN ty.year IS NOT NULL THEN ty.films 
        ELSE ARRAY[]::films[] END as films,
    -- quality_class: derived from current year's rating when active
    CASE 
        WHEN ty.year IS NOT NULL THEN
            CASE 
                WHEN ty.avg_rating > 8 THEN 'star'
                WHEN ty.avg_rating > 7 THEN 'good'
                WHEN ty.avg_rating > 6 THEN 'average'
                ELSE 'bad'
            END::quality_class
        -- Carry forward quality_class when inactive (business rule confirmed)
        ELSE ly.quality_class
    END as quality_class,
    -- is_active: TRUE if actor has films this year
    CASE 
        WHEN ty.year IS NOT NULL THEN TRUE
        ELSE FALSE
    END as is_active,
    -- Assumes year-by-year processing (no gaps)
    COALESCE(ty.year, ly.current_year + 1) as current_year
FROM last_year ly
FULL OUTER JOIN this_year ty
    ON ly.actorid = ty.actorid
-- Idempotency: prevent PK violations on retry (Postgres 9.5+)
ON CONFLICT (actorid, current_year) DO NOTHING;
