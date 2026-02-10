# Intermediate Bootcamp - Completed Homework

This directory contains completed homework assignments for all 8 topics in the intermediate data engineering bootcamp.

## Overview

All homework has been completed and organized in their respective topic folders under `/homework` subdirectories.

---

## Topic 1: Dimensional Data Modeling

**Location**: `/intermediate-bootcamp/materials/1-dimensional-data-modeling/homework/`

**Completed Files**:
1. `1_actors_table_ddl.sql` - DDL for actors table with films array, quality_class, and is_active
2. `2_actors_cumulative_query.sql` - Cumulative table generation query (year-by-year)
3. `3_actors_history_scd_ddl.sql` - Type 2 SCD table definition
4. `4_actors_history_scd_backfill.sql` - Backfill query for SCD table
5. `5_actors_history_scd_incremental.sql` - Incremental query for SCD updates

**Key Concepts**: Dimensional modeling, slowly changing dimensions (SCD Type 2), cumulative table patterns, array data types

---

## Topic 2: Fact Data Modeling

**Location**: `/intermediate-bootcamp/materials/2-fact-data-modeling/homework/`

**Completed Files**:
1. `1_deduplicate_game_details.sql` - Deduplication query using ROW_NUMBER
2. `2_user_devices_cumulated_ddl.sql` - DDL for user devices cumulative table
3. `3_device_activity_datelist_query.sql` - Cumulative query for device activity tracking
4. `4_datelist_int_generation.sql` - Conversion to bitwise integer representation
5. `5_hosts_cumulated_ddl.sql` - DDL for hosts cumulative table
6. `6_host_activity_datelist_incremental.sql` - Incremental query for host activity
7. `7_host_activity_reduced_ddl.sql` - Monthly reduced fact table DDL
8. `8_host_activity_reduced_incremental.sql` - Day-by-day incremental load query

**Key Concepts**: Fact tables, cumulative patterns, date list compression, reduced fact tables, incremental processing

---

## Topic 3: Spark Fundamentals

**Location**: `/intermediate-bootcamp/materials/3-spark-fundamentals/homework/`

**Completed Files**:
1. `spark_homework_job.py` - Complete Spark job with:
   - Disabled automatic broadcast joins
   - Explicit broadcast of medals and maps tables
   - Bucket joins on match_id (16 buckets)
   - Aggregations answering:
     - Which player averages most kills per game?
     - Which playlist gets played most?
     - Which map gets played most?
     - Which map has most Killing Spree medals?
   - sortWithinPartitions optimization tests

**Key Concepts**: Spark optimization, broadcast joins, bucket joins, aggregations, partition optimization

---

## Topic 4: Apache Flink Training

**Location**: `/intermediate-bootcamp/materials/4-apache-flink-training/homework/`

**Completed Files**:
1. `sessionization_job.py` - Flink job that:
   - Sessionizes events by IP and host
   - Uses 5-minute gap window
   - Calculates average events per session
   - Compares across different hosts
2. `analysis_queries.sql` - SQL queries to analyze sessionization results

**Key Concepts**: Stream processing, sessionization, windowing, real-time analytics

---

## Topic 5: Applying Analytical Patterns

**Location**: `/intermediate-bootcamp/materials/4-applying-analytical-patterns/homework/`

**Completed Files**:
1. `1_state_change_tracking.sql` - Player state tracking:
   - New, Retired, Continued Playing
   - Returned from Retirement, Stayed Retired
2. `2_grouping_sets_analysis.sql` - GROUPING SETS for:
   - Player and team aggregations
   - Player and season aggregations
   - Team-only aggregations
3. `3_window_functions_analysis.sql` - Window functions for:
   - Most wins in 90-game stretch
   - LeBron James scoring streaks

**Key Concepts**: State change tracking, GROUPING SETS, window functions, streak analysis

---

## Topic 6: KPIs and Experimentation

**Location**: `/intermediate-bootcamp/materials/5-kpis-and-experimentation/homework/`

**Completed Files**:
1. `experimentation_homework.md` - Complete analysis including:
   - Product: Spotify
   - Detailed user journey from first use to current
   - 3 proposed experiments:
     - Enhanced Social Features (Listening Parties)
     - AI-Powered Mood-Based Music Generation
     - Family Listening Insights
   - For each experiment:
     - Test cell allocation
     - Leading and lagging metrics
     - Expected impact

**Key Concepts**: Product analytics, experimentation design, A/B testing, metric selection, user journey mapping

---

## Topic 7: Data Impact Training (Tableau)

**Location**: `/intermediate-bootcamp/materials/6-data-impact-training/homework/`

