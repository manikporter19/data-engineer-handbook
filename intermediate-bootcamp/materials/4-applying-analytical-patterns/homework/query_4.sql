-- Query 4: Who scored the most points in one season?
-- Uses inline subquery pattern with proper join to games table

SELECT 
    player_name,
    season,
    SUM(pts) as total_points,
    COUNT(DISTINCT game_id) as games_played,
    AVG(pts) as avg_points_per_game
FROM (
    SELECT 
        gd.player_name,
        g.season,
        gd.game_id,
        gd.pts
    FROM game_details gd
    JOIN games g ON gd.game_id = g.game_id
) x
GROUP BY player_name, season
ORDER BY total_points DESC
LIMIT 1;
