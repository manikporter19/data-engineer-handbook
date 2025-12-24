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
-- Uses deterministic ordering (game_date, game_id) and defensive COUNT DISTINCT
WITH lebron AS (
    SELECT 
        gd.game_id,
        g.game_date,
        CASE WHEN gd.pts > 10 THEN 1 ELSE 0 END as gt10,
        gd.pts
    FROM game_details gd
    JOIN games g ON g.game_id = gd.game_id
    WHERE gd.player_name = 'LeBron James'
),
with_starts AS (
    SELECT 
        *,
        CASE 
            WHEN gt10 = 1 
                AND COALESCE(LAG(gt10) OVER (ORDER BY game_date, game_id), 0) = 0 
            THEN 1 
            ELSE 0 
        END as is_start
    FROM lebron
),
with_groups AS (
    SELECT 
        *,
        SUM(is_start) OVER (ORDER BY game_date, game_id) as grp
    FROM with_starts
)
SELECT 
    grp,
    MIN(game_date) as streak_start,
    MAX(game_date) as streak_end,
    COUNT(DISTINCT game_id) as consecutive_games_over_10_pts,
    AVG(pts) as avg_points
FROM with_groups
WHERE gt10 = 1
GROUP BY grp
ORDER BY consecutive_games_over_10_pts DESC
LIMIT 1;
