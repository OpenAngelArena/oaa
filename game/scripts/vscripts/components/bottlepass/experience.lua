
if Bottlepass == nil then Bottlepass = Bottlepass or class({}) end

function Bottlepass:SendEndGameStats()
  local xpInfo = {}
  local playerStats = {}

  local players = {}
  PlayerResource:GetAllTeamPlayerIDs():each(function(id)
    players[id] = PlayerResource:GetPlayer(id)
  end)

  for k, v in pairs(players) do
    -- local level = Bottlepass:GetXPLevelByXp(v.xp)
    -- local title = Bottlepass:GetTitleIXP(level)
    -- local color = Bottlepass:GetTitleColorIXP(title, true)
    -- local progress = Bottlepass:GetXpProgressToNextLevel(v.xp)

    -- PLACEHOLDERS: testing purpose, remove once the above are added
    local level = 7
    local title = "Warrior"
    local color = "#4C8BCA"
    -- diff between current xp and max xp of current level between 0 and 1, for the progress bar
    local progress = 0.7
    -- END OF PLACEHOLDERS

    if level and title and color and progress then
      xpInfo[k] = {
        level = level,
        title = title,
        color = color,
        progress = progress
      }
    end
  end

  for k = 0, DOTA_MAX_TEAM_PLAYERS - 1 do
    if PlayerResource:IsValidPlayerID(k) and not PlayerResource:IsBlackBoxPlayer(k) then
      playerStats[k] = {
        damage_dealt = PlayerResource:GetRawPlayerDamage(k),
        damage_dealt_to_bosses = 0,
        --damage_dealt_to_summons = 0, -- interesting against Spirit Bear and similar, otherwise redundant
        damage_taken = PlayerResource:GetHeroDamageTaken(k, true),
        damage_taken_from_bosses = 0, -- PlayerResource:GetTowerDamageTaken(k, true),
        --damage_taken_from_creeps = PlayerResource:GetCreepDamageTaken(k, true), -- interesting for single player, otherwise redundant
        healing = PlayerResource:GetHealing(k),
        gpm = math.floor(PlayerResource:GetGoldPerMin(k)+0.5),
        xpm = math.floor(PlayerResource:GetXPPerMin(k)+0.5),
      }
      -- Get correct stats if the module and the table exist
      if StatTracker and StatTracker.stats and StatTracker.stats[k] then
        local tracked_stats = StatTracker.stats[k]
        playerStats[k].damage_dealt = math.ceil(tracked_stats.damage_dealt_to_heroes)
        playerStats[k].damage_dealt_to_bosses = = math.ceil(tracked_stats.damage_dealt_to_bosses)
        --playerStats[k].damage_dealt_to_summons = = math.ceil(tracked_stats.damage_dealt_to_player_creeps)
        playerStats[k].damage_taken = math.ceil(tracked_stats.damage_taken_from_players)
        playerStats[k].damage_taken_from_bosses = math.ceil(tracked_stats.damage_taken_from_bosses)
        --playerStats[k].damage_taken_from_creeps = math.ceil(tracked_stats.damage_taken_from_neutral_creeps
      end
    else
      playerStats[k] = {
        damage_dealt = 0,
        damage_dealt_to_bosses = 0,
        --damage_dealt_to_summons = 0,
        damage_taken = 0,
        damage_taken_from_bosses = 0,
        --damage_taken_from_creeps = 0,
        healing = 0,
        gpm = 0,
        xpm = 0,
      }
    end
  end

  CustomNetTables:SetTableValue("end_game_scoreboard", "game_info", {
    players = Bottlepass.mmrDiffs,
    xp_info = xpInfo,
    stats = playerStats,
    info = {
      winner = GAME_WINNER_TEAM,
      radiant_score = PointsManager:GetPoints(DOTA_TEAM_GOODGUYS),
      dire_score = PointsManager:GetPoints(DOTA_TEAM_BADGUYS),
    }
  })
end