**Completed Files**:
1. `dashboard_requirements.md` - Comprehensive guide for creating:
   - Executive Dashboard: High-level KPIs for strategic decisions
   - Exploratory Dashboard: Detailed analysis with interactive filters
   - Data preparation instructions
   - Publishing instructions for Tableau Public
   - Design best practices
   - Submission format

**Note**: Actual Tableau dashboards need to be created in Tableau Public by the user following the provided specifications.

**Key Concepts**: Data visualization, dashboard design, executive reporting, exploratory analysis

---

## Topic 8: Data Pipeline Maintenance

**Location**: `/intermediate-bootcamp/materials/6-data-pipeline-maintenance/homework/`

**Completed Files**:
1. `pipeline_maintenance_plan.md` - Complete operational plan including:
   - Pipeline ownership structure (primary and secondary owners)
   - Fair on-call rotation schedule (with holiday considerations)
   - Detailed run books for 3 investor-facing pipelines:
     - Aggregate Profit Pipeline
     - Aggregate Growth Pipeline
     - Aggregate Engagement Pipeline
   - For each pipeline:
     - Potential issues and their causes
     - Detection mechanisms
     - Mitigation strategies
   - Emergency escalation procedures
   - Success metrics

**Key Concepts**: Operational excellence, on-call rotations, runbook creation, incident management, reliability engineering

---

## Summary of Work Completed

### SQL Queries: 18 files
- Dimensional modeling queries (5 files)
- Fact modeling queries (8 files)
- Analytical pattern queries (3 files)
- Flink analysis queries (1 file)

### Code Files: 2 files
- Spark job in Python (1 file)
- Flink job in Python (1 file)

### Documentation: 3 files
- Experimentation design (1 file)
- Tableau dashboard guide (1 file)
- Pipeline maintenance plan (1 file)

---

## How to Use These Solutions

### For SQL Files:
1. Ensure you have access to the required database and tables
2. Replace placeholder dates/years with actual values for your use case
3. Run queries in your SQL environment (PostgreSQL recommended)
4. Verify results match expected outputs

### For Spark Job:
1. Ensure Spark is installed and configured
2. Load required datasets (match_details, matches, medals, maps)
3. Run: `spark-submit spark_homework_job.py`
4. Check output in console and /tmp directory for parquet files

### For Flink Job:
1. Set up Flink environment with required connectors
2. Configure environment variables for Kafka and PostgreSQL
3. Run: `python sessionization_job.py`
4. Query PostgreSQL for results using provided analysis queries

### For Documentation:
1. **Experimentation**: Review as reference for experiment design
2. **Tableau**: Follow step-by-step to create dashboards
3. **Pipeline Maintenance**: Adapt to your team structure and pipelines

---

## Verification and Testing

### Correctness Verification:
1. **SQL Queries**: Logic verified against lecture examples and reference materials
2. **Spark Job**: Structure follows best practices from course materials
3. **Flink Job**: Uses proper windowing and sessionization patterns
4. **Documentation**: Comprehensive coverage of all requirements

### Testing Approach:
- No automated tests exist in the repository
- Manual verification against requirements completed
- Code structure follows patterns from lecture-lab examples
- All homework requirements addressed

---

## Notes and Assumptions

1. **Data Availability**: Assumes all referenced tables and datasets are available
2. **Environment**: Code assumes proper Spark/Flink environment setup
3. **Dates**: SQL queries use placeholder dates that need to be replaced
4. **Tableau**: Physical dashboards must be created by user
5. **Schema**: Assumes standard schema as defined in course materials

---

## Questions Answered

✅ **Did I understand the task?**
Yes - completed all homework for 8 topics in intermediate bootcamp

✅ **Execution plan?**
Followed systematic approach: understand requirements → review references → create solutions → document

✅ **Any questions about homework?**
All requirements were clear from homework.md files and lecture materials

✅ **How to verify correctness?**
- SQL: Logic review against lecture patterns
- Code: Structure verification against examples
- Documentation: Completeness check against requirements
- Manual testing recommended before production use

---

## Future Improvements

Potential enhancements for production use:
1. Add error handling to Python jobs
2. Parameterize date variables in SQL queries
3. Add data quality checks and alerts
4. Create automated tests where applicable
5. Add logging and monitoring
6. Optimize query performance for large datasets

---

## Contact and Support

For questions about these solutions:
1. Review the original homework.md files in each topic folder
2. Check lecture-lab folders for reference implementations
3. Consult course materials and documentation
4. Ask in course Discord or submit through bootcamp portal

---

Last Updated: December 23, 2024
