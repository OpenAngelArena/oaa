
if Bottlepass == nil then Bottlepass = Bottlepass or class({}) end

function Bottlepass:SendEndGameStats()
  local xpInfo = {}

  local players = {}
  for i = 0, PlayerResource:GetPlayerCount() - 1 do
    players[i] = PlayerResource:GetPlayer(i)
  end

  for k, v in pairs(players) do
--    local level = Bottlepass:GetXPLevelByXp(v.xp)
--    local title = Bottlepass:GetTitleIXP(level)
--    local color = Bottlepass:GetTitleColorIXP(title, true)
--    local progress = Bottlepass:GetXpProgressToNextLevel(v.xp)

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

  CustomNetTables:SetTableValue("end_game_scoreboard", "game_info", {
    players = Bottlepass.mmrDiffs,
    xp_info = xpInfo,
    info = {
      winner = GAME_WINNER_TEAM,
      radiant_score = PointsManager:GetPoints(DOTA_TEAM_GOODGUYS),
      dire_score = PointsManager:GetPoints(DOTA_TEAM_BADGUYS),
    }
  })
end
