-- Snowflake DDL for actors_history_scd table (Type 2 SCD)
-- Tracks quality_class and is_active changes over time
--
-- Design: Non-snapshot, single ever-current SCD
-- - Rows extended in place for unchanged actors (update end_date)
-- - New rows inserted for changes
-- - No yearly re-insertion of full history

CREATE TABLE IF NOT EXISTS actors_history_scd (
    actor VARCHAR(500) NOT NULL,  -- Display name (Type 1 - always current)
    actorid VARCHAR(100) NOT NULL,
    quality_class VARCHAR(20) NOT NULL CHECK (quality_class IN ('star', 'good', 'average', 'bad')),
    is_active BOOLEAN NOT NULL,
    start_date NUMBER(4,0) NOT NULL,  -- Inclusive: first year with this state
    end_date NUMBER(4,0) NOT NULL,    -- Inclusive: last year with this state
    PRIMARY KEY (actorid, start_date),
    CONSTRAINT chk_date_range CHECK (start_date <= end_date)
);

-- Index for effective-dating queries (find state as of specific year)
CREATE INDEX IF NOT EXISTS idx_scd_actorid_end ON actors_history_scd(actorid, end_date);

-- Index for range queries
CREATE INDEX IF NOT EXISTS idx_scd_dates ON actors_history_scd(start_date, end_date);

-- Clustering key for better performance
ALTER TABLE actors_history_scd CLUSTER BY (actorid, start_date);

-- Optional: Exclusion constraint alternative (prevent overlapping intervals)
-- Snowflake doesn't support exclusion constraints like PostgreSQL
-- Use application logic or triggers to enforce

-- Notes on open-ended vs closed ranges:
-- - Current design: Closed ranges (end_date updated annually)
-- - Alternative: Open-ended rows (end_date NULL for current state)
--   Benefits: Fewer updates
--   Tradeoffs: More complex queries (need IS NULL checks)

-- Example effective-dating query:
-- SELECT * FROM actors_history_scd 
-- WHERE actorid = 'A1' AND 2020 BETWEEN start_date AND end_date;
