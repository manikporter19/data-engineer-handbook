-- Query to convert device_activity_datelist into datelist_int
-- Uses bit manipulation to encode date presence as a 32-bit integer

SELECT 
    user_id,
    browser_type,
    datelist_int,
    date
FROM (
    WITH starter AS (
        SELECT 
            udc.device_activity_datelist @> ARRAY[DATE(d.valid_date)] as is_active,
            EXTRACT(DAY FROM DATE('2023-03-31') - d.valid_date) as days_since,
            udc.user_id,
            udc.browser_type
        FROM user_devices_cumulated udc
        CROSS JOIN (
            SELECT generate_series('2023-03-01', '2023-03-31', INTERVAL '1 day') as valid_date
        ) as d
        WHERE date = DATE('2023-03-31')  -- Replace with actual date variable (e.g., :this_date or {{ var('this_date') }})
    ),
    bits AS (
        SELECT 
            user_id,
            browser_type,
            SUM(
                CASE 
                    WHEN is_active THEN POW(2, 32 - days_since)
                    ELSE 0 
                END
            )::BIGINT::BIT(32) as datelist_int,
            DATE('2023-03-31') as date  -- Replace with actual date variable (e.g., :this_date or {{ var('this_date') }})
        FROM starter
        GROUP BY user_id, browser_type
    )
    SELECT 
        user_id,
        browser_type,
        datelist_int,
        date
    FROM bits
) subquery;
