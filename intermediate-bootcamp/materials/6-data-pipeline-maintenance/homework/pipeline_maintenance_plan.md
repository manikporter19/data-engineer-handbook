# Data Pipeline Maintenance Homework

## Team Setup
Team of 4 data engineers managing 5 critical pipelines across different business areas.

---

## Pipeline Ownership Structure

### Team Members
1. **Alice Chen** - Senior Data Engineer
2. **Bob Martinez** - Senior Data Engineer  
3. **Carol Zhang** - Data Engineer
4. **David Johnson** - Data Engineer

### Pipeline Ownership Assignment

#### Pipeline 1: Unit-Level Profit (Experiments)
- **Primary Owner**: Carol Zhang
- **Secondary Owner**: David Johnson
- **Rationale**: 
  - Unit-level data requires strong attention to detail
  - Carol has experience with experimentation frameworks
  - David provides good backup with analytical mindset

#### Pipeline 2: Aggregate Profit (Investors)
- **Primary Owner**: Alice Chen
- **Secondary Owner**: Bob Martinez
- **Rationale**: 
  - High-stakes investor reporting requires senior oversight
  - Alice has strong business acumen and stakeholder management
  - Bob provides senior-level backup for critical pipeline

#### Pipeline 3: Daily Growth (Experiments)
- **Primary Owner**: David Johnson
- **Secondary Owner**: Carol Zhang
- **Rationale**: 
  - Daily frequency requires reliable engineer
  - David's consistency makes him ideal
  - Carol as backup maintains continuity with unit-level profit

#### Pipeline 4: Aggregate Growth (Investors)
- **Primary Owner**: Bob Martinez
- **Secondary Owner**: Alice Chen
- **Rationale**: 
  - Pairs with aggregate profit for investor reporting
  - Bob can coordinate investor metrics cohesively
  - Alice provides senior backup

#### Pipeline 5: Aggregate Engagement (Investors)
- **Primary Owner**: Alice Chen
- **Secondary Owner**: Carol Zhang
- **Rationale**: 
  - Alice balances investor reporting load with Bob
  - Carol provides cross-training opportunity on investor metrics
  - Develops Carol's experience with stakeholder-facing pipelines

---

## On-Call Schedule

### Rotation Philosophy
- **2-week rotations** to balance workload and context switching
- **Staggered start dates** to ensure overlap and knowledge transfer
- **Holiday considerations** built into schedule
- **Backup on-call** for escalations and primary unavailability

### Annual Schedule (2024 Example)

#### Q1 (January - March)

| Weeks | Primary On-Call | Backup On-Call | Notes |
|-------|----------------|----------------|-------|
| Jan 1-2 | Bob Martinez | Alice Chen | New Year's coverage |
| Jan 3-4, 15-16 | Carol Zhang | David Johnson | |
| Jan 17-30 | David Johnson | Carol Zhang | |
| Jan 31 - Feb 13 | Alice Chen | Bob Martinez | |
| Feb 14-27 | Bob Martinez | Alice Chen | Valentine's Day week |
| Feb 28 - Mar 12 | Carol Zhang | David Johnson | |
| Mar 13-26 | David Johnson | Carol Zhang | |
| Mar 27 - Apr 9 | Alice Chen | Bob Martinez | |

#### Q2 (April - June)

| Weeks | Primary On-Call | Backup On-Call | Notes |
|-------|----------------|----------------|-------|
| Apr 10-23 | Bob Martinez | Alice Chen | |
| Apr 24 - May 7 | Carol Zhang | David Johnson | |
| May 8-21 | David Johnson | Carol Zhang | |
| May 22 - Jun 4 | Alice Chen | Bob Martinez | Memorial Day |
| Jun 5-18 | Bob Martinez | Alice Chen | |
| Jun 19 - Jul 2 | Carol Zhang | David Johnson | |

#### Q3 (July - September)

| Weeks | Primary On-Call | Backup On-Call | Notes |
|-------|----------------|----------------|-------|
| Jul 3-16 | David Johnson | Carol Zhang | July 4th holiday |
| Jul 17-30 | Alice Chen | Bob Martinez | |
| Jul 31 - Aug 13 | Bob Martinez | Alice Chen | |
| Aug 14-27 | Carol Zhang | David Johnson | |
| Aug 28 - Sep 10 | David Johnson | Carol Zhang | Labor Day |
| Sep 11-24 | Alice Chen | Bob Martinez | |
| Sep 25 - Oct 8 | Bob Martinez | Alice Chen | |

#### Q4 (October - December)

| Weeks | Primary On-Call | Backup On-Call | Notes |
|-------|----------------|----------------|-------|
| Oct 9-22 | Carol Zhang | David Johnson | |
| Oct 23 - Nov 5 | David Johnson | Carol Zhang | |
| Nov 6-19 | Alice Chen | Bob Martinez | |
| Nov 20 - Dec 3 | Bob Martinez | Alice Chen | Thanksgiving (light load) |
| Dec 4-17 | Carol Zhang | David Johnson | |
| Dec 18-31 | Alice Chen | Bob Martinez | Christmas/New Year (light load) |

