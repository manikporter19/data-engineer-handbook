-- GROUPING SETS query for efficient aggregations of game_details data
-- Aggregates along multiple dimensions: player+team, player+season, and team

WITH game_details_augmented AS (
    SELECT 
        gd.player_id,
        gd.player_name,
        gd.team_id,
        gd.team_abbreviation,
        g.season,
        gd.pts,
        gd.reb,
        gd.ast,
        CASE WHEN gd.pts > 0 THEN 1 ELSE 0 END as games_played
    FROM game_details gd
    JOIN games g ON gd.game_id = g.game_id
)
SELECT 
    -- Identify which aggregation level this row represents
    CASE 
        WHEN GROUPING(player_name, team_abbreviation) = 0 AND GROUPING(season) = 1 
            THEN 'player_and_team'
        WHEN GROUPING(player_name, season) = 0 AND GROUPING(team_abbreviation) = 1 
            THEN 'player_and_season'
        WHEN GROUPING(team_abbreviation) = 0 AND GROUPING(player_name, season) = 3 
            THEN 'team_only'
        ELSE 'other'
    END as aggregation_level,
    
    COALESCE(player_name, '(all players)') as player_name,
    COALESCE(team_abbreviation, '(all teams)') as team_abbreviation,
    COALESCE(CAST(season AS TEXT), '(all seasons)') as season,
    
    -- Aggregated metrics
    SUM(pts) as total_points,
    SUM(reb) as total_rebounds,
    SUM(ast) as total_assists,
    SUM(games_played) as games_played,
    AVG(pts) as avg_points_per_game,
    AVG(reb) as avg_rebounds_per_game,
    AVG(ast) as avg_assists_per_game

FROM game_details_augmented

GROUP BY GROUPING SETS (
    -- Player and Team: Who scored the most points playing for one team?
    (player_name, team_abbreviation),
    
    -- Player and Season: Who scored the most points in one season?
    (player_name, season),
    
    -- Team only: Which team has won the most games?
    (team_abbreviation)
)

ORDER BY 
    aggregation_level,
    total_points DESC;


-- Specific queries to answer each question:

-- Question 1: Who scored the most points playing for one team?
SELECT 
    player_name,
    team_abbreviation,
    SUM(pts) as total_points,
    SUM(CASE WHEN pts > 0 THEN 1 ELSE 0 END) as games_played,
    AVG(pts) as avg_points_per_game
FROM game_details_augmented
GROUP BY player_name, team_abbreviation
ORDER BY total_points DESC
LIMIT 20;


-- Question 2: Who scored the most points in one season?
SELECT 
    player_name,
    season,
    SUM(pts) as total_points,
    SUM(CASE WHEN pts > 0 THEN 1 ELSE 0 END) as games_played,
    AVG(pts) as avg_points_per_game
FROM game_details_augmented
GROUP BY player_name, season
ORDER BY total_points DESC
LIMIT 20;


-- Question 3: Which team has the best overall performance?
-- Note: To answer "which team has won the most games", we need game outcomes
-- This query shows team performance metrics instead
SELECT 
    team_abbreviation,
    SUM(pts) as total_points,
    SUM(reb) as total_rebounds,
    SUM(ast) as total_assists,
    COUNT(DISTINCT player_id) as unique_players,
    SUM(CASE WHEN pts > 0 THEN 1 ELSE 0 END) as total_games,
    AVG(pts) as avg_points_per_game
FROM game_details_augmented
GROUP BY team_abbreviation
ORDER BY total_points DESC
LIMIT 20;
