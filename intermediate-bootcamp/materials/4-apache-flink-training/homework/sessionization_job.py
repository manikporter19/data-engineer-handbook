"""
Apache Flink Training Homework
Create a Flink job that:
- Sessionizes input data by IP address and host
- Uses a 5-minute gap
- Answers questions about average web events per session
- Compares results between different hosts

Environment: Flink 1.17+, PyFlink with Blink planner
JSON Format: ISO-8601 timestamps with Z suffix
"""

import os
from pyflink.datastream import StreamExecutionEnvironment
from pyflink.table import EnvironmentSettings, DataTypes, StreamTableEnvironment
from pyflink.table.expressions import lit, col
from pyflink.table.window import Session


def create_events_source_kafka(t_env):
    """Create Kafka source table for web events
    
    Uses CAST to TIMESTAMP_LTZ for proper ISO-8601 parsing
    """
    kafka_key = os.environ.get("KAFKA_WEB_TRAFFIC_KEY", "")
    kafka_secret = os.environ.get("KAFKA_WEB_TRAFFIC_SECRET", "")
    table_name = "web_events_kafka"
    
    source_ddl = f"""
        CREATE TABLE {table_name} (
            ip STRING,
            event_time STRING,
            referrer STRING,
            host STRING,
            url STRING,
            geodata STRING,
            row_time AS CAST(event_time AS TIMESTAMP_LTZ(3)),
            WATERMARK FOR row_time AS row_time - INTERVAL '15' SECOND
        ) WITH (
            'connector' = 'kafka',
            'properties.bootstrap.servers' = '{os.environ.get('KAFKA_URL')}',
            'topic' = '{os.environ.get('KAFKA_TOPIC')}',
            'properties.group.id' = '{os.environ.get('KAFKA_GROUP')}',
            'properties.security.protocol' = 'SASL_SSL',
            'properties.sasl.mechanism' = 'PLAIN',
            'properties.sasl.jaas.config' = 'org.apache.flink.kafka.shaded.org.apache.kafka.common.security.plain.PlainLoginModule required username=\"{kafka_key}\" password=\"{kafka_secret}\";',
            'scan.startup.mode' = 'latest-offset',
            'format' = 'json',
            'json.ignore-parse-errors' = 'true',
            'json.fail-on-missing-field' = 'false'
        );
    """
    t_env.execute_sql(source_ddl)
    return table_name


def create_sessionized_events_sink_postgres(t_env):
    """Create PostgreSQL sink table for sessionized events
    
    Includes buffer configuration for better write performance
    """
    table_name = 'sessionized_events'
    sink_ddl = f"""
        CREATE TABLE {table_name} (
            session_start TIMESTAMP(3),
            session_end TIMESTAMP(3),
            ip STRING,
            host STRING,
            event_count BIGINT,
            PRIMARY KEY (session_start, ip, host) NOT ENFORCED
        ) WITH (
            'connector' = 'jdbc',
            'url' = '{os.environ.get("POSTGRES_URL")}',
            'table-name' = '{table_name}',
            'username' = '{os.environ.get("POSTGRES_USER", "postgres")}',
            'password' = '{os.environ.get("POSTGRES_PASSWORD", "postgres")}',
            'driver' = 'org.postgresql.Driver',
            'sink.buffer-flush.max-rows' = '100',
            'sink.buffer-flush.interval' = '1s'
        );
    """
    t_env.execute_sql(sink_ddl)
    return table_name


def create_session_statistics_sink_postgres(t_env):
    """Create PostgreSQL sink table for session statistics by host
    
    Stores continuous streaming aggregations per host
    """
    table_name = 'session_statistics'
    sink_ddl = f"""
        CREATE TABLE {table_name} (
            host STRING,
            avg_events_per_session DOUBLE,
            total_sessions BIGINT,
            PRIMARY KEY (host) NOT ENFORCED
        ) WITH (
            'connector' = 'jdbc',
            'url' = '{os.environ.get("POSTGRES_URL")}',
            'table-name' = '{table_name}',
            'username' = '{os.environ.get("POSTGRES_USER", "postgres")}',
            'password' = '{os.environ.get("POSTGRES_PASSWORD", "postgres")}',
            'driver' = 'org.postgresql.Driver',
            'sink.buffer-flush.max-rows' = '50',
            'sink.buffer-flush.interval' = '2s'
        );
    """
    t_env.execute_sql(sink_ddl)
    return table_name


def sessionize_web_events():
    """Main function to sessionize web events and calculate statistics
    
    Uses StatementSet to write both sessionized events and host statistics
    """
    # Set up the execution environment
    env = StreamExecutionEnvironment.get_execution_environment()
    env.enable_checkpointing(10000)
    env.set_parallelism(3)
    
    # Set up the table environment
    settings = EnvironmentSettings.new_instance().in_streaming_mode().build()
    t_env = StreamTableEnvironment.create(env, environment_settings=settings)
    
    try:
        # Create source and sink tables
        source_table = create_events_source_kafka(t_env)
        sessionized_sink = create_sessionized_events_sink_postgres(t_env)
        statistics_sink = create_session_statistics_sink_postgres(t_env)
        
        # Sessionize events with 5-minute gap by IP and host
        print("Starting sessionization with 5-minute gap...")
        sessionized_query = (
            t_env.from_path(source_table)
            .window(
                Session.with_gap(lit(5).minutes)
                .on(col("row_time"))
                .alias("w")
            )
            .group_by(col("w"), col("ip"), col("host"))
            .select(
                col("w").start.alias("session_start"),
                col("w").end.alias("session_end"),
                col("ip"),
                col("host"),
                lit(1).count.alias("event_count")
            )
        )
        
        # Calculate per-host statistics from sessionized data
        host_stats = (
            sessionized_query
            .group_by(col("host"))
            .select(
                col("host"),
                col("event_count").cast(DataTypes.DOUBLE()).avg.alias("avg_events_per_session"),
                lit(1).count.alias("total_sessions")
            )
        )
        
        # Use StatementSet to write to both sinks
        stmt_set = t_env.create_statement_set()
        stmt_set.add_insert(sessionized_sink, sessionized_query)
        stmt_set.add_insert(statistics_sink, host_stats)
        
        print("\n" + "=" * 80)
        print("Sessionization Job Started")
        print("=" * 80)
        print("\nConfiguration:")
        print(f"  - Session Gap: 5 minutes")
        print(f"  - Grouping By: IP address + host")
        print(f"  - Watermark: 15 seconds late events allowed")
        print(f"  - Source: Kafka ({os.environ.get('KAFKA_TOPIC', 'N/A')})")
        print(f"  - Sink: PostgreSQL (sessionized_events + session_statistics)")
        print("\nQuestions to be answered:")
        print("1. What is the average number of web events per session from Tech Creator?")
        print("2. Compare results between different hosts:")
        print("   - zachwilson.techcreator.io")
        print("   - zachwilson.tech")
        print("   - lulu.techcreator.io")
        print("\nTables created:")
        print("  - sessionized_events: Individual sessions with event counts")
        print("  - session_statistics: Aggregated stats per host (streaming updates)")
        print("\nQuery examples in: sql/analysis_queries.sql")
        print("=" * 80)
        
        # Execute the statement set (runs continuously)
        stmt_set.execute().wait()
        
    except Exception as e:
        print(f"Sessionization job failed: {str(e)}")
        raise


if __name__ == '__main__':
    sessionize_web_events()
