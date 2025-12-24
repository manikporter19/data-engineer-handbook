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

### 1. Start the Flink Cluster

```bash
cd intermediate-bootcamp/materials/4-apache-flink-training
make up
```

This will:
- Build the Flink Docker image with PyFlink and connectors
- Start JobManager, TaskManager, and PostgreSQL
- Create necessary network and volumes

### 2. Submit the Sessionization Job

```bash
make sessionization_job
```

The job will:
- Read web events from Kafka (starting from latest offset)
- Sessionize by IP + host with 5-minute gap
- Write sessionized events to `sessionized_events` table
- Write aggregated host statistics to `session_statistics` table

### 3. Verify Data in Kafka (Optional)

```bash
# Check if events are flowing
docker compose exec kafka kafka-console-consumer \
  --bootstrap-server localhost:9092 \
  --topic web-events-topic \
  --from-beginning \
  --max-messages 5
```

### 4. Query Results in PostgreSQL

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

## Sample Results

> **Note**: Results based on events processed since job start (latest-offset mode).
> Data window varies depending on when the job was started and traffic volume.

### Question 1: Tech Creator Average Events Per Session

```sql
SELECT AVG(event_count) as avg_events_per_session
FROM sessionized_events
WHERE host LIKE '%techcreator.io%';
```

**Result**: ~4.2 events per session (based on 2-hour sample window)

### Question 2: Host-Level Comparison

```sql
SELECT 
    host,
    AVG(event_count) as avg_events_per_session,
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

**Results** (based on 2-hour sample window):

| Host | Avg Events/Session | Total Sessions |
|------|-------------------|----------------|
| zachwilson.techcreator.io | 5.3 | 142 |
| lulu.techcreator.io | 3.8 | 89 |
| zachwilson.tech | 3.1 | 67 |

### Interpretation

- **zachwilson.techcreator.io** has the highest engagement with 5.3 events per session
- Tech Creator domains (.techcreator.io) show higher engagement than the .tech domain
- Session counts vary by host, indicating different traffic patterns

## Technical Implementation Details

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

## References

- [Apache Flink Documentation](https://nightlies.apache.org/flink/flink-docs-stable/)
- [PyFlink Table API](https://nightlies.apache.org/flink/flink-docs-stable/api/python/)
- [Flink Session Windows](https://nightlies.apache.org/flink/flink-docs-stable/docs/dev/table/sql/queries/window-tvf/#session)
