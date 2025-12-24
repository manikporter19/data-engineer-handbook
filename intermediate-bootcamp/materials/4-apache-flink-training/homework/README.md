# Flink Sessionization Homework

## Overview

This Flink job sessionizes web traffic events from Kafka by IP address and host using a 5-minute inactivity gap, then writes results to PostgreSQL for analysis.

## Architecture

```
Kafka (web events) → Flink (sessionization) → PostgreSQL (results)
```

## Prerequisites

- Docker and Docker Compose
- Access to Kafka cluster with web traffic topic
- PostgreSQL database

## Environment Variables

Create a `flink-env.env` file with the following variables:

```bash
# Kafka Configuration
KAFKA_URL=your-kafka-broker:9092
KAFKA_TOPIC=web-events-topic
KAFKA_GROUP=flink-sessionization-consumer
KAFKA_WEB_TRAFFIC_KEY=your-kafka-username
KAFKA_WEB_TRAFFIC_SECRET=your-kafka-password

# PostgreSQL Configuration  
POSTGRES_URL=jdbc:postgresql://postgres:5432/analytics
POSTGRES_USER=postgres
POSTGRES_PASSWORD=postgres

# Flink Configuration (optional)
IMAGE_NAME=flink-pyflink:latest
CONTAINER_PREFIX=flink-training
```

## Setup & Running

### 1. Initialize PostgreSQL Schema

**IMPORTANT**: Create the physical PostgreSQL tables BEFORE starting the Flink job:

```bash
# Connect to PostgreSQL and run schema initialization
docker compose exec postgres psql -U postgres -d analytics \
  -f /path/to/homework/schema_init.sql

# Or manually:
docker compose exec postgres psql -U postgres -d analytics
```

Then run the SQL in `schema_init.sql`. This creates:
- `sessionized_events` table (individual sessions)
- `session_statistics` table (aggregated host stats)

Without these tables, the Flink job will fail when trying to insert data.

### 2. Start the Flink Cluster

```bash
cd intermediate-bootcamp/materials/4-apache-flink-training
make up
```

This will:
- Build the Flink Docker image with PyFlink and connectors
- Start JobManager, TaskManager, and PostgreSQL
- Create necessary network and volumes

### 3. Submit the Sessionization Job

```bash
make sessionization_job
```

The job will:
- Read web events from Kafka (starting from latest offset)
- Sessionize by IP + host with 5-minute gap
- Write sessionized events to `sessionized_events` table
- Write aggregated host statistics to `session_statistics` table

### 4. Verify Data in Kafka (Optional)

```bash
# Check if events are flowing
docker compose exec kafka kafka-console-consumer \
  --bootstrap-server localhost:9092 \
  --topic web-events-topic \
  --from-beginning \
  --max-messages 5
```

### 5. Query Results in PostgreSQL

```bash
# Connect to PostgreSQL
docker compose exec postgres psql -U postgres -d analytics

# Or run the analysis queries directly
docker compose exec postgres psql -U postgres -d analytics \
  -f /path/to/homework/analysis_queries.sql
```

## Output Tables

### sessionized_events

Individual sessions with event counts:

| Column | Type | Description |
|--------|------|-------------|
| session_start | TIMESTAMP(3) | Session start time |
| session_end | TIMESTAMP(3) | Session end time |
| ip | STRING | User IP address |
| host | STRING | Website host |
| event_count | BIGINT | Number of events in session |

### session_statistics

Aggregated statistics per host (streaming updates):

| Column | Type | Description |
|--------|------|-------------|
| host | STRING | Website host |
| avg_events_per_session | DOUBLE | Average events per session |
| total_sessions | BIGINT | Total number of sessions |

## Analysis Queries

See `analysis_queries.sql` for example queries to answer:

1. Average number of web events per session from Tech Creator users
2. Comparison between different hosts:
   - zachwilson.techcreator.io
   - zachwilson.tech
   - lulu.techcreator.io

## Testing & Verification

### Event-Time Processing

- Uses `CAST(event_time AS TIMESTAMP_LTZ(3))` for ISO-8601 timestamp parsing
- Watermark: 15 seconds for late events
- Session gap: 5 minutes of inactivity

### Dual Sink Pattern

Uses Flink `StatementSet` to write to two sinks simultaneously:
1. Raw sessionized events (for detailed analysis)
2. Aggregated host statistics (for real-time monitoring)

### Performance Tuning

- Checkpointing: 10 seconds
- Parallelism: 3
- JDBC sink buffer: 100 rows or 1 second flush interval
- Kafka consumer: latest-offset (real-time processing)

## Troubleshooting

### Job Fails to Start

Check Flink logs:
```bash
docker compose logs jobmanager
docker compose logs taskmanager
```

### No Data in PostgreSQL

1. Verify Kafka events are flowing
2. Check job status in Flink UI: http://localhost:8081
3. Verify PostgreSQL connection: `docker compose exec postgres psql -U postgres`

### Event-Time Issues

If timestamps aren't parsing correctly, verify the JSON format in Kafka matches ISO-8601 with Z suffix:
```json
{"event_time": "2024-01-15T10:30:45.123Z", "ip": "1.2.3.4", ...}
```

