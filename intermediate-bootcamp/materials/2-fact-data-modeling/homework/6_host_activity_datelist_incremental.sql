-- Incremental query to generate host_activity_datelist
-- Builds up the activity list one day at a time
--
-- IDEMPOTENCY: Uses ON CONFLICT to safely rerun for the same date
-- TABLE NAME FIX: Changed 'events' to 'web_events'
--
-- Usage with psql variables:
--   psql -v prev_date='2023-03-30' -v this_date='2023-03-31' -f 6_host_activity_datelist_incremental.sql
-- Usage with dbt:
--   {{ var('prev_date') }} and {{ var('this_date') }}

INSERT INTO hosts_cumulated (host, host_activity_datelist, date)
WITH yesterday AS (
    SELECT * 
    FROM hosts_cumulated
    WHERE date = DATE('2023-03-30')  -- Replace with :prev_date or {{ var('prev_date') }}
),
today AS (
    SELECT 
        host,
        DATE_TRUNC('day', event_time)::DATE as today_date,
        COUNT(1) as num_events
    FROM web_events  -- FIXED: Changed from 'events' to 'web_events'
    WHERE DATE_TRUNC('day', event_time) = DATE('2023-03-31')  -- Replace with :this_date or {{ var('this_date') }}
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
    ON y.host = t.host
-- IDEMPOTENCY: Prevents duplicate key errors on reruns
ON CONFLICT (host, date) 
DO UPDATE SET 
    host_activity_datelist = EXCLUDED.host_activity_datelist;
