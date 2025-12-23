-- Cumulative query to generate device_activity_datelist from events
-- Builds up the activity list one day at a time using FULL OUTER JOIN

INSERT INTO user_devices_cumulated
WITH yesterday AS (
    SELECT * 
    FROM user_devices_cumulated
    WHERE date = DATE('2023-03-30')  -- Replace with actual date variable
),
today AS (
    SELECT 
        e.user_id,
        d.browser_type,
        DATE_TRUNC('day', e.event_time)::DATE as today_date,
        COUNT(1) as num_events
    FROM events e
    JOIN devices d ON e.device_id = d.device_id
    WHERE DATE_TRUNC('day', e.event_time) = DATE('2023-03-31')  -- Replace with actual date variable
        AND e.user_id IS NOT NULL
    GROUP BY e.user_id, d.browser_type, DATE_TRUNC('day', e.event_time)
)
SELECT 
    COALESCE(t.user_id, y.user_id) as user_id,
    COALESCE(t.browser_type, y.browser_type) as browser_type,
    COALESCE(y.device_activity_datelist, ARRAY[]::DATE[]) ||
        CASE 
            WHEN t.user_id IS NOT NULL THEN ARRAY[t.today_date]
            ELSE ARRAY[]::DATE[]
        END as device_activity_datelist,
    COALESCE(t.today_date, y.date + INTERVAL '1 day')::DATE as date
FROM yesterday y
FULL OUTER JOIN today t 
    ON y.user_id = t.user_id 
    AND y.browser_type = t.browser_type;
