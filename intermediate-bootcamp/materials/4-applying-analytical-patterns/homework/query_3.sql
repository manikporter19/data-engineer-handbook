-- Query 3: Who scored the most points playing for one team?
-- Uses inline subquery pattern with proper join to games table

SELECT 
    player_name,
    team_abbreviation,
    SUM(pts) as total_points,
    COUNT(DISTINCT game_id) as games_played,
    AVG(pts) as avg_points_per_game
FROM (
    SELECT 
        gd.player_name,
        gd.team_abbreviation,
        gd.game_id,
        gd.pts,
        g.season
    FROM game_details gd
    JOIN games g ON gd.game_id = g.game_id
) x
GROUP BY player_name, team_abbreviation
ORDER BY total_points DESC
LIMIT 1;