### Holiday Considerations

#### Major Holidays with Adjusted Coverage:
1. **New Year's (Dec 28 - Jan 2)**
   - Senior engineers (Alice/Bob) take primary
   - Reduced monitoring, investor metrics still critical
   
2. **Memorial Day (Last Monday of May)**
   - Ensure backup is available if primary is off
   
3. **July 4th Week**
   - Light experiment load, maintain investor metrics
   
4. **Labor Day (First Monday of September)**
   - Standard coverage with backup awareness
   
5. **Thanksgiving Week (4th Thursday of November)**
   - Senior engineer primary, experiment pipelines can pause
   
6. **Christmas/New Year (Dec 24 - Jan 1)**
   - Rotating senior coverage
   - Experiment pipelines paused
   - Investor metrics on reduced schedule (weekly instead of daily)

### On-Call Responsibilities
- Monitor pipeline health dashboards
- Respond to alerts within 30 minutes (business hours) or 1 hour (off-hours)
- Triage and fix issues or escalate to backup
- Document incidents in shared log
- Hand off open issues during rotation transition

---

## Run Books for Investor Metrics Pipelines

### Run Book 1: Aggregate Profit Pipeline

#### Pipeline Overview
- **Owner**: Alice Chen (Primary), Bob Martinez (Secondary)
- **Schedule**: Daily at 6 AM EST
- **Runtime**: ~45 minutes
- **Dependencies**: 
  - Unit-level profit data (from experiments pipeline)
  - Revenue data from finance system
  - Cost data from operations system
- **Outputs**: 
  - `aggregate_profit_daily` table
  - Investor dashboard auto-refresh
  - Email report to CFO

#### Potential Issues

##### Issue 1: Source Data Delay
**Symptom**: Pipeline times out waiting for revenue data
**Cause**: Finance system batch job delayed
**Impact**: Investor report delayed, dashboard shows stale data
**Detection**: Alert on pipeline runtime > 60 minutes
**Mitigation**: 
- Check finance system status dashboard
- Contact finance team if delay > 30 minutes
- Can run with T-1 data if necessary for critical reporting

##### Issue 2: Data Quality - Negative Profit
**Symptom**: Data validation fails, negative aggregate profit detected
**Cause**: Cost data duplicated or revenue data missing for major segment
**Impact**: Incorrect investor metrics, potential reporting to board
**Detection**: Data quality check in pipeline fails
**Mitigation**:
- Query source tables to identify segment with issue
- Contact source system owner
- Do NOT override - wait for correct data
- Notify stakeholders of delay

##### Issue 3: Historical Data Restatement
**Symptom**: Finance requests reprocessing of last 30 days
**Cause**: Accounting policy change or data correction
**Impact**: Investor metrics change historically
**Detection**: Manual request via ticket
**Mitigation**:
- Run backfill script: `python backfill_profit.py --start-date YYYY-MM-DD --end-date YYYY-MM-DD`
- Notify BI team to refresh investor dashboards
- Document change in monthly report

##### Issue 4: Downstream Dashboard Broken
**Symptom**: Dashboard shows no data or errors
**Cause**: Schema change in output table not reflected in dashboard
**Impact**: Investors cannot see metrics
**Detection**: Dashboard health check fails
**Mitigation**:
- Verify data exists in `aggregate_profit_daily`
- Check dashboard logs for errors
- Contact BI team for dashboard fix
- Provide CSV export as temporary workaround

---

### Run Book 2: Aggregate Growth Pipeline

#### Pipeline Overview
- **Owner**: Bob Martinez (Primary), Alice Chen (Secondary)
- **Schedule**: Daily at 7 AM EST (after profit pipeline)
- **Runtime**: ~30 minutes
- **Dependencies**: 
  - Daily growth data (from experiments pipeline)
  - User acquisition data from marketing system
  - Churn data from customer system
- **Outputs**: 
  - `aggregate_growth_metrics` table
  - Investor growth dashboard
  - Weekly board report (automated)

#### Potential Issues

##### Issue 1: Metric Spike/Drop Detection
**Symptom**: Alert fires for 20%+ change in growth rate
**Cause**: Could be real (product launch) or error (data duplication)
**Impact**: False alarm vs. missing critical insight
**Detection**: Automated anomaly detection alert
**Mitigation**:
- Compare to previous week same day
- Check for known product launches or campaigns
- Query source data for duplication
- If real, add annotation to dashboard
- If error, pause pipeline and investigate

