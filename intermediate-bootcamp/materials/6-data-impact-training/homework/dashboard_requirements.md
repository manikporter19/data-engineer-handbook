# Data Impact Training Homework - Tableau Dashboards

## Assignment Requirements

Create two dashboards using Tableau Public:
1. **Executive Dashboard** - High-level KPIs and metrics
2. **Exploratory Dashboard** - Detailed analysis with filters

## Dashboard 1: Executive Dashboard

### Purpose
Provide high-level insights for executives to make strategic decisions quickly.

### Recommended Visualizations

#### Using Match Details Dataset (Recommended):
1. **Overall Performance KPIs** (Top of dashboard)
   - Total Matches Played (big number)
   - Total Players (big number)
   - Average Match Duration (big number)
   - Most Popular Game Mode (text/number)

2. **Match Trends Over Time**
   - Line chart: Matches per day/week/month
   - Shows growth or decline in game activity

3. **Top Performers**
   - Bar chart: Top 10 players by kills
   - Bar chart: Top 10 players by medals earned

4. **Game Mode Distribution**
   - Pie chart or treemap: Distribution of matches across playlists
   - Shows which game modes are most popular

5. **Map Popularity**
   - Horizontal bar chart: Matches played per map
   - Helps understand content usage

6. **Player Engagement Metrics**
   - Dual-axis chart: Average kills vs. average deaths by playlist
   - Shows which game modes are most competitive

### Design Guidelines
- **Clean Layout**: Use a grid layout with clear sections
- **Color Scheme**: Professional colors (blues, grays) with accent colors for highlights
- **Limited Filters**: Only date range and maybe top-level category
- **Annotations**: Add key insights directly on charts
- **Mobile-Friendly**: Consider how it looks on different screen sizes

---

## Dashboard 2: Exploratory Dashboard

### Purpose
Allow analysts and curious stakeholders to dive deep into the data with interactive filters.

### Recommended Visualizations

#### Using Match Details Dataset (Recommended):
1. **Interactive Filters Panel** (Left sidebar or top)
   - Date range picker
   - Player name dropdown (multi-select)
   - Map selector
   - Playlist selector
   - Medal type selector
   - Performance range sliders (kills, deaths, etc.)

2. **Player Performance Deep Dive**
   - Scatter plot: Kills vs. Deaths (with trend line)
   - Shows player efficiency
   - Size by matches played, color by map

3. **Time-Based Analysis**
   - Heatmap: Matches by day of week and hour
   - Shows when players are most active

4. **Medal Analysis**
   - Stacked bar chart: Medal types by player
   - Shows different skill patterns

5. **Map Performance Comparison**
   - Box plot or violin plot: Kill distribution by map
   - Shows difficulty or balance across maps

6. **Player Rankings Table**
   - Detailed table with sorting and highlighting
   - Columns: Player name, total kills, total deaths, K/D ratio, matches played, win rate
   - Conditional formatting for top performers

7. **Match Detail View**
   - Drill-down capability to see individual match statistics
   - Triggered by clicking on data points

### Design Guidelines
- **Information Density**: More charts and data than executive dashboard
- **Interactivity**: All filters affect all visualizations
- **Tooltips**: Rich tooltips with additional context
- **Cross-Filtering**: Click on one chart to filter others
- **Export Options**: Consider adding export capabilities

---

## Alternative: Using Web Events Dataset

If you prefer to use web events data instead of match details:

### Executive Dashboard (Web Events)
1. **Traffic KPIs**: Total visits, unique visitors, page views
2. **Traffic Trends**: Line chart of visits over time
3. **Top Pages**: Bar chart of most visited URLs
4. **Traffic Sources**: Pie chart of referrer distribution
5. **Host Performance**: Comparison across different hosts
6. **Device Breakdown**: Mobile vs. desktop traffic

