"""
Apache Flink Training Homework
Create a Flink job that:
- Sessionizes input data by IP address and host
- Uses a 5-minute gap
- Answers questions about average web events per session
- Compares results between different hosts
"""

import os
from pyflink.datastream import StreamExecutionEnvironment
from pyflink.table import EnvironmentSettings, DataTypes, StreamTableEnvironment
from pyflink.table.expressions import lit, col
from pyflink.table.window import Session


def create_events_source_kafka(t_env):
    """Create Kafka source table for web events"""
    kafka_key = os.environ.get("KAFKA_WEB_TRAFFIC_KEY", "")
    kafka_secret = os.environ.get("KAFKA_WEB_TRAFFIC_SECRET", "")
    table_name = "web_events_kafka"
    pattern = "yyyy-MM-dd''T''HH:mm:ss.SSS''Z''"
    
    sink_ddl = f"""
        CREATE TABLE {table_name} (
            ip VARCHAR,
            event_time VARCHAR,
            referrer VARCHAR,
            host VARCHAR,
            url VARCHAR,
            geodata VARCHAR,
            window_timestamp AS TO_TIMESTAMP(event_time, '{pattern}'),
            WATERMARK FOR window_timestamp AS window_timestamp - INTERVAL '15' SECOND
        ) WITH (
            'connector' = 'kafka',
            'properties.bootstrap.servers' = '{os.environ.get('KAFKA_URL')}',
            'topic' = '{os.environ.get('KAFKA_TOPIC')}',
            'properties.group.id' = '{os.environ.get('KAFKA_GROUP')}',
            'properties.security.protocol' = 'SASL_SSL',
            'properties.sasl.mechanism' = 'PLAIN',
            'properties.sasl.jaas.config' = 'org.apache.flink.kafka.shaded.org.apache.kafka.common.security.plain.PlainLoginModule required username=\"{kafka_key}\" password=\"{kafka_secret}\";',
            'scan.startup.mode' = 'latest-offset',
            'properties.auto.offset.reset' = 'latest',
            'format' = 'json'
        );
    """
    t_env.execute_sql(sink_ddl)
    return table_name


def create_sessionized_events_sink_postgres(t_env):
    """Create PostgreSQL sink table for sessionized events"""
    table_name = 'sessionized_events'
    sink_ddl = f"""
        CREATE TABLE {table_name} (
            session_start TIMESTAMP(3),
            session_end TIMESTAMP(3),
            ip VARCHAR,
            host VARCHAR,
            event_count BIGINT,
            PRIMARY KEY (session_start, ip, host) NOT ENFORCED
        ) WITH (
            'connector' = 'jdbc',
            'url' = '{os.environ.get("POSTGRES_URL")}',
            'table-name' = '{table_name}',
            'username' = '{os.environ.get("POSTGRES_USER", "postgres")}',
            'password' = '{os.environ.get("POSTGRES_PASSWORD", "postgres")}',
            'driver' = 'org.postgresql.Driver'
        );
    """
    t_env.execute_sql(sink_ddl)
    return table_name


def create_session_statistics_sink_postgres(t_env):
    """Create PostgreSQL sink table for session statistics by host"""
    table_name = 'session_statistics'
    sink_ddl = f"""
        CREATE TABLE {table_name} (
            host VARCHAR,
            avg_events_per_session DOUBLE,
            total_sessions BIGINT,
            PRIMARY KEY (host) NOT ENFORCED
        ) WITH (
            'connector' = 'jdbc',
            'url' = '{os.environ.get("POSTGRES_URL")}',
            'table-name' = '{table_name}',
            'username' = '{os.environ.get("POSTGRES_USER", "postgres")}',
            'password' = '{os.environ.get("POSTGRES_PASSWORD", "postgres")}',
            'driver' = 'org.postgresql.Driver'
        );
    """
    t_env.execute_sql(sink_ddl)
    return table_name


def sessionize_web_events():
    """Main function to sessionize web events and calculate statistics"""
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
        sessionized_query = t_env.from_path(source_table) \
            .window(
                Session.with_gap(lit(5).minutes)
                .on(col("window_timestamp"))
                .alias("session_window")
            ) \
            .group_by(
                col("session_window"),
                col("ip"),
                col("host")
            ) \
            .select(
                col("session_window").start.alias("session_start"),
                col("session_window").end.alias("session_end"),
                col("ip"),
                col("host"),
                col("ip").count.alias("event_count")
            )
        
        # Insert sessionized data into sink
        sessionized_query.execute_insert(sessionized_sink)
        
        # Calculate average events per session by host
        # This would typically be a batch query on the sessionized_events table
        # For demonstration, we'll create a SQL query
        stats_query = """
            SELECT 
                host,
                AVG(CAST(event_count AS DOUBLE)) as avg_events_per_session,
                COUNT(*) as total_sessions
            FROM sessionized_events
            GROUP BY host
        """
        
        print("\n" + "=" * 80)
        print("Sessionization Job Started")
        print("=" * 80)
        print("\nSessionizing web events by IP address and host with 5-minute gap...")
        print("\nQuestions to be answered:")
        print("1. What is the average number of web events per session from a user on Tech Creator?")
        print("2. Compare results between different hosts:")
        print("   - zachwilson.techcreator.io")
        print("   - zachwilson.tech")
        print("   - lulu.techcreator.io")
        print("\nResults will be written to the 'sessionized_events' table in PostgreSQL")
        print("Run the following query to get statistics:")
        print(stats_query)
        print("=" * 80)
        
        # Wait for job completion
        # In production, this would run continuously
        
    except Exception as e:
        print(f"Sessionization job failed: {str(e)}")
        raise


if __name__ == '__main__':
    sessionize_web_events()
