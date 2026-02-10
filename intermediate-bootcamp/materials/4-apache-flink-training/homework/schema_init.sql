-- PostgreSQL schema initialization for Flink sessionization job
-- Run this BEFORE starting the Flink job to create physical tables

-- Drop tables if they exist (for clean reruns)
DROP TABLE IF EXISTS session_statistics CASCADE;
DROP TABLE IF EXISTS sessionized_events CASCADE;

-- Table for individual sessionized events
CREATE TABLE sessionized_events (
    session_start timestamptz NOT NULL,
    session_end timestamptz NOT NULL,
    ip text NOT NULL,
    host text NOT NULL,
    event_count bigint NOT NULL,
    PRIMARY KEY(session_start, ip, host)
);

-- Index for efficient host filtering
CREATE INDEX idx_sessionized_events_host ON sessionized_events(host);

-- Table for aggregated session statistics per host
CREATE TABLE session_statistics (
    host text PRIMARY KEY,
    avg_events_per_session double precision NOT NULL,
    total_sessions bigint NOT NULL,
    updated_at timestamptz DEFAULT CURRENT_TIMESTAMP
);

-- Add comments for documentation
COMMENT ON TABLE sessionized_events IS 'Individual web traffic sessions grouped by IP and host with 5-minute inactivity gap';
COMMENT ON TABLE session_statistics IS 'Real-time aggregated statistics per host (streaming updates from Flink)';
COMMENT ON COLUMN sessionized_events.session_start IS 'Session start timestamp (watermarked event time)';
COMMENT ON COLUMN sessionized_events.session_end IS 'Session end timestamp (last event in window)';
COMMENT ON COLUMN sessionized_events.event_count IS 'Number of web events in this session';
COMMENT ON COLUMN session_statistics.avg_events_per_session IS 'Average events per session for this host';
COMMENT ON COLUMN session_statistics.total_sessions IS 'Total number of sessions observed for this host';

-- Grant permissions (adjust as needed for your environment)
-- GRANT SELECT, INSERT, UPDATE ON sessionized_events TO flink_user;
-- GRANT SELECT, INSERT, UPDATE ON session_statistics TO flink_user;
