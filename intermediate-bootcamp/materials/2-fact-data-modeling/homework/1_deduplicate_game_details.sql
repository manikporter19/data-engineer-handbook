-- Query to deduplicate game_details from Day 1
-- Uses ROW_NUMBER to identify and keep only the first occurrence of each duplicate

WITH deduped AS (
    SELECT *,
           ROW_NUMBER() OVER (
               PARTITION BY game_id, team_id, player_id 
               ORDER BY game_id
           ) as row_num
    FROM game_details
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
