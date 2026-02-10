-- Incremental query that loads host_activity_reduced day-by-day
-- Aggregates daily metrics into monthly arrays
-- IMPORTANT: Appends 0 for days with no activity to maintain aligned arrays (one element per day)

INSERT INTO host_activity_reduced (month, host, hit_array, unique_visitors_array)
WITH daily_aggregates AS (
    SELECT 
        DATE_TRUNC('month', event_time)::DATE as month,
        host,
        DATE_TRUNC('day', event_time)::DATE as date,
        COUNT(1) as hits,
        COUNT(DISTINCT user_id) as unique_visitors
    FROM web_events  -- Corrected from 'events' to 'web_events'
    WHERE DATE_TRUNC('day', event_time) = DATE('2023-03-31')  -- Replace with actual date variable (e.g., :this_date or {{ var('this_date') }})
        AND host IS NOT NULL
    GROUP BY DATE_TRUNC('month', event_time), host, DATE_TRUNC('day', event_time)
),
yesterday AS (
    SELECT *
    FROM host_activity_reduced
    WHERE month = DATE_TRUNC('month', DATE('2023-03-31'))  -- Replace with actual date variable (e.g., :this_date or {{ var('this_date') }})
)
SELECT 
    COALESCE(da.month, y.month) as month,
    COALESCE(da.host, y.host) as host,
    -- Always append exactly one element per day (0 if no activity) to keep arrays aligned
    COALESCE(y.hit_array, ARRAY[]::INTEGER[]) || ARRAY[COALESCE(da.hits, 0)] as hit_array,
    COALESCE(y.unique_visitors_array, ARRAY[]::INTEGER[]) || ARRAY[COALESCE(da.unique_visitors, 0)] as unique_visitors_array
FROM yesterday y
FULL OUTER JOIN daily_aggregates da
    ON y.host = da.host
    AND y.month = da.month
ON CONFLICT (host, month)
DO UPDATE SET
    hit_array = EXCLUDED.hit_array,
    unique_visitors_array = EXCLUDED.unique_visitors_array;
