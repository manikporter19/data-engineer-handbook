-- GROUPING SETS query for efficient aggregations of game_details data
-- Aggregates along multiple dimensions: player+team, player+season, and team
-- Uses proper GROUPING() syntax and includes team wins calculation

WITH base AS (
    SELECT 
        gd.player_id,
        gd.player_name,
        gd.team_id,
        gd.team_abbreviation,
        g.season,
        gd.game_id,
        gd.pts,
        gd.reb,
        gd.ast
    FROM game_details gd
    JOIN games g ON gd.game_id = g.game_id
),
-- Calculate team total points per game
team_pts AS (
    SELECT 
        g.game_id,
        gd.team_id,
        gd.team_abbreviation,
        SUM(gd.pts) AS team_pts
    FROM game_details gd
    JOIN games g ON gd.game_id = g.game_id
    GROUP BY g.game_id, gd.team_id, gd.team_abbreviation
),
-- Calculate wins: team with more points wins
team_wins AS (
    SELECT 
        a.game_id,
        a.team_id,
        a.team_abbreviation,
        CASE WHEN a.team_pts > b.team_pts THEN 1 ELSE 0 END AS won
    FROM team_pts a
    JOIN team_pts b ON a.game_id = b.game_id AND a.team_id <> b.team_id
),
-- Augment base with wins
base_with_wins AS (
    SELECT 
        b.*,
        COALESCE(tw.won, 0) AS won
    FROM base b
    LEFT JOIN team_wins tw ON b.game_id = tw.game_id AND b.team_id = tw.team_id
)
SELECT 
    -- Identify which aggregation level this row represents
    -- Use individual GROUPING() calls for proper SQL compatibility
    CASE 
        WHEN GROUPING(player_name) = 0 AND GROUPING(team_abbreviation) = 0 AND GROUPING(season) = 1 
            THEN 'player_and_team'
        WHEN GROUPING(player_name) = 0 AND GROUPING(season) = 0 AND GROUPING(team_abbreviation) = 1 
            THEN 'player_and_season'
        WHEN GROUPING(team_abbreviation) = 0 AND GROUPING(player_name) = 1 AND GROUPING(season) = 1 
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
    COUNT(DISTINCT game_id) as games_played,
    AVG(pts) as avg_points_per_game,
    AVG(reb) as avg_rebounds_per_game,
    AVG(ast) as avg_assists_per_game,
    SUM(won) as wins

FROM base_with_wins

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
WITH base AS (
    SELECT 
        gd.player_name,
        gd.team_abbreviation,
        gd.game_id,
        gd.pts
    FROM game_details gd
    JOIN games g ON gd.game_id = g.game_id
)
SELECT 
    player_name,
    team_abbreviation,
    SUM(pts) as total_points,
    COUNT(DISTINCT game_id) as games_played,
    AVG(pts) as avg_points_per_game
FROM base
GROUP BY player_name, team_abbreviation
ORDER BY total_points DESC
LIMIT 20;


-- Question 2: Who scored the most points in one season?
WITH base AS (
    SELECT 
        gd.player_name,
        g.season,
        gd.game_id,
        gd.pts
    FROM game_details gd
    JOIN games g ON gd.game_id = g.game_id
)
SELECT 
    player_name,
    season,
    SUM(pts) as total_points,
    COUNT(DISTINCT game_id) as games_played,
    AVG(pts) as avg_points_per_game
FROM base
GROUP BY player_name, season
ORDER BY total_points DESC
LIMIT 20;


-- Question 3: Which team has won the most games?
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
    SUM(won) as total_wins,
    COUNT(DISTINCT game_id) as total_games,
    ROUND(100.0 * SUM(won) / COUNT(DISTINCT game_id), 2) as win_percentage
FROM team_wins
GROUP BY team_abbreviation
ORDER BY total_wins DESC
LIMIT 20;
