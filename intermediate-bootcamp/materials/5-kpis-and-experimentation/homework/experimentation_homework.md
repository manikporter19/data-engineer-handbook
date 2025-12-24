# KPIs and Experimentation Homework

## Product Selection: Spotify

Spotify is a music streaming platform that I use daily. Below is my analysis of the user journey and proposed experiments.

---

## User Journey: From First Use to Current Experience

### Initial Discovery and Onboarding (First Week)
- **Discovery**: Found Spotify through recommendations from friends and online reviews
- **Sign-up**: Created a free account with email - simple, frictionless process
- **First Impression**: Clean interface, easy to search for favorite artists
- **What I Loved**: 
  - Instant access to millions of songs
  - Personalized playlists appeared quickly (Discover Weekly concept was exciting)
  - Easy to create and share playlists with friends

### Growth Phase (Months 1-6)
- **Engagement Increase**: Started using Spotify daily during commute and work
- **Discovery Features**: 
  - Discover Weekly became my Monday ritual
  - Release Radar helped me stay updated with favorite artists
  - Collaborative playlists for parties and events
- **What I Loved**:
  - Music recommendation algorithm was surprisingly accurate
  - Seamless transition between devices (phone, laptop, smart speaker)
  - Ability to download music for offline listening (after premium upgrade)

### Premium Conversion (Month 3)
- **Trigger**: Ads became disruptive during focused work sessions
- **Decision**: Converted to Premium for ad-free experience and offline downloads
- **Value Realized**: Significantly better experience, felt worth the cost

### Current Usage (Present Day)
- **Daily Active User**: Use Spotify 2-3 hours per day
- **Primary Use Cases**:
  - Background music during work (focus playlists)
  - Discovering new music (Discover Weekly, Daily Mixes)
  - Podcast listening (added value beyond music)
  - Social sharing of favorite songs and playlists
- **What I Still Love**:
  - Consistent quality of recommendations
  - Wrapped annual summary (creates viral moment)
  - Cross-platform synchronization
  - Podcast integration in same app

---

## Proposed Experiments

### Experiment 1: Enhanced Social Features - "Listening Parties"

**Hypothesis**: Adding real-time collaborative listening sessions will increase user engagement and retention among friend groups.

#### Randomization & Eligibility

**Unit of Randomization**:
- **Social graph cluster** (to handle network effects and prevent SUTVA violations)
- Users within the same social community are assigned to the same treatment cell
- Only treatment users can create listening parties (prevents cross-contamination)
- Analysis unit: Inviter/creator level (users who initiate parties)

**Eligibility Criteria**:
- Users with ≥ 3 friends on Spotify (have social graph connections)
- OR users who have used sharing features in past 90 days
- Active Spotify users with ≥ 1 session in past 14 days
- Excludes users under 13 years old (content moderation complexity)

**Exposure Definition**:
- User has feature flag enabled AND appears in an eligible session
- For Treatment A: Exposed when user creates or joins ≥ 1 listening party
- For Treatment B: Exposed when user creates or joins ≥ 1 listening party with voice/reactions

**Adoption Metric**:
- **Creator adoption**: % of users who create ≥ 1 listening party within D14
- **Participant adoption**: % of users who join ≥ 1 listening party within D14
- **Repeat adoption**: % of users with ≥ 3 listening party sessions within D30

#### Test Cells
- **Control Group (40%)**: Current Spotify experience, no changes
- **Treatment A (30%)**: "Listening Party" feature with basic chat
  - Users can create virtual rooms
  - Friends can join and listen to same song simultaneously
  - Basic text chat during session
- **Treatment B (30%)**: Full "Listening Party" with enhanced features
  - All features from Treatment A
  - Voice chat option
  - Collaborative queue where participants can add songs
  - Reactions/emojis during playback

#### Metrics

**Primary Metric** (user-level):
- **28-day retention rate**: % of users who return to Spotify at least once in the 28 days following experiment enrollment

