-- Analysis queries for sessionized web events
-- Run these queries after the Flink job has processed events

-- Question 1: What is the average number of web events per session from a user on Tech Creator?
SELECT 
    AVG(event_count) as avg_events_per_session,
    COUNT(*) as total_sessions,
    MIN(event_count) as min_events,
    MAX(event_count) as max_events
FROM sessionized_events
WHERE host LIKE '%techcreator.io%';

-- Question 2: Compare results between different hosts
SELECT 
    host,
    AVG(event_count) as avg_events_per_session,
    COUNT(*) as total_sessions,
    MIN(event_count) as min_events,
    MAX(event_count) as max_events,
    SUM(event_count) as total_events
FROM sessionized_events
WHERE host IN (
    'zachwilson.techcreator.io',
    'zachwilson.tech',
    'lulu.techcreator.io'
)
GROUP BY host
ORDER BY avg_events_per_session DESC;

-- Additional analysis: Session duration statistics
SELECT 
    host,
    AVG(EXTRACT(EPOCH FROM (session_end - session_start))) / 60 as avg_session_duration_minutes,
    COUNT(*) as total_sessions
FROM sessionized_events
WHERE host IN (
    'zachwilson.techcreator.io',
    'zachwilson.tech',
    'lulu.techcreator.io'
)
GROUP BY host
ORDER BY avg_session_duration_minutes DESC;

-- IP address analysis: Most active users
SELECT 
    ip,
    host,
    COUNT(*) as session_count,
    AVG(event_count) as avg_events_per_session,
    SUM(event_count) as total_events
FROM sessionized_events
GROUP BY ip, host
HAVING COUNT(*) > 5
ORDER BY total_events DESC
LIMIT 20;
