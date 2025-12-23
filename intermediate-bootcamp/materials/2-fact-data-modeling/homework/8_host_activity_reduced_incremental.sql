-- Incremental query that loads host_activity_reduced day-by-day
-- Aggregates daily metrics into monthly arrays

INSERT INTO host_activity_reduced
WITH daily_aggregates AS (
    SELECT 
        DATE_TRUNC('month', event_time)::DATE as month,
        host,
        DATE_TRUNC('day', event_time)::DATE as date,
        COUNT(1) as hits,
        COUNT(DISTINCT user_id) as unique_visitors
    FROM events
    WHERE DATE_TRUNC('day', event_time) = DATE('2023-03-31')  -- Replace with actual date variable
        AND host IS NOT NULL
    GROUP BY DATE_TRUNC('month', event_time), host, DATE_TRUNC('day', event_time)
),
yesterday AS (
    SELECT *
    FROM host_activity_reduced
    WHERE month = DATE_TRUNC('month', DATE('2023-03-31'))  -- Replace with actual date variable
)
SELECT 
    COALESCE(da.month, y.month) as month,
    COALESCE(da.host, y.host) as host,
    COALESCE(y.hit_array, ARRAY[]::INTEGER[]) ||
        CASE 
            WHEN da.host IS NOT NULL THEN ARRAY[da.hits]
            ELSE ARRAY[]::INTEGER[]
        END as hit_array,
    COALESCE(y.unique_visitors_array, ARRAY[]::INTEGER[]) ||
        CASE 
            WHEN da.host IS NOT NULL THEN ARRAY[da.unique_visitors]
            ELSE ARRAY[]::INTEGER[]
        END as unique_visitors_array
FROM yesterday y
FULL OUTER JOIN daily_aggregates da
    ON y.host = da.host
    AND y.month = da.month
ON CONFLICT (host, month)
DO UPDATE SET
    hit_array = EXCLUDED.hit_array,
    unique_visitors_array = EXCLUDED.unique_visitors_array;
