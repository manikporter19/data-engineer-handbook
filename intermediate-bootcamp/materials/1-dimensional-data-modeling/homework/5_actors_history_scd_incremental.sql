-- Incremental query for actors_history_scd
-- Combines previous year's SCD data with new incoming data from actors table

CREATE TYPE scd_type AS (
    quality_class quality_class,
    is_active BOOLEAN,
    start_date INTEGER,
    end_date INTEGER
);

INSERT INTO actors_history_scd
WITH last_year_scd AS (
    SELECT * FROM actors_history_scd
    WHERE current_year = 1970  -- Replace with actual year variable
    AND end_date = 1970
),
historical_scd AS (
    SELECT 
        actor,
        actorid,
        quality_class,
        is_active,
        start_date,
        end_date
    FROM actors_history_scd
    WHERE current_year = 1970  -- Replace with actual year variable
    AND end_date < 1970
),
this_year_data AS (
    SELECT * FROM actors
    WHERE current_year = 1971  -- Replace with actual year variable
),
unchanged_records AS (
    SELECT 
        ty.actor,
        ty.actorid,
        ty.quality_class,
        ty.is_active,
        ly.start_date,
        ty.current_year as end_date
    FROM this_year_data ty
    JOIN last_year_scd ly
        ON ty.actorid = ly.actorid
    WHERE ty.quality_class = ly.quality_class
        AND ty.is_active = ly.is_active
),
changed_records AS (
    SELECT 
        ty.actor,
        ty.actorid,
        UNNEST(ARRAY[
            ROW(
                ly.quality_class,
                ly.is_active,
                ly.start_date,
                ly.end_date
            )::scd_type,
            ROW(
                ty.quality_class,
                ty.is_active,
                ty.current_year,
                ty.current_year
            )::scd_type
        ]) as records
    FROM this_year_data ty
    LEFT JOIN last_year_scd ly
        ON ty.actorid = ly.actorid
    WHERE (ty.quality_class <> ly.quality_class
        OR ty.is_active <> ly.is_active)
        OR ly.actorid IS NULL
),
unnested_changed_records AS (
    SELECT 
        actor,
        actorid,
        (records::scd_type).quality_class,
        (records::scd_type).is_active,
        (records::scd_type).start_date,
        (records::scd_type).end_date
    FROM changed_records
),
new_records AS (
    SELECT 
        ty.actor,
        ty.actorid,
        ty.quality_class,
        ty.is_active,
        ty.current_year as start_date,
        ty.current_year as end_date
    FROM this_year_data ty
    LEFT JOIN last_year_scd ly
        ON ty.actorid = ly.actorid
    WHERE ly.actorid IS NULL
)
SELECT 
    actor,
    actorid,
    quality_class,
    is_active,
    start_date,
    end_date,
    1971 as current_year  -- Replace with actual year variable
FROM (
    SELECT * FROM historical_scd
    UNION ALL
    SELECT * FROM unchanged_records
    UNION ALL
    SELECT * FROM unnested_changed_records
    UNION ALL
    SELECT * FROM new_records
) a;