### Exploratory Dashboard (Web Events)
1. **Filters**: Date, host, referrer, device type, browser
2. **User Journey**: Sankey diagram showing navigation flow
3. **Time Analysis**: Heatmap of traffic by day/hour
4. **Device Deep Dive**: Performance metrics by device and browser
5. **Referrer Analysis**: Detailed breakdown of traffic sources
6. **Session Analysis**: Distribution of session lengths and page views

---

## Data Preparation

### For Match Details Dataset:
1. Load `match_details`, `matches`, `medals`, and `medals_matches_players` tables
2. Join tables appropriately:
   - `match_details` ⋈ `matches` on `match_id`
   - `match_details` ⋈ `medals_matches_players` on `match_id` and `player_id`
   - `medals_matches_players` ⋈ `medals` on `medal_id`
3. Create calculated fields as needed:
   - K/D Ratio: `SUM([Kills]) / SUM([Deaths])`
   - Win Rate: `SUM([Wins]) / COUNT([Matches])`
   - Performance Score: Custom formula

### For Web Events Dataset:
1. Load `events` and `devices` tables
2. Join on `device_id`
3. Create calculated fields:
   - Unique Visitors: `COUNTD([user_id])`
   - Bounce Rate: Custom calculation
   - Average Session Duration: Time-based calculation

---

## Publishing to Tableau Public

### Steps:
1. **Create Dashboards in Tableau Desktop**
   - Tableau Public is free to download
   - Create your two dashboards

2. **Save to Tableau Public**
   - File → Tableau Public → Save to Tableau Public As...
   - Sign in to your Tableau Public account (create one if needed)
   - Give your workbook a descriptive name

3. **Configure Visibility**
   - Ensure dashboards are set to "Public"
   - Add descriptions and tags for discoverability

4. **Get Share Links**
   - After publishing, you'll get a URL like:
     `https://public.tableau.com/views/YourWorkbookName/Dashboard1`
   - Copy both dashboard URLs

5. **Prepare Submission**
   - Create a text file with both dashboard URLs
   - Add any notes about data sources or assumptions
   - Zip the text file
   - Submit according to course instructions

---

## Tips for Success

### Design Tips:
- **Tell a Story**: Dashboards should have a narrative flow
- **Consistency**: Use same colors, fonts, and styles across both dashboards
- **Performance**: Avoid too many complex calculations
- **Accessibility**: Consider color blindness in color choices
- **White Space**: Don't overcrowd - less is more

### Technical Tips:
- **Test Filters**: Make sure all filters work correctly
- **Cross-Check Data**: Verify calculations match source data
- **Mobile Test**: Check how dashboards look on mobile
- **Loading Time**: Optimize for fast loading

### Common Mistakes to Avoid:
- Too many metrics on executive dashboard
- No filters on exploratory dashboard
- Inconsistent color schemes
- Unlabeled axes or unclear legends
- No titles or descriptions
- Forgetting to make workbook public

---

## Example URLs Format

Create a text file named `tableau_dashboards.txt`:

```
Name: [Your Name]
Course: Intermediate Bootcamp - Week 6

Executive Dashboard:
https://public.tableau.com/views/DataEngineerBootcamp/ExecutiveDashboard

Exploratory Dashboard:
https://public.tableau.com/views/DataEngineerBootcamp/ExploratoryDashboard

Data Source: Match Details dataset from Week 3 Spark Fundamentals
Notes: 
- Executive dashboard focuses on high-level KPIs for strategic decisions
- Exploratory dashboard allows deep dive analysis with multiple interactive filters
- All visualizations are cross-filtered for seamless exploration
```

Zip this file and submit according to course instructions.

---

## Additional Resources

- [Tableau Public Gallery](https://public.tableau.com/gallery/) - Inspiration
- [Tableau Documentation](https://help.tableau.com/) - Technical help
- [Dashboard Design Best Practices](https://help.tableau.com/current/blueprint/en-us/bp_visual_best_practices.htm)
- Course Discord Channel - Ask questions and share progress

Good luck with your dashboards! 🎨📊
