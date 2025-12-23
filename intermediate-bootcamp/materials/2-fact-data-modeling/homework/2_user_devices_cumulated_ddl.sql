-- DDL for user_devices_cumulated table
-- Tracks a user's active days by browser_type using a MAP structure

CREATE TABLE user_devices_cumulated (
    user_id BIGINT,
    browser_type TEXT,
    device_activity_datelist DATE[],
    date DATE,
    PRIMARY KEY (user_id, browser_type, date)
);

-- Alternative approach using MAP type (if supported by database)
-- CREATE TABLE user_devices_cumulated (
--     user_id BIGINT,
--     device_activity_datelist MAP<TEXT, ARRAY<DATE>>,
--     date DATE,
--     PRIMARY KEY (user_id, date)
-- );
