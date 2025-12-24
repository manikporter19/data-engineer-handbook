-- DDL for host_activity_reduced monthly fact table
-- Stores monthly aggregates of hits and unique visitors per host

CREATE TABLE host_activity_reduced (
    month DATE NOT NULL,
    host TEXT NOT NULL,
    hit_array INTEGER[] NOT NULL DEFAULT ARRAY[]::INTEGER[],
    unique_visitors_array INTEGER[] NOT NULL DEFAULT ARRAY[]::INTEGER[],
    PRIMARY KEY (host, month)
);