##### Issue 2: Duplicate Records in Source
**Symptom**: Row count in staging table 2x expected
**Cause**: Source system sent data twice
**Impact**: Overstated growth metrics to investors
**Detection**: Row count validation check
**Mitigation**:
- Run deduplication query: `SELECT DISTINCT * FROM staging_growth`
- Identify source system issue and fix at root
- Rerun pipeline with deduplicated data
- Document incident

##### Issue 3: Marketing Data Missing
**Symptom**: User acquisition count is 0
**Cause**: Marketing data feed failed
**Impact**: Growth metrics incomplete, user breakdown missing
**Detection**: Data validation on acquisition_count > 0
**Mitigation**:
- Check marketing system status
- Contact marketing data team
- Can proceed with growth from existing users only
- Add caveat to investor report

##### Issue 4: Timezone Handling Issue
**Symptom**: Data doesn't match operations team's numbers
**Cause**: UTC vs. local time discrepancy
**Impact**: Off-by-one-day errors in reporting
**Detection**: Data reconciliation fails
**Mitigation**:
- Verify timestamp conversion logic
- Ensure all source systems use UTC
- Run query with explicit timezone conversion
- Document timezone standards

---

### Run Book 3: Aggregate Engagement Pipeline

#### Pipeline Overview
- **Owner**: Alice Chen (Primary), Carol Zhang (Secondary)
- **Schedule**: Daily at 8 AM EST
- **Runtime**: ~40 minutes
- **Dependencies**: 
  - Event tracking data from analytics platform
  - Session data from web/mobile apps
  - Feature usage data from product analytics
- **Outputs**: 
  - `aggregate_engagement_metrics` table
  - Investor engagement dashboard
  - Monthly active user (MAU) report

#### Potential Issues

##### Issue 1: Event Tracking Data Volume Spike
**Symptom**: Pipeline runs for 2+ hours instead of 40 minutes
**Cause**: Bot traffic, load testing, or viral product moment
**Impact**: Delayed metrics, potential data warehouse overload
**Detection**: Runtime alert at 90 minutes
**Mitigation**:
- Check for bot patterns in source data
- Filter out known bot IPs/user agents
- Implement sampling if truly high volume
- Consider adding aggregation layer upstream

##### Issue 2: MAU Calculation Incorrect
**Symptom**: Monthly active users drops 50% overnight
**Cause**: Logic error in user activity definition or date range
**Impact**: Alarming metric for investors, potential questions from board
**Detection**: Validation rule on MAU change > 20%
**Mitigation**:
- Review query logic for date filters
- Verify user activity definition hasn't changed
- Check for data source completeness
- Do NOT publish until resolved
- Communicate delay to stakeholders

##### Issue 3: Session Duration Anomaly
**Symptom**: Average session duration is 10x normal
**Cause**: Session timeout logic not applied, or users leaving tabs open
**Impact**: Inflated engagement metrics
**Detection**: Statistical anomaly detection
**Mitigation**:
- Apply session timeout (e.g., 30 minutes of inactivity)
- Review session definition with product team
- Adjust calculation to exclude outliers
- Document methodology change

##### Issue 4: Feature Usage Data Missing
**Symptom**: New feature shows 0 usage despite product launch
**Cause**: Instrumentation not deployed or event name mismatch
**Impact**: Incomplete engagement picture for investors
**Detection**: Manual check on known new features
**Mitigation**:
- Verify event tracking is deployed
- Check event name in source data
- Contact product analytics team
- Add placeholder or "data pending" note in report

---

## Emergency Escalation Procedures

### Level 1: Primary On-Call
- Handle routine issues
- Response SLA: 30 min (business hours), 1 hour (off-hours)

### Level 2: Backup On-Call
- Escalate if primary unavailable or issue beyond expertise
- Response SLA: 1 hour (business hours), 2 hours (off-hours)

### Level 3: Pipeline Owner
- Escalate for complex issues requiring deep knowledge
- Response SLA: 2 hours (business hours), 4 hours (off-hours)

### Level 4: Engineering Manager
- Escalate for critical incidents affecting investor reporting
- Response SLA: 1 hour (any time)

### Critical Incident Definition
- Investor metrics will miss reporting deadline
- Data quality issue affecting board-level decisions
- Security breach or data leak
- Complete pipeline failure for > 4 hours

---

## Success Metrics for Pipeline Maintenance

1. **Uptime**: 99.5% target for investor pipelines
2. **SLA Adherence**: 95% of pipelines complete on time
3. **Incident Response**: 90% of incidents resolved within SLA
4. **Data Quality**: < 0.1% error rate in investor metrics
5. **Stakeholder Satisfaction**: Quarterly survey score > 4.0/5.0

---

## Quarterly Review Process

Every quarter, the team will:
1. Review incident logs and common issues
2. Update run books with new learnings
3. Rotate backup owners for cross-training
4. Assess on-call load and adjust if needed
5. Propose pipeline improvements to reduce toil

---

This document should be stored in the team wiki and updated regularly based on learnings from incidents and changes to pipelines.
