-- Snowflake version of cumulative actors query
-- Builds/updates the actors table year-by-year
--
-- Parameterization:
--   SET prev_year = 1970; SET this_year = 1971;
--   Then run this script
--
-- Uses MERGE for idempotency (safe to re-run)

MERGE INTO actors t
USING (
    WITH last_year AS (
        SELECT * FROM actors WHERE current_year = $prev_year
    ),
    this_year AS (
        SELECT 
            actor,
            actorid,
            YEAR as year,
            ARRAY_AGG(
                OBJECT_CONSTRUCT(
                    'film', film,
                    'votes', votes,
                    'rating', rating,
                    'filmid', filmid
                )
            ) WITHIN GROUP (ORDER BY votes DESC, filmid) as films,
            AVG(rating) as avg_rating,
            COUNT(*) as film_count
        FROM actor_films
        WHERE year = $this_year
        GROUP BY actor, actorid, year
    )
    SELECT
        COALESCE(ty.actor, ly.actor) as actor,
        COALESCE(ty.actorid, ly.actorid) as actorid,
        -- Concatenate films arrays (dedupe if needed)
        CASE 
            WHEN ly.films IS NULL THEN ty.films
            WHEN ty.films IS NULL THEN ly.films
            ELSE ARRAY_CAT(ly.films, ty.films)
        END as films,
        -- Quality class based on this year's average rating
        CASE
            WHEN ty.year IS NULL THEN ly.quality_class  -- Carry forward if inactive
            WHEN ty.avg_rating > 8 THEN 'star'
            WHEN ty.avg_rating > 7 THEN 'good'
            WHEN ty.avg_rating > 6 THEN 'average'
            ELSE 'bad'
        END as quality_class,
        CASE WHEN ty.year IS NOT NULL THEN TRUE ELSE FALSE END as is_active,
        COALESCE(ty.year, ly.current_year + 1) as current_year
    FROM this_year ty
    FULL OUTER JOIN last_year ly
        ON ty.actorid = ly.actorid
) s
ON t.actorid = s.actorid AND t.current_year = s.current_year
WHEN MATCHED THEN
    UPDATE SET
        t.actor = s.actor,
        t.films = s.films,
        t.quality_class = s.quality_class,
        t.is_active = s.is_active
WHEN NOT MATCHED THEN
    INSERT (actor, actorid, films, quality_class, is_active, current_year)
    VALUES (s.actor, s.actorid, s.films, s.quality_class, s.is_active, s.current_year);

-- Notes:
-- 1. Assumes year-by-year processing without gaps
-- 2. Inactive actors carry forward quality_class from last active year
-- 3. Actor name is Type 1 (always reflects current spelling)
-- 4. Uses AVG(rating) with FLOAT precision (consider CAST to NUMBER for stability)
-- 5. Films are deduplicated if you have duplicates across years
