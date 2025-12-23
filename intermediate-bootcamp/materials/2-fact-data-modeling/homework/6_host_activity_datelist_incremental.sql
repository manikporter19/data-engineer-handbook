-- Incremental query to generate host_activity_datelist
-- Builds up the activity list one day at a time

INSERT INTO hosts_cumulated
WITH yesterday AS (
    SELECT * 
    FROM hosts_cumulated
    WHERE date = DATE('2023-03-30')  -- Replace with actual date variable
),
today AS (
    SELECT 
        host,
        DATE_TRUNC('day', event_time)::DATE as today_date,
        COUNT(1) as num_events
    FROM events
    WHERE DATE_TRUNC('day', event_time) = DATE('2023-03-31')  -- Replace with actual date variable
        AND host IS NOT NULL
    GROUP BY host, DATE_TRUNC('day', event_time)
)
SELECT 
    COALESCE(t.host, y.host) as host,
    COALESCE(y.host_activity_datelist, ARRAY[]::DATE[]) ||
        CASE 
            WHEN t.host IS NOT NULL THEN ARRAY[t.today_date]
            ELSE ARRAY[]::DATE[]
        END as host_activity_datelist,
    COALESCE(t.today_date, y.date + INTERVAL '1 day')::DATE as date
FROM yesterday y
FULL OUTER JOIN today t 
    ON y.host = t.host;
