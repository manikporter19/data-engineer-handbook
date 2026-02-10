-- Query 6: What is the most games a team has won in a 90 game stretch?
-- Uses proper win calculation by comparing team total points per game
-- Implements rolling window with ROW_NUMBER for precise 90-game windows

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
