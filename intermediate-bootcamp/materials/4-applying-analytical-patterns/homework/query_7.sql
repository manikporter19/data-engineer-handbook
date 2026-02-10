-- Query 7: How many games in a row did LeBron James score over 10 points?
-- Uses deterministic ordering (game_date, game_id) and defensive COUNT DISTINCT
-- Implements streak detection with LAG window function

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