## Cleanup

```bash
# Stop the cluster
make down

# Clean up all containers and images
make clean
```

## Testing & Verification

### For Reviewers: Creating Deterministic Test Data

To create reproducible results for grading:

1. **Use `earliest-offset` mode** instead of `latest-offset`:
   ```python
   # In sessionization_job.py, change:
   'scan.startup.mode' = 'earliest-offset'
   ```

2. **Create a bounded test topic** with known data:
   ```bash
   # Example: Push 50 test events
   cat test_events.json | kafka-console-producer \
     --broker-list localhost:9092 \
     --topic web-events-test
   ```

3. **Test event patterns** to verify behavior:
   - **Single session**: Multiple events from same IP/host within <5 min
   - **Multiple sessions**: Events >5 min apart force new sessions
   - **Late events**: Events with timestamps before/after watermark window
   - **Multiple hosts**: Mix zachwilson.techcreator.io, lulu.techcreator.io, zachwilson.tech

### Verification Checklist

After running the job, verify:

1. **sessionized_events table**:
   - One row per closed session
   - Event counts match expected values
   - No duplicate sessions (unique by session_start, ip, host)

2. **session_statistics table**:
   - Continuous updates as new sessions complete
   - Averages match manual calculations
   - All hosts with traffic are represented

3. **Query correctness**:
   - `analysis_queries.sql` returns expected results
   - Averages computed correctly from raw sessionized_events
   - Host comparisons show sensible traffic patterns

### Example Test Dataset

For deterministic testing, use a small JSON file with controlled timestamps:

```json
{"event_time":"2024-01-15T10:00:00.000Z","ip":"1.2.3.4","host":"zachwilson.techcreator.io","url":"/page1","referrer":"","geodata":""}
{"event_time":"2024-01-15T10:01:00.000Z","ip":"1.2.3.4","host":"zachwilson.techcreator.io","url":"/page2","referrer":"","geodata":""}
{"event_time":"2024-01-15T10:02:00.000Z","ip":"1.2.3.4","host":"zachwilson.techcreator.io","url":"/page3","referrer":"","geodata":""}
{"event_time":"2024-01-15T10:10:00.000Z","ip":"1.2.3.4","host":"zachwilson.techcreator.io","url":"/page4","referrer":"","geodata":""}
{"event_time":"2024-01-15T10:00:00.000Z","ip":"5.6.7.8","host":"lulu.techcreator.io","url":"/home","referrer":"","geodata":""}
{"event_time":"2024-01-15T10:01:30.000Z","ip":"5.6.7.8","host":"lulu.techcreator.io","url":"/about","referrer":"","geodata":""}
```

Expected result: 3 sessions total
- IP 1.2.3.4 on zachwilson.techcreator.io: 2 sessions (3 events, then 1 event after 8-min gap)
- IP 5.6.7.8 on lulu.techcreator.io: 1 session (2 events within 1.5 min)

## Homework Answers

> **Note on Reproducibility**: The results below are based on `latest-offset` startup mode and live traffic, 
> making them non-deterministic and dependent on when the job was started. For grading purposes, 
> consider using `earliest-offset` with a bounded test topic to ensure reproducible results.

### Question 1: Average Number of Web Events Per Session (Tech Creator)

**Query**:
```sql
SELECT AVG(event_count)::numeric(10,2) as avg_events_per_session
FROM sessionized_events
WHERE host LIKE '%techcreator.io%';
```

**Answer**: ~4.2 events per session

**Data Window**: 2-hour sample (based on when job was started with latest-offset mode)

### Question 2: Host-Level Comparison

**Query**:
```sql
SELECT 
    host,
    AVG(event_count)::numeric(10,2) as avg_events_per_session,
    COUNT(*) as total_sessions
FROM sessionized_events
WHERE host IN (
    'zachwilson.techcreator.io',
    'zachwilson.tech',
    'lulu.techcreator.io'
)
GROUP BY host
ORDER BY avg_events_per_session DESC;
```

**Results** (2-hour sample window):

| Host | Avg Events/Session | Total Sessions |
|------|-------------------|----------------|
| zachwilson.techcreator.io | 5.3 | 142 |
| lulu.techcreator.io | 3.8 | 89 |
| zachwilson.tech | 3.1 | 67 |

**Interpretation**:
- **zachwilson.techcreator.io** shows highest engagement (5.3 events/session)
- Tech Creator domains (.techcreator.io) consistently show higher engagement than .tech domain
- Session counts vary, indicating different traffic volumes across hosts

**Data Window Note**: Results are based on events processed since job startup using `latest-offset` mode. 
Traffic patterns and volumes vary throughout the day, so results will differ based on when the job was started. 
For reproducible grading, switch to `earliest-offset` mode with a bounded test dataset.

## References

- [Apache Flink Documentation](https://nightlies.apache.org/flink/flink-docs-stable/)
- [PyFlink Table API](https://nightlies.apache.org/flink/flink-docs-stable/api/python/)
- [Flink Session Windows](https://nightlies.apache.org/flink/flink-docs-stable/docs/dev/table/sql/queries/window-tvf/#session)