**Leading Indicators** (Days 1-14):
- Feature adoption rate (% of users who create/join a listening party)
- Average listening party duration
- Number of repeat listening party sessions per user
- Invitation sent rate
- Friend-to-friend engagement rate

**Lagging Indicators** (Days 14-90):
- Daily active users (DAU) growth
- Average session duration
- Premium conversion rate (hypothesis: more engaged users convert)
- Social sharing outside the app (viral coefficient)
- User satisfaction (NPS score)

#### Guardrail Metrics

**Reliability & Performance**:
- Crash rate: ≤ 0.5% (protect from voice/chat feature instability)
- Playback start latency: ≤ 2 seconds (ensure synchronized playback doesn't degrade UX)
- Audio sync lag between users: ≤ 500ms

**Content Safety & Moderation**:
- Abuse reports per DAU: ≤ 0.001 (monitor voice chat for harassment)
- Moderation cost per 1,000 sessions: ≤ $5 (voice transcription and flagging)

**Monetization Protection**:
- Ad impressions per free-tier session: ≥ baseline (ensure social features don't reduce ad exposure)
- Premium conversion rate: ≥ baseline (confirm social features don't cannibalize paid conversion)

**Cost Controls**:
- Voice infrastructure cost per listening party hour: ≤ $0.10
- Overall platform cost increase: ≤ 3%

#### Success Criteria & Decision Rules

**Ship Treatment A if**:
- Primary metric improves by ≥ +3% (ITT, p < 0.05)
- No guardrail degrades by > -2%
- Voice moderation cost per 1k sessions ≤ $5
- User feedback NPS ≥ 7/10

**Ship Treatment B if**:
- Primary metric improves by ≥ +5% (ITT, p < 0.05)
- No guardrail degrades by > -2%
- Voice infrastructure cost per hour ≤ $0.10
- Abuse report rate ≤ 0.001
- Can scale to 10% of user base within budget constraints

**Do not ship if**:
- Primary metric neutral or negative
- Any guardrail degrades > -5%
- Cost per incremental retained user > $2
- Content moderation requirements exceed operational capacity

---

### Experiment 2: AI-Powered Mood-Based Music Generation

**Hypothesis**: An AI DJ that automatically creates transitions between songs based on user mood and time of day will increase listening time and user satisfaction.

#### Randomization & Eligibility

**Unit of Randomization**:
- **User level** (independent experiences, low interference risk)
- Device consistency: User assigned to same treatment across all devices
- Platform-aware: Treatment experience adapts to mobile vs desktop

**Eligibility Criteria**:
- Users with ≥ 30 minutes per day baseline listening (past 30 days)
- Active Premium or Free tier users
- Excludes users with accessibility settings that conflict with voice prompts unless explicitly opted in
- Excludes accounts flagged for streaming fraud/abuse

**Exposure Definition**:
- User has feature flag enabled AND initiates ≥ 1 AI DJ session
- Treatment A: User clicks "Start AI DJ" button
- Treatment B: User clicks "Start AI DJ" and interacts with mood selector

**Adoption Metric**:
- **Trial adoption**: % of users who start ≥ 1 AI DJ session within D14
- **Regular adoption**: % of users who use AI DJ ≥ 3 times within D30
- **Habitual adoption**: % of users who use AI DJ ≥ 50% of listening sessions in D30

#### Test Cells
- **Control Group (50%)**: Standard playlist experience
- **Treatment A (25%)**: "AI DJ" feature with basic transitions
  - AI analyzes listening patterns
  - Creates smooth transitions between songs
  - Simple interface: "Start AI DJ" button
- **Treatment B (25%)**: Enhanced AI DJ with mood detection
  - All features from Treatment A
  - Mood selector (energetic, calm, focused, happy, etc.)
  - Time-of-day optimization
  - Voice prompts between songs (personalized DJ commentary)

#### Metrics

**Primary Metric** (user-level):
- **Average daily listening minutes per user**: Total minutes listened per day divided by active users

**Leading Indicators** (Days 1-30):
- AI DJ session starts per user
- Average AI DJ session duration vs. regular playlist
- Skip rate during AI DJ sessions
- User feedback ratings after sessions
- Time-to-next-song consistency

**Lagging Indicators** (Days 30-90):
- User satisfaction scores
- Feature stickiness (return rate to AI DJ)
- Premium retention rate
- Listening diversity (new artists/genres explored)
- User testimonials and app store ratings

#### Guardrail Metrics

**Reliability & Performance**:
- Crash rate: ≤ 0.5%
- Playback start latency: ≤ 1.5 seconds
- Rebuffer rate: ≤ 0.3% of playback time
- Track transition smoothness: ≥ 95% successful crossfades

**Content Quality**:
- Skip rate: ≤ baseline + 5% (ensure AI recommendations aren't worse than manual)
- Negative feedback rate: ≤ 2% of sessions
- Artist/genre diversity maintained: ≥ baseline

**Monetization Protection**:
- Ad impressions per free-tier session: ≥ baseline
- Ad revenue per free user: ≥ baseline (ensure AI DJ doesn't reduce ad exposure)
- Premium conversion rate: ≥ baseline

**Cost Controls**:
- TTS/LLM inference cost per listening hour: ≤ $0.02 (Treatment B voice prompts)
- AI recommendation compute cost per user per month: ≤ $0.05
- Overall infrastructure cost increase: ≤ 5%

#### Success Criteria & Decision Rules

**Ship Treatment A if**:
- Primary metric improves by ≥ +5% (ITT, p < 0.05)
- No guardrail degrades by > -2%
- Skip rate increase ≤ +3%
- AI compute cost per incremental hour ≤ $0.03

**Ship Treatment B if**:
- Primary metric improves by ≥ +8% (ITT, p < 0.05)
- No guardrail degrades by > -2%
- TTS/LLM cost per hour ≤ $0.02
- User satisfaction score ≥ 8/10
- Feature can scale to 50% of user base within budget

**Do not ship if**:
- Primary metric neutral or negative
- Skip rate increases > +5%
- Any guardrail degrades > -5%
- Cost per incremental listening hour > $0.05
- Negative user feedback > 5%

---

### Experiment 3: "Family Listening Insights" for Family Plan Users

**Hypothesis**: Providing aggregated, privacy-respecting insights about family listening habits will increase family plan retention and satisfaction.

#### Randomization & Eligibility

**Unit of Randomization**:
- **Family account/household level** (prevents spillover within families)
- All members of the family account are assigned to the same treatment
- Analysis unit: Family account (not individual users to avoid double-counting)

**Eligibility Criteria**:
- Active family plans with ≥ 2 active members (≥ 1 session in past 30 days)
- Family plans active for ≥ 60 days (exclude new signups still in trial phase)
- Excludes accounts with minors unless parental controls and consent are incorporated
- Account in good standing (no payment issues or policy violations)

**Exposure Definition**:
- Family account has feature flag enabled AND primary account holder views insights
- Treatment A: Email report is opened or dashboard link is clicked
- Treatment B: In-app dashboard is visited ≥ 1 time

**Adoption Metric**:
- **Email engagement**: % of families who open ≥ 1 monthly report within D30
- **Dashboard adoption**: % of families who visit dashboard ≥ 1 time within D30
- **Active adoption**: % of families where ≥ 2 members view insights within D60
- **Feature retention**: % of families that engage with insights monthly over D90

#### Test Cells
- **Control Group (60%)**: Current family plan experience
- **Treatment A (20%)**: Monthly family listening report
  - Top songs/artists across family
  - Listening time breakdown by family member (anonymized)
  - Shared playlist recommendations
  - Email delivery only
- **Treatment B (20%)**: Interactive family listening hub
  - All features from Treatment A
  - In-app interactive dashboard
  - Family playlist challenges
  - Shared Wrapped-style year-end summary
  - Optional: family listening stats visible to all members

#### Metrics

**Primary Metric** (account-level):
- **90-day family plan retention rate**: % of family plan accounts that remain subscribed 90 days after experiment enrollment

**Leading Indicators** (Days 1-30):
- Report open rate (email)
- Dashboard visit rate (in-app)
- Family playlist creation rate
- Challenge participation rate
- Social sharing of family insights

**Lagging Indicators** (Days 30-180):
- Family plan referral rate (new family plans created)
- Average family plan size
- Overall family plan satisfaction (survey)
- Customer support tickets related to family plans
- Lifetime value (LTV) of family plan subscribers

#### Guardrail Metrics

**Privacy & Trust**:
- Privacy complaint rate: ≤ 0.01% of family accounts
- Opt-out rate from insights: ≤ 5%
- Family member removal rate: ≤ baseline (ensure insights don't cause friction)

**Reliability & Performance**:
- Dashboard load time: ≤ 2 seconds
- Email delivery success rate: ≥ 98%
- Data accuracy: ≥ 99.5% (ensure insights are trustworthy)

**Monetization Protection**:
- Average revenue per family account: ≥ baseline
- Family plan downgrades to individual: ≤ baseline + 1%
- Churn within 30 days of insights: ≤ baseline

**Cost Controls**:
- Analytics computation cost per family account per month: ≤ $0.10
- Email delivery cost per report: ≤ $0.01
- Storage cost per family account: ≤ $0.05/month
- Overall feature cost per retained family: ≤ $2/year

#### Success Criteria & Decision Rules

**Ship Treatment A if**:
- Primary metric improves by ≥ +3% (ITT, p < 0.05)
- No guardrail degrades by > -2%
- Email open rate ≥ 40%
- Privacy complaints ≤ 0.01%
- Cost per incremental retained family ≤ $10

**Ship Treatment B if**:
- Primary metric improves by ≥ +5% (ITT, p < 0.05)
- No guardrail degrades by > -2%
- Dashboard engagement ≥ 30% monthly active users
- Analytics cost per account ≤ $0.10/month
- Positive satisfaction score ≥ 8/10
- Can scale to all family plans within infrastructure budget

**Do not ship if**:
- Primary metric neutral or negative
- Privacy complaint rate > 0.05%
- Any guardrail degrades > -5%
- Cost per incremental retained family > $15
- Opt-out rate > 10%
- Feature causes increase in family plan downgrades

---

## Summary

All three experiments are designed to:
1. **Increase Engagement**: More time spent in the app
2. **Improve Retention**: Keep users coming back
3. **Drive Conversion**: Free users to Premium, single users to Family plans
4. **Enhance Satisfaction**: Better user experience leads to positive word-of-mouth

The experiments follow a staged rollout approach (control + 2 treatment groups) to understand which feature implementations provide the best return on investment while minimizing risk.

### Key Experiment Design Principles Applied

**1. Clear Primary Metrics**:
- Experiment 1: 28-day retention rate (user-level)
- Experiment 2: Average daily listening minutes per user
- Experiment 3: 90-day family plan retention rate (account-level)

**2. Comprehensive Guardrail Metrics**:
- **Reliability**: Crash rates, latency, rebuffer rates to protect user experience
- **Content Safety**: Abuse reports and moderation costs for social/voice features
- **Monetization**: Ad impressions and revenue protection for free tier
- **Cost Controls**: Infrastructure and operational cost thresholds per experiment
- **Privacy & Trust**: Privacy complaints and opt-out rates (Experiment 3)

**3. Explicit Decision Rules**:
- Each treatment has clear success criteria with statistical significance thresholds (p < 0.05)
- Minimum improvement thresholds prevent shipping marginal wins
- Guardrail bounds prevent shipping features that harm other aspects of the platform
- Cost-per-outcome thresholds ensure economic viability
- "Do not ship" criteria protect against launching harmful features

**4. Avoiding Common Pitfalls**:
- Single primary metric per experiment prevents p-hacking
- Leading/lagging indicator separation enables early signal detection
- Guardrails ensure holistic platform health
- Cost controls prevent budget overruns
- Treatment comparisons (A vs B) enable incremental feature investment decisions

**5. Measurement Windows & ITT/TOT Analysis**:

All experiments use **standardized measurement windows**:
- **Leading indicators**: D1-14 (early signal detection)
- **Primary metric measurement**: D1-28 (Exp 1, 2) or D1-90 (Exp 3)
- **Lagging indicators**: D29-90 (Exp 1, 2) or D91-180 (Exp 3)

**Intent-to-Treat (ITT) vs. Treatment-on-Treated (TOT)**:
- **ITT** (primary): Includes all randomized users, regardless of exposure
  - Used for all ship/no-ship decisions
  - Represents real-world deployment impact
  - Conservative estimate, accounts for non-compliance
  
- **TOT** (secondary): Includes only users who actually used the feature
  - Used for mechanism insight and feature optimization
  - Helps understand feature effectiveness among adopters
  - NOT used for ship decisions (introduces selection bias)

**Example**:
- Exp 1: ITT = all users in treatment cell; TOT = users who created/joined ≥1 party
- Exp 2: ITT = all users with AI DJ enabled; TOT = users who started ≥1 AI DJ session
- Exp 3: ITT = all families assigned to treatment; TOT = families where account holder viewed insights

**6. Power Analysis & Sample Sizing**:

**Experiment 1 (Listening Parties)**:
- **Baseline**: 28-day retention = 35%
- **MDE (Minimum Detectable Effect)**: +3 percentage points (to 38%)
- **Sample size**: ~18,000 users per treatment arm
  - Power: 80%, alpha: 0.05
  - Bonferroni correction for 2 treatments: alpha = 0.025 per comparison
- **Test duration**: 4-6 weeks (28 days + 2 weeks ramp-up)
- **Seasonality**: Avoid major holidays, control for day-of-week effects

**Experiment 2 (AI DJ)**:
- **Baseline**: Average daily listening = 60 minutes
- **Standard deviation**: 45 minutes (typical for streaming platforms)
- **MDE**: +5 minutes per day (+8.3%)
- **Sample size**: ~25,000 users per treatment arm
  - Power: 80%, alpha: 0.05
  - Bonferroni correction for 2 treatments: alpha = 0.025
- **Test duration**: 2-4 weeks minimum (capture weekly patterns)
- **Seasonality**: Control for weekday vs. weekend listening patterns

**Experiment 3 (Family Insights)**:
- **Baseline**: 90-day family retention = 82%
- **MDE**: +2.5 percentage points (to 84.5%)
- **Sample size**: ~12,000 family accounts per treatment arm
  - Power: 80%, alpha: 0.05
  - Bonferroni correction for 2 treatments: alpha = 0.025
- **Test duration**: 12-16 weeks (90 days + ramp-up)
- **Long-term holdout**: Consider 5% permanent holdout for long-term validation
- **Sequential testing**: Use group sequential methods with O'Brien-Fleming boundaries to enable early stopping for futility or overwhelming success

**Statistical Considerations**:
- **Multiple comparisons**: Holm-Bonferroni method for family-wise error rate control
- **Peeking protection**: Pre-registered analysis plan, limited interim looks
- **Variance reduction**: CUPED (Controlled-experiment Using Pre-Experiment Data) to reduce variance using pre-period metrics
- **Heterogeneous effects**: Pre-specified subgroup analysis (e.g., by platform, user tenure, baseline engagement)
