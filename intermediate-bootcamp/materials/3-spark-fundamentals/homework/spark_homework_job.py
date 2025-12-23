"""
Spark Fundamentals Homework
Build a Spark job that:
- Disables automatic broadcast join
- Explicitly broadcasts medals and maps
- Bucket joins match_details, matches, and medal_matches_players on match_id with 16 buckets
- Aggregates data to answer key questions
- Optimizes with sortWithinPartitions
"""

from pyspark.sql import SparkSession
from pyspark.sql.functions import col, avg, count, sum as spark_sum, desc


def main():
    # Initialize Spark session
    spark = SparkSession.builder \
        .master("local") \
        .appName("spark_fundamentals_homework") \
        .getOrCreate()
    
    # Disable automatic broadcast join
    spark.conf.set("spark.sql.autoBroadcastJoinThreshold", "-1")
    
    # Read the datasets
    # Assuming tables are already loaded in the Spark catalog
    match_details = spark.table("match_details")
    matches = spark.table("matches")
    medals_matches_players = spark.table("medals_matches_players")
    medals = spark.table("medals")
    maps = spark.table("maps")
    
    # Create bucketed tables for match_details, matches, and medals_matches_players
    # Note: In production, these would be created once and reused
    match_details.write \
        .bucketBy(16, "match_id") \
        .mode("overwrite") \
        .saveAsTable("match_details_bucketed")
    
    matches.write \
        .bucketBy(16, "match_id") \
        .mode("overwrite") \
        .saveAsTable("matches_bucketed")
    
    medals_matches_players.write \
        .bucketBy(16, "match_id") \
        .mode("overwrite") \
        .saveAsTable("medals_matches_players_bucketed")
    
    # Read bucketed tables
    match_details_bucketed = spark.table("match_details_bucketed")
    matches_bucketed = spark.table("matches_bucketed")
    medals_matches_players_bucketed = spark.table("medals_matches_players_bucketed")
    
    # Explicitly broadcast small tables (medals and maps)
    medals_broadcast = spark.broadcast(medals)
    maps_broadcast = spark.broadcast(maps)
    
    # Perform bucket joins
    # Join match_details with matches on match_id
    joined_df = match_details_bucketed.join(
        matches_bucketed,
        on="match_id",
        how="inner"
    )
    
    # Join with medals_matches_players on match_id
    joined_df = joined_df.join(
        medals_matches_players_bucketed,
        on=["match_id", "player_id"],  # Assuming player_id exists in both
        how="left"
    )
    
    # Broadcast join with medals
    joined_df = joined_df.join(
        medals_broadcast,
        on="medal_id",  # Assuming medal_id is the join key
        how="left"
    )
    
    # Broadcast join with maps
    joined_df = joined_df.join(
        maps_broadcast,
        on="map_id",  # Assuming map_id is the join key
        how="inner"
    )
    
    # Register as temp view for SQL queries
    joined_df.createOrReplaceTempView("joined_data")
    
    print("=" * 80)
    print("Question 1: Which player averages the most kills per game?")
    print("=" * 80)
    most_kills_per_game = spark.sql("""
        SELECT 
            player_id,
            player_name,
            AVG(kills) as avg_kills_per_game,
            COUNT(DISTINCT match_id) as total_games
        FROM joined_data
        GROUP BY player_id, player_name
        ORDER BY avg_kills_per_game DESC
        LIMIT 10
    """)
    most_kills_per_game.show()
    
    print("\n" + "=" * 80)
    print("Question 2: Which playlist gets played the most?")
    print("=" * 80)
    most_played_playlist = spark.sql("""
        SELECT 
            playlist_id,
            playlist_name,
            COUNT(DISTINCT match_id) as total_matches
        FROM joined_data
        GROUP BY playlist_id, playlist_name
        ORDER BY total_matches DESC
        LIMIT 10
    """)
    most_played_playlist.show()
    
    print("\n" + "=" * 80)
    print("Question 3: Which map gets played the most?")
    print("=" * 80)
    most_played_map = spark.sql("""
        SELECT 
            map_id,
            map_name,
            COUNT(DISTINCT match_id) as total_matches
        FROM joined_data
        GROUP BY map_id, map_name
        ORDER BY total_matches DESC
        LIMIT 10
    """)
    most_played_map.show()
    
    print("\n" + "=" * 80)
    print("Question 4: Which map do players get the most Killing Spree medals on?")
    print("=" * 80)
    killing_spree_by_map = spark.sql("""
        SELECT 
            map_id,
            map_name,
            COUNT(*) as killing_spree_count
        FROM joined_data
        WHERE medal_name = 'Killing Spree'
        GROUP BY map_id, map_name
        ORDER BY killing_spree_count DESC
        LIMIT 10
    """)
    killing_spree_by_map.show()
    
    # Aggregate dataset for sortWithinPartitions optimization
    print("\n" + "=" * 80)
    print("Testing sortWithinPartitions with different columns")
    print("=" * 80)
    
    aggregated_df = joined_df.groupBy(
        "match_id", "map_name", "playlist_name", "player_id"
    ).agg(
        spark_sum("kills").alias("total_kills"),
        spark_sum("deaths").alias("total_deaths")
    )
    
    # Test 1: Sort by playlist (low cardinality)
    print("\nTest 1: Sorting by playlist_name")
    sorted_by_playlist = aggregated_df.repartition("match_id") \
        .sortWithinPartitions("playlist_name")
    
    # Write to check data size
    sorted_by_playlist.write.mode("overwrite").parquet("/tmp/sorted_by_playlist")
    
    # Test 2: Sort by map (low cardinality)
    print("Test 2: Sorting by map_name")
    sorted_by_map = aggregated_df.repartition("match_id") \
        .sortWithinPartitions("map_name")
    
    sorted_by_map.write.mode("overwrite").parquet("/tmp/sorted_by_map")
    
    # Test 3: Sort by player_id (high cardinality)
    print("Test 3: Sorting by player_id")
    sorted_by_player = aggregated_df.repartition("match_id") \
        .sortWithinPartitions("player_id")
    
    sorted_by_player.write.mode("overwrite").parquet("/tmp/sorted_by_player")
    
    # Test 4: Sort by match_id (high cardinality)
    print("Test 4: Sorting by match_id")
    sorted_by_match = aggregated_df.repartition("match_id") \
        .sortWithinPartitions("match_id")
    
    sorted_by_match.write.mode("overwrite").parquet("/tmp/sorted_by_match")
    
    print("\n" + "=" * 80)
    print("Checking file sizes for different sort strategies:")
    print("=" * 80)
    print("Low cardinality columns (playlist, map) typically result in better compression")
    print("Check the /tmp directory for the actual file sizes")
    
    spark.stop()


if __name__ == "__main__":
    main()
