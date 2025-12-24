-- Query to deduplicate nba_game_details from Day 1
-- Uses ROW_NUMBER with deterministic ordering to keep the most recent record
-- If no timestamp columns exist, this uses a stable tie-breaker approach

WITH deduped AS (
    SELECT *,
           ROW_NUMBER() OVER (
               PARTITION BY game_id, team_id, player_id 
               -- Order by a deterministic column for consistent deduplication
               -- If updated_at/created_at exist, use: ORDER BY updated_at DESC NULLS LAST, created_at DESC NULLS LAST
               -- Otherwise, use a stable surrogate like pts DESC, player_name to ensure determinism
               ORDER BY pts DESC NULLS LAST, player_name
           ) as row_num
    FROM nba_game_details
)
SELECT 
    game_id,
    team_id,
    team_abbreviation,
    team_city,
    player_id,
    player_name,
    nickname,
    start_position,
    comment,
    min,
    fgm,
    fga,
    fg_pct,
    fg3m,
    fg3a,
    fg3_pct,
    ftm,
    fta,
    ft_pct,
    oreb,
    dreb,
    reb,
    ast,
    stl,
    blk,
    "TO",
    pf,
    pts,
    plus_minus
FROM deduped
WHERE row_num = 1;
