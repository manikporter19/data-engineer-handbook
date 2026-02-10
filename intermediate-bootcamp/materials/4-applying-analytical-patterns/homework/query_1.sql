-- State Change Tracking for Players
-- Tracks player status changes across all seasons: New, Retired, Continued Playing, Returned from Retirement, Stayed Retired
-- This query builds per-player, per-season activity from actual game data rather than relying on a players table

WITH seasons AS (
    -- Extract all distinct seasons from the games table
    SELECT DISTINCT season 
    FROM games
    ORDER BY season
),
roster AS (
    -- Build a complete roster of all players across all seasons with activity flag
    -- A player is "active" in a season if they played in any game that season
    SELECT 
        p.player_id,
        p.player_name,
        s.season,
        CASE 
            WHEN EXISTS (
                SELECT 1 
                FROM game_details gd
                JOIN games g ON g.game_id = gd.game_id
                WHERE gd.player_id = p.player_id 
                AND g.season = s.season
            ) THEN 1 
            ELSE 0 
        END as active
    FROM players p
    CROSS JOIN seasons s
),
with_lags AS (
    -- Use window functions to compare current season with previous season and all prior seasons
    SELECT 
        player_id,
        player_name,
        season,
        active,
        -- Previous season's activity status
        LAG(active) OVER (PARTITION BY player_id ORDER BY season) as prev_active,
        -- Whether player was ever active in any season BEFORE the current one
        -- This helps distinguish "New" (first-ever activation) from "Returned from Retirement"
        MAX(active) OVER (
            PARTITION BY player_id 
            ORDER BY season 
            ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING
        ) as any_prior_active
    FROM roster
)
SELECT 
    player_id,
    player_name,
    season,
    active as is_active_this_season,
    prev_active as was_active_last_season,
    CASE 
        -- New: First time ever active (no prior activity, no previous season, currently active)
        WHEN prev_active IS NULL AND active = 1 THEN 'New'
        
        -- Retired: Was active last season, not active this season
        WHEN prev_active = 1 AND active = 0 THEN 'Retired'
        
        -- Continued Playing: Was active last season, still active this season
        WHEN prev_active = 1 AND active = 1 THEN 'Continued Playing'
        
        -- Returned from Retirement: Was active in some prior season, not active last season, active this season
        WHEN prev_active = 0 AND active = 1 AND any_prior_active = 1 THEN 'Returned from Retirement'
        
        -- Stayed Retired: Not active last season, not active this season, but was active in some prior season
        WHEN prev_active = 0 AND active = 0 AND any_prior_active = 1 THEN 'Stayed Retired'
        
        -- Players with no activity yet (season before their debut) - filter these out or handle as needed
        WHEN prev_active IS NULL AND active = 0 THEN NULL
        
        ELSE NULL
    END as player_status
FROM with_lags
WHERE 
    -- Filter out seasons before player's first appearance where they have no status
    (prev_active IS NOT NULL OR active = 1)
ORDER BY player_name, season;

-- Summary statistics of state changes by season
SELECT 
    season,
    CASE 
        WHEN prev_active IS NULL AND active = 1 THEN 'New'
        WHEN prev_active = 1 AND active = 0 THEN 'Retired'
        WHEN prev_active = 1 AND active = 1 THEN 'Continued Playing'
        WHEN prev_active = 0 AND active = 1 AND any_prior_active = 1 THEN 'Returned from Retirement'
        WHEN prev_active = 0 AND active = 0 AND any_prior_active = 1 THEN 'Stayed Retired'
    END as player_status,
    COUNT(*) as player_count
FROM with_lags
WHERE 
    -- Only count valid status transitions
    (prev_active IS NOT NULL OR active = 1)
    AND CASE 
        WHEN prev_active IS NULL AND active = 1 THEN 'New'
        WHEN prev_active = 1 AND active = 0 THEN 'Retired'
        WHEN prev_active = 1 AND active = 1 THEN 'Continued Playing'
        WHEN prev_active = 0 AND active = 1 AND any_prior_active = 1 THEN 'Returned from Retirement'
        WHEN prev_active = 0 AND active = 0 AND any_prior_active = 1 THEN 'Stayed Retired'
    END IS NOT NULL
GROUP BY season, player_status
ORDER BY season, player_count DESC;
