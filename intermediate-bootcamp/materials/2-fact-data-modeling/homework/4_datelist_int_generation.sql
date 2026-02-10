-- Query to convert device_activity_datelist into datelist_int
-- Uses bit manipulation to encode date presence as a 32-bit integer
-- Fixed: Uses proper bit shifting (1::bigint << days_since) instead of POW(2, 32-days_since)
-- days_since: 0 = today, 1 = yesterday, ..., 30 = 30 days ago
--
-- Parameterization:
-- - PostgreSQL psql: Replace DATE('2023-03-31') with :as_of_date
-- - dbt: Replace with {{ var('as_of_date') }}
-- - Snowflake: Replace with $as_of_date

WITH params AS (
    SELECT DATE('2023-03-31')::date AS as_of  -- Replace with actual date variable
),
calendar AS (
    -- Generate dates from start of month to as_of date
    SELECT 
        gs::date AS d,
        (SELECT as_of FROM params) - gs::date AS day_diff
    FROM generate_series(
        date_trunc('month', (SELECT as_of FROM params))::date,
        (SELECT as_of FROM params),
        interval '1 day'
    ) gs
),
starter AS (
    SELECT 
        udc.user_id,
        udc.browser_type,
        c.d,
        EXTRACT(DAY FROM c.day_diff)::int AS days_since,  -- 0 = today, 1 = yesterday, etc.
        (c.d = ANY(udc.device_activity_datelist)) AS is_active
    FROM user_devices_cumulated udc
    JOIN params p ON udc.date = p.as_of
    JOIN calendar c ON TRUE  -- Cartesian join to check each date in the month
)
SELECT 
    user_id,
    browser_type,
    SUM(
        CASE 
            WHEN is_active THEN (1::bigint << days_since)  -- Bit shifting: correct position for each day
            ELSE 0 
        END
    )::bit(32) AS datelist_int,  -- Cast to BIT(32) at the end
    (SELECT as_of FROM params) AS date
FROM starter
GROUP BY user_id, browser_type;
