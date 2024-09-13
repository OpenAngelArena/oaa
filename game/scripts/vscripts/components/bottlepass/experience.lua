
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
        damage_taken = PlayerResource:GetHeroDamageTaken(k, true),
        healing = PlayerResource:GetHealing(k),
      }
    else
      playerStats[k] = {
        damage_dealt = 0,
        damage_taken = 0,
        healing = 0,
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
