-- Cumulative table generation query for actors table
-- Populates the actors table one year at a time using FULL OUTER JOIN pattern

INSERT INTO actors
WITH last_year AS (
    SELECT * FROM actors
    WHERE current_year = 1969  -- Replace with actual year variable
),
this_year AS (
    SELECT 
        actor,
        actorid,
        ARRAY_AGG(ROW(film, votes, rating, filmid)::films) as films,
        AVG(rating) as avg_rating,
        year
    FROM actor_films
    WHERE year = 1970  -- Replace with actual year variable
    GROUP BY actor, actorid, year
)
SELECT
    COALESCE(ly.actor, ty.actor) as actor,
    COALESCE(ly.actorid, ty.actorid) as actorid,
    COALESCE(ly.films, ARRAY[]::films[]) || 
        CASE WHEN ty.year IS NOT NULL THEN ty.films 
        ELSE ARRAY[]::films[] END as films,
    CASE 
        WHEN ty.year IS NOT NULL THEN
            CASE 
                WHEN ty.avg_rating > 8 THEN 'star'
                WHEN ty.avg_rating > 7 THEN 'good'
                WHEN ty.avg_rating > 6 THEN 'average'
                ELSE 'bad'
            END::quality_class
        ELSE ly.quality_class
    END as quality_class,
    CASE 
        WHEN ty.year IS NOT NULL THEN TRUE
        ELSE FALSE
    END as is_active,
    COALESCE(ty.year, ly.current_year + 1) as current_year
FROM last_year ly
FULL OUTER JOIN this_year ty
    ON ly.actorid = ty.actorid;
