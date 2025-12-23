-- State Change Tracking for Players
-- Tracks player status changes: New, Retired, Continued Playing, Returned from Retirement, Stayed Retired

WITH last_season AS (
    SELECT 
        player_name,
        current_season,
        is_active
    FROM players
    WHERE current_season = 2020  -- Replace with year - 1
),
this_season AS (
    SELECT 
        player_name,
        current_season,
        is_active
    FROM players
    WHERE current_season = 2021  -- Replace with current year
),
combined AS (
    SELECT 
        COALESCE(ts.player_name, ls.player_name) as player_name,
        COALESCE(ts.current_season, ls.current_season + 1) as current_season,
        ls.is_active as was_active_last_season,
        ts.is_active as is_active_this_season
    FROM last_season ls
    FULL OUTER JOIN this_season ts
        ON ls.player_name = ts.player_name
)
SELECT 
    player_name,
    current_season,
    CASE 
        -- New: player was not in league last season but is active this season
        WHEN was_active_last_season IS NULL AND is_active_this_season = TRUE 
            THEN 'New'
        
        -- Retired: player was active last season but not active this season
        WHEN was_active_last_season = TRUE AND is_active_this_season = FALSE 
            THEN 'Retired'
        
        -- Continued Playing: player was active last season and is still active this season
        WHEN was_active_last_season = TRUE AND is_active_this_season = TRUE 
            THEN 'Continued Playing'
        
        -- Returned from Retirement: player was not active last season but is active this season
        WHEN was_active_last_season = FALSE AND is_active_this_season = TRUE 
            THEN 'Returned from Retirement'
        
        -- Stayed Retired: player was not active last season and still not active this season
        WHEN was_active_last_season = FALSE AND is_active_this_season = FALSE 
            THEN 'Stayed Retired'
        
        -- No longer tracked: player was in league last season but no record this season
        WHEN was_active_last_season IS NOT NULL AND is_active_this_season IS NULL 
            THEN 'No Longer Tracked'
        
        ELSE 'Unknown'
    END as player_status,
    was_active_last_season,
    is_active_this_season
FROM combined
ORDER BY player_name;

-- Summary statistics of state changes
SELECT 
    CASE 
        WHEN was_active_last_season IS NULL AND is_active_this_season = TRUE THEN 'New'
        WHEN was_active_last_season = TRUE AND is_active_this_season = FALSE THEN 'Retired'
        WHEN was_active_last_season = TRUE AND is_active_this_season = TRUE THEN 'Continued Playing'
        WHEN was_active_last_season = FALSE AND is_active_this_season = TRUE THEN 'Returned from Retirement'
        WHEN was_active_last_season = FALSE AND is_active_this_season = FALSE THEN 'Stayed Retired'
        WHEN was_active_last_season IS NOT NULL AND is_active_this_season IS NULL THEN 'No Longer Tracked'
        ELSE 'Unknown'
    END as player_status,
    COUNT(*) as player_count
FROM combined
GROUP BY 
    CASE 
        WHEN was_active_last_season IS NULL AND is_active_this_season = TRUE THEN 'New'
        WHEN was_active_last_season = TRUE AND is_active_this_season = FALSE THEN 'Retired'
        WHEN was_active_last_season = TRUE AND is_active_this_season = TRUE THEN 'Continued Playing'
        WHEN was_active_last_season = FALSE AND is_active_this_season = TRUE THEN 'Returned from Retirement'
        WHEN was_active_last_season = FALSE AND is_active_this_season = FALSE THEN 'Stayed Retired'
        WHEN was_active_last_season IS NOT NULL AND is_active_this_season IS NULL THEN 'No Longer Tracked'
        ELSE 'Unknown'
    END
ORDER BY player_count DESC;
