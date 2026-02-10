-- Cumulative query to generate device_activity_datelist from web_events
-- Builds up the activity list one day at a time using FULL OUTER JOIN
-- Implements 31-day sliding window to bound array growth
-- Idempotent: Uses ON CONFLICT DO UPDATE to handle reruns safely

INSERT INTO user_devices_cumulated (user_id, browser_type, device_activity_datelist, date)
WITH yesterday AS (
    SELECT * 
    FROM user_devices_cumulated
    WHERE date = DATE('2023-03-30')  -- Replace with actual date variable (e.g., :prev_date or {{ var('prev_date') }})
),
today AS (
    SELECT 
        e.user_id,
        d.browser_type,
        DATE_TRUNC('day', e.event_time)::DATE as today_date,
        COUNT(1) as num_events
    FROM web_events e  -- FIXED: Corrected table name from 'events' to 'web_events'
    JOIN devices d ON e.device_id = d.device_id
    WHERE DATE_TRUNC('day', e.event_time) = DATE('2023-03-31')  -- Replace with actual date variable (e.g., :this_date or {{ var('this_date') }})
        AND e.user_id IS NOT NULL
    GROUP BY e.user_id, d.browser_type, DATE_TRUNC('day', e.event_time)
)
SELECT 
    COALESCE(t.user_id, y.user_id) as user_id,
    COALESCE(t.browser_type, y.browser_type) as browser_type,
    -- FIXED: Implement 31-day sliding window to bound array growth
    (
        SELECT ARRAY(
            SELECT d 
            FROM unnest(
                COALESCE(y.device_activity_datelist, ARRAY[]::DATE[]) ||
                CASE 
                    WHEN t.user_id IS NOT NULL THEN ARRAY[t.today_date]
                    ELSE ARRAY[]::DATE[]
                END
            ) AS d
            WHERE d >= (COALESCE(t.today_date, y.date + INTERVAL '1 day')::DATE - INTERVAL '30 days')
            ORDER BY d
        )
    ) as device_activity_datelist,
    COALESCE(t.today_date, y.date + INTERVAL '1 day')::DATE as date
FROM yesterday y
FULL OUTER JOIN today t 
    ON y.user_id = t.user_id 
    AND y.browser_type = t.browser_type
-- FIXED: Add idempotency with ON CONFLICT DO UPDATE
ON CONFLICT (user_id, browser_type, date) 
DO UPDATE SET 
    device_activity_datelist = EXCLUDED.device_activity_datelist;
