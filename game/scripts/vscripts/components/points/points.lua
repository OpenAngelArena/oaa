-- Taken from bb template
if PointsManager == nil then
  Debug.EnabledModules['points:*'] = false

  DebugPrint ( 'Creating new PointsManager object.' )
  PointsManager = class({})
end

function PointsManager:Init ()
  DebugPrint ( 'Initializing.' )

  self.hasGameEnded = false

  CustomNetTables:SetTableValue( 'team_scores', 'score', {
    goodguys = 0,
    badguys = 0,
  })

  GameEvents:OnHeroKilled(function (keys)
    -- increment points
    if keys.killer:GetTeam() ~= keys.killed:GetTeam() and not keys.killed:IsReincarnating() and keys.killed:GetTeam() ~= DOTA_TEAM_NEUTRALS then
      self:AddPoints(keys.killer:GetTeam())
    end
  end)

  -- Register chat commands
  ChatCommand:LinkCommand("-addpoints", Dynamic_Wrap(PointsManager, "AddPointsCommand"), self)
  ChatCommand:LinkCommand("-kill_limit", Dynamic_Wrap(PointsManager, "SetLimitCommand"), self)
end

function PointsManager:CheckWinCondition(teamID, points)
  if self.hasGameEnded then
    return
  end

  local limit = CustomNetTables:GetTableValue('team_scores', 'limit').value

  if points >= limit then
    Timers:CreateTimer(1, function()
      GAME_WINNER_TEAM = teamID
      GAME_TIME_ELAPSED = GameRules:GetDOTATime(false, false)
      GameRules:SetGameWinner(teamID)
    end)
    self.hasGameEnded = true
  end
end

function PointsManager:SetPoints(teamID, amount)
  local score = CustomNetTables:GetTableValue('team_scores', 'score')

  if teamID == DOTA_TEAM_GOODGUYS then
    score.goodguys = amount
  elseif teamID == DOTA_TEAM_BADGUYS then
    score.badguys = amount
  end

  CustomNetTables:SetTableValue('team_scores', 'score', score)
  self:CheckWinCondition(teamID, amount)
end

function PointsManager:AddPoints(teamID, amount)
  amount = amount or 1

  local score = CustomNetTables:GetTableValue('team_scores', 'score')

  if teamID == DOTA_TEAM_GOODGUYS then
    score.goodguys = score.goodguys + amount
    amount = score.goodguys
  elseif teamID == DOTA_TEAM_BADGUYS then
    score.badguys = score.badguys + amount
    amount = score.badguys
  end

  CustomNetTables:SetTableValue('team_scores', 'score', score)
  self:CheckWinCondition(teamID, amount)
end

function PointsManager:GetPoints(teamID)
  local score = CustomNetTables:GetTableValue('team_scores', 'score')

  if teamID == DOTA_TEAM_GOODGUYS then
    return score.goodguys
  elseif teamID == DOTA_TEAM_BADGUYS then
    return score.badguys
  end
end

function PointsManager:GetLimit()
  return CustomNetTables:GetTableValue('team_scores', 'limit').value
end

function PointsManager:SetLimit(killLimit)
  CustomNetTables:SetTableValue('team_scores', 'limit', {value = killLimit})
end

function PointsManager:AddPointsCommand(keys)
  local text = string.lower(keys.text)
  local splitted = split(text, " ")
  local hero = PlayerResource:GetSelectedHeroEntity(keys.playerid)
  local teamID = hero:GetTeamNumber()
  local pointsToAdd = tonumber(splitted[2]) or 1
  self:AddPoints(teamID, pointsToAdd)
end

function PointsManager:SetLimitCommand(keys)
  local text = string.lower(keys.text)
  local splitted = split(text, " ")
  if splitted[2] and tonumber(splitted[2]) then
    self:SetLimit(tonumber(splitted[2]))
  else
    GameRules:SendCustomMessage("Usage is -kill_limit X, where X is the kill limit to set", 0, 0)
  end
end
