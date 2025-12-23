-- DDL for hosts_cumulated table
-- Tracks which dates each host is experiencing any activity

CREATE TABLE hosts_cumulated (
    host TEXT,
    host_activity_datelist DATE[],
    date DATE,
    PRIMARY KEY (host, date)
);
