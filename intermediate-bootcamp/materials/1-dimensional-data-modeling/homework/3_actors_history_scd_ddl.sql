-- DDL for actors_history_scd table
-- Implements Type 2 Slowly Changing Dimension to track changes in quality_class and is_active
-- This is a non-snapshot SCD: rows are extended/updated in place, not re-inserted each year
--
-- Design decision: Closed ranges (end_date always set)
-- Alternative: Open-ended ranges (end_date NULL for current) reduces updates but complicates queries

CREATE TABLE actors_history_scd (
    actor TEXT,  -- Display name, not tracked for changes (Type 1 semantics)
    actorid TEXT NOT NULL,
    quality_class quality_class NOT NULL,  -- Tracked attribute
    is_active BOOLEAN NOT NULL,  -- Tracked attribute
    start_date INTEGER NOT NULL,
    end_date INTEGER NOT NULL,
    PRIMARY KEY (actorid, start_date),
    CHECK (start_date <= end_date)  -- Ensure valid date ranges
);

-- Index for efficient effective-dating queries (finding current record)
CREATE INDEX idx_actors_history_scd_effective_date ON actors_history_scd(actorid, end_date);

-- Optional: Prevent overlapping intervals using exclusion constraint (requires btree_gist extension)
-- CREATE EXTENSION IF NOT EXISTS btree_gist;
-- ALTER TABLE actors_history_scd 
--   ADD CONSTRAINT actors_history_scd_no_overlap 
--   EXCLUDE USING gist (actorid WITH =, int4range(start_date, end_date + 1) WITH &&);

-- Note: This table design uses closed ranges. If you prefer open-ended ranges:
-- 1. Allow NULL end_date for current records
-- 2. Modify CHECK to: CHECK (start_date <= end_date OR end_date IS NULL)
-- 3. Adjust incremental logic to UPDATE end_date on change, not extend unchanged
