-- DDL for user_devices_cumulated table
-- Tracks a user's active days by browser_type using a cumulative DATE array
--
-- Array Window Strategy:
--   - Intended window: Last 31 days (sliding window for monthly activity tracking)
--   - Array grows by appending new activity dates each day
--   - Consider implementing array pruning/truncation if window exceeds 31 days
--   - For longer retention periods (e.g., 90+ days), consider partitioning or separate archival table
--
-- Database Dialect: PostgreSQL (native array support)
--   - PostgreSQL 10+ with native DATE[] array type
--   - Arrays are stored efficiently with GIN indexes available for querying
--   - For other databases without native arrays, see alternatives below
--
-- Performance Considerations:
--   - Array size bounded by retention window (31 dates max = ~248 bytes per row)
--   - Consider GIN index on device_activity_datelist for fast containment queries:
--     CREATE INDEX idx_user_devices_activity_gin ON user_devices_cumulated 
--     USING GIN (device_activity_datelist);

CREATE TABLE user_devices_cumulated (
    user_id BIGINT NOT NULL,
    browser_type TEXT NOT NULL,
    device_activity_datelist DATE[] NOT NULL DEFAULT ARRAY[]::DATE[],
    date DATE NOT NULL,
    PRIMARY KEY (user_id, browser_type, date)
);

-- ============================================================================
-- ALTERNATIVE IMPLEMENTATIONS FOR NON-ARRAY DATABASES
-- ============================================================================

-- Option 1: Snowflake (VARIANT with ARRAY)
-- CREATE TABLE user_devices_cumulated (
--     user_id NUMBER(38,0) NOT NULL,
--     browser_type VARCHAR NOT NULL,
--     device_activity_datelist VARIANT NOT NULL,  -- Stores array as JSON
--     date DATE NOT NULL,
--     PRIMARY KEY (user_id, browser_type, date)
-- );
-- Note: Use ARRAY_CONSTRUCT() and ARRAY_CAT() for array operations

-- Option 2: BigQuery (REPEATED field)
-- CREATE TABLE user_devices_cumulated (
--     user_id INT64 NOT NULL,
--     browser_type STRING NOT NULL,
--     device_activity_datelist ARRAY<DATE>,  -- Native repeated field
--     date DATE NOT NULL
-- )
-- PARTITION BY date
-- CLUSTER BY user_id, browser_type;

-- Option 3: MySQL/SQL Server (Normalized child table - most portable)
-- CREATE TABLE user_devices_cumulated (
--     user_id BIGINT NOT NULL,
--     browser_type VARCHAR(100) NOT NULL,
--     date DATE NOT NULL,
--     PRIMARY KEY (user_id, browser_type, date)
-- );
-- CREATE TABLE user_device_activity_dates (
--     user_id BIGINT NOT NULL,
--     browser_type VARCHAR(100) NOT NULL,
--     snapshot_date DATE NOT NULL,
--     activity_date DATE NOT NULL,
--     PRIMARY KEY (user_id, browser_type, snapshot_date, activity_date),
--     FOREIGN KEY (user_id, browser_type, snapshot_date) 
--         REFERENCES user_devices_cumulated(user_id, browser_type, date)
-- );

-- Option 4: Redshift (SUPER type with JSON array)
-- CREATE TABLE user_devices_cumulated (
--     user_id BIGINT NOT NULL,
--     browser_type VARCHAR(100) NOT NULL,
--     device_activity_datelist SUPER,  -- JSON array format
--     date DATE NOT NULL,
--     PRIMARY KEY (user_id, browser_type, date)
-- )
-- DISTKEY(user_id)
-- SORTKEY(date, user_id);
