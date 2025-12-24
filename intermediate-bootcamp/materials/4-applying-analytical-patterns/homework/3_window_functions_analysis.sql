-- Window Functions Analysis on game_details
-- Question 1: What is the most games a team has won in a 90 game stretch?
-- Question 2: How many games in a row did LeBron James score over 10 points?

-- Question 1: Most wins in a 90-game stretch for each team
-- This uses proper win calculation by comparing team total points per game
WITH team_pts AS (
    SELECT 
        g.game_id,
        g.game_date,
        gd.team_id,
        gd.team_abbreviation,
        SUM(gd.pts) as team_pts
    FROM game_details gd
    JOIN games g ON g.game_id = gd.game_id
    GROUP BY g.game_id, g.game_date, gd.team_id, gd.team_abbreviation
),
team_wins AS (
    SELECT 
        a.game_id,
        a.game_date,
        a.team_id,
        a.team_abbreviation,
        CASE 
            WHEN a.team_pts > b.team_pts THEN 1 
            ELSE 0 
        END as won
    FROM team_pts a
    JOIN team_pts b ON a.game_id = b.game_id AND a.team_id <> b.team_id
),
ordered AS (
    SELECT 
        *,
        ROW_NUMBER() OVER (PARTITION BY team_id ORDER BY game_date, game_id) as rn
    FROM team_wins
),
rolling AS (
    SELECT 
        team_id,
        team_abbreviation,
        game_date,
        rn,
        SUM(won) OVER (
            PARTITION BY team_id 
            ORDER BY rn 
            ROWS BETWEEN 89 PRECEDING AND CURRENT ROW
        ) as wins_in_90,
        COUNT(*) OVER (
            PARTITION BY team_id 
            ORDER BY rn 
            ROWS BETWEEN 89 PRECEDING AND CURRENT ROW
        ) as n_in_window
    FROM ordered
),
per_team_max AS (
    SELECT 
        team_id,
        team_abbreviation,
        MAX(wins_in_90) as max_wins_in_90
    FROM rolling
    WHERE n_in_window = 90  -- Only consider complete 90-game windows
    GROUP BY team_id, team_abbreviation
)
SELECT 
    team_abbreviation,
    max_wins_in_90
FROM per_team_max
ORDER BY max_wins_in_90 DESC
LIMIT 20;


-- Question 2: Longest streak of LeBron James scoring over 10 points
WITH lebron_games AS (
    SELECT 
        gd.game_id,
        g.game_date,
        gd.player_name,
        gd.pts,
        CASE WHEN gd.pts > 10 THEN 1 ELSE 0 END as scored_over_10,
        ROW_NUMBER() OVER (ORDER BY g.game_date) as game_number
    FROM game_details gd
    JOIN games g ON gd.game_id = g.game_id
    WHERE gd.player_name = 'LeBron James'
    ORDER BY g.game_date
),
streak_identified AS (
    SELECT 
        game_id,
        game_date,
        player_name,
        pts,
        scored_over_10,
        game_number,
        -- Create a group identifier for consecutive games scoring > 10
        -- When scored_over_10 changes from 1 to 0 or 0 to 1, increment group
        SUM(CASE 
            WHEN scored_over_10 = 1 
                AND LAG(scored_over_10, 1, 0) OVER (ORDER BY game_number) = 0 
            THEN 1 
            ELSE 0 
        END) OVER (ORDER BY game_number) as streak_group
    FROM lebron_games
),
streak_lengths AS (
    SELECT 
        streak_group,
        MIN(game_date) as streak_start_date,
        MAX(game_date) as streak_end_date,
        COUNT(*) as games_in_streak,
        AVG(pts) as avg_points_in_streak
    FROM streak_identified
    WHERE scored_over_10 = 1
    GROUP BY streak_group
)
SELECT 
    streak_group,
    streak_start_date,
    streak_end_date,
    games_in_streak,
    ROUND(avg_points_in_streak, 2) as avg_points_in_streak
FROM streak_lengths
ORDER BY games_in_streak DESC
LIMIT 10;


-- Alternative approach for Question 2: Using LAG to detect streak breaks
WITH lebron_games AS (
    SELECT 
        gd.game_id,
        g.game_date,
        gd.player_name,
        gd.pts,
        CASE WHEN gd.pts > 10 THEN 1 ELSE 0 END as scored_over_10
    FROM game_details gd
    JOIN games g ON gd.game_id = g.game_id
    WHERE gd.player_name = 'LeBron James'
    ORDER BY g.game_date
),
with_streak_breaks AS (
    SELECT 
        *,
        -- Detect when a streak starts (previous game didn't score > 10, this game does)
        CASE 
            WHEN scored_over_10 = 1 
                AND (LAG(scored_over_10) OVER (ORDER BY game_date) = 0 
                     OR LAG(scored_over_10) OVER (ORDER BY game_date) IS NULL)
            THEN 1 
            ELSE 0 
        END as is_streak_start
    FROM lebron_games
),
with_streak_ids AS (
    SELECT 
        *,
        SUM(is_streak_start) OVER (ORDER BY game_date) as streak_id
    FROM with_streak_breaks
)
SELECT 
    streak_id,
    MIN(game_date) as streak_start,
    MAX(game_date) as streak_end,
    COUNT(*) as consecutive_games_over_10_pts,
    AVG(pts) as avg_points,
    MIN(pts) as min_points,
    MAX(pts) as max_points
FROM with_streak_ids
WHERE scored_over_10 = 1
GROUP BY streak_id
ORDER BY consecutive_games_over_10_pts DESC
LIMIT 10;
