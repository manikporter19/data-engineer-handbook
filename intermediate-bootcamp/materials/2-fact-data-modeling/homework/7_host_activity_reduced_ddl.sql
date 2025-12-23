-- DDL for host_activity_reduced monthly fact table
-- Stores monthly aggregates of hits and unique visitors per host

CREATE TABLE host_activity_reduced (
    month DATE,
    host TEXT,
    hit_array INTEGER[],
    unique_visitors_array INTEGER[],
    PRIMARY KEY (host, month)
);
