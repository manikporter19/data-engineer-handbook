-- Query 5: Which team has won the most games?
-- Uses proper win calculation by comparing team total points per game

WITH team_pts AS (
    SELECT 
        g.game_id,
        gd.team_id,
        gd.team_abbreviation,
        SUM(gd.pts) AS team_pts
    FROM game_details gd
    JOIN games g ON gd.game_id = g.game_id
    GROUP BY g.game_id, gd.team_id, gd.team_abbreviation
),
team_wins AS (
    SELECT 
        a.game_id,
        a.team_id,
        a.team_abbreviation,
        CASE WHEN a.team_pts > b.team_pts THEN 1 ELSE 0 END AS won
    FROM team_pts a
    JOIN team_pts b ON a.game_id = b.game_id AND a.team_id <> b.team_id
)
SELECT 
    team_abbreviation,
    SUM(won) as total_wins
FROM team_wins
GROUP BY team_abbreviation
ORDER BY total_wins DESC
LIMIT 1;
