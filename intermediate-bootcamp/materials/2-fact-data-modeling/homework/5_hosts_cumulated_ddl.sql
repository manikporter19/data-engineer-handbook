-- DDL for hosts_cumulated table
-- Tracks which dates each host is experiencing any activity

CREATE TABLE hosts_cumulated (
    host TEXT NOT NULL,
    host_activity_datelist DATE[] NOT NULL DEFAULT ARRAY[]::DATE[],
    date DATE NOT NULL,
    PRIMARY KEY (host, date)
);
