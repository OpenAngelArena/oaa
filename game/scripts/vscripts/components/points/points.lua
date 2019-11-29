-- Taken from bb template
if PointsManager == nil then
  Debug.EnabledModules['points:*'] = false

  DebugPrint ( 'Creating new PointsManager object.' )
  PointsManager = class({})
end

local WinnerEvent = Event()
local ScoreChangedEvent = Event()
local LimitChangedEvent = Event()
PointsManager.onWinner = WinnerEvent.listen
PointsManager.onScoreChanged = ScoreChangedEvent.listen
PointsManager.onLimitChanged = LimitChangedEvent.listen

function PointsManager:Init ()
  DebugPrint ( 'Initializing.' )

  self.hasGameEnded = false

  local scoreLimit = NORMAL_KILL_LIMIT
  if HeroSelection.is10v10 then
    scoreLimit = TEN_V_TEN_KILL_LIMIT
  end
  CustomNetTables:SetTableValue( 'team_scores', 'limit', { value = scoreLimit, name = 'normal' } )

  CustomNetTables:SetTableValue( 'team_scores', 'score', {
    goodguys = 0,
    badguys = 0,
  })

  GameEvents:OnHeroKilled(function (keys)
    -- increment points
    if not keys.killer or not keys.killed then
      return
    end
    if keys.killer:GetTeam() ~= keys.killed:GetTeam() and not keys.killed:IsReincarnating() and keys.killed:GetTeam() ~= DOTA_TEAM_NEUTRALS then
      self:AddPoints(keys.killer:GetTeam())
    end
  end)

  GameEvents:OnPlayerAbandon(function (keys)
    local limit = self:GetLimit()
    local maxPoints = math.max(self:GetPoints(DOTA_TEAM_GOODGUYS), self:GetPoints(DOTA_TEAM_BADGUYS))
    limit = math.min(limit, math.max(maxPoints + 10, limit - 10))

    self:SetLimit(limit)
  end)

  -- Register chat commands
  ChatCommand:LinkDevCommand("-addpoints", Dynamic_Wrap(PointsManager, "AddPointsCommand"), self)
  ChatCommand:LinkDevCommand("-add_enemy_points", Dynamic_Wrap(PointsManager, "AddEnemyPointsCommand"), self)
  ChatCommand:LinkDevCommand("-kill_limit", Dynamic_Wrap(PointsManager, "SetLimitCommand"), self)
  ChatCommand:LinkDevCommand("-kill_limit", Dynamic_Wrap(PointsManager, "SetLimitCommand"), self)

  local position = Vector(-5200, 200, 512)
  local coreDude = CreateUnitByName("npc_dota_core_guy", position, true, nil, nil, DOTA_TEAM_GOODGUYS)
  position = Vector(-5200, -200, 512)
  coreDude = CreateUnitByName("npc_dota_core_guy_2", position, true, nil, nil, DOTA_TEAM_GOODGUYS)

  -- PlayerResource:GetPlayerIDsForTeam(DOTA_TEAM_GOODGUYS):each(function (playerID)
  --   coreDude:SetControllableByPlayer(playerID, false)
  -- end)

  position = Vector(5200, 200, 512)
  coreDude = CreateUnitByName("npc_dota_core_guy_2", position, true, nil, nil, DOTA_TEAM_BADGUYS)
  position = Vector(5200, -200, 512)
  coreDude = CreateUnitByName("npc_dota_core_guy", position, true, nil, nil, DOTA_TEAM_BADGUYS)
  -- PlayerResource:GetPlayerIDsForTeam(DOTA_TEAM_BADGUYS):each(function (playerID)
  --   coreDude:SetControllableByPlayer(playerID, false)
  -- end)
end

function PointsManager:GetState ()
  return {
    limit = self:GetLimit(),
    goodScore = self:GetPoints(DOTA_TEAM_GOODGUYS),
    badScore = self:GetPoints(DOTA_TEAM_BADGUYS)
  }
end

function PointsManager:LoadState (state)
  self:SetLimit(state.limit)
  self:SetPoints(DOTA_TEAM_GOODGUYS, state.goodScore)
  self:SetPoints(DOTA_TEAM_BADGUYS, state.badScore)
end

function PointsManager:CheckWinCondition(teamID, points)
  if self.hasGameEnded then
    return
  end

  local limit = CustomNetTables:GetTableValue('team_scores', 'limit').value

  if points >= limit then
    WinnerEvent.broadcast(teamID)
  end
end

function PointsManager:SetWinner(teamID)
  -- actually need to implement lose win logic for teams
  Music:FinishMatch(teamID)
  GAME_WINNER_TEAM = teamID
  Bottlepass:SendWinner(teamID)

  GAME_TIME_ELAPSED = GameRules:GetDOTATime(false, false)
  GameRules:SetGameWinner(teamID)
  self.hasGameEnded = true
end

function PointsManager:SetPoints(teamID, amount)
  local score = CustomNetTables:GetTableValue('team_scores', 'score')

  if teamID == DOTA_TEAM_GOODGUYS then
    score.goodguys = amount
  elseif teamID == DOTA_TEAM_BADGUYS then
    score.badguys = amount
  end

  CustomNetTables:SetTableValue('team_scores', 'score', score)
  ScoreChangedEvent.broadcast()
  self:CheckWinCondition(teamID, amount)
end

function PointsManager:AddPoints(teamID, amount)
  amount = amount or 1
  local score = CustomNetTables:GetTableValue('team_scores', 'score')

  if teamID == DOTA_TEAM_GOODGUYS then
    amount = score.goodguys + amount
  elseif teamID == DOTA_TEAM_BADGUYS then
    amount = score.badguys + amount
  end

  PointsManager:SetPoints(teamID, amount)
end

function PointsManager:GetPoints(teamID)
  local score = CustomNetTables:GetTableValue('team_scores', 'score')

  if not score then
    return 0
  end

  if teamID == DOTA_TEAM_GOODGUYS then
    return score.goodguys
  elseif teamID == DOTA_TEAM_BADGUYS then
    return score.badguys
  end
end

function PointsManager:GetGameLength()
  return CustomNetTables:GetTableValue('team_scores', 'limit').name
end

function PointsManager:GetLimit()
  return CustomNetTables:GetTableValue('team_scores', 'limit').value
end

function PointsManager:SetLimit(killLimit)
  CustomNetTables:SetTableValue('team_scores', 'limit', {value = killLimit, name = self:GetGameLength() })
  LimitChangedEvent.broadcast(true)
end

function PointsManager:IncreaseLimit(extend_amount)
  PointsManager:SetLimit(PointsManager:GetLimit() + extend_amount)
  Notifications:TopToAll({text="#duel_final_duel_objective_extended", duration=5.0, replacement_map={extend_amount=extend_amount}})
end

function PointsManager:AddEnemyPointsCommand(keys)
  local text = string.lower(keys.text)
  local splitted = split(text, " ")
  local hero = PlayerResource:GetSelectedHeroEntity(keys.playerid)
  local teamID = hero:GetTeamNumber()
  if hero:GetTeamNumber() == DOTA_TEAM_GOODGUYS then
    teamID = DOTA_TEAM_BADGUYS
  else
    teamID = DOTA_TEAM_GOODGUYS
  end
  local pointsToAdd = tonumber(splitted[2]) or 1
  self:AddPoints(teamID, pointsToAdd)
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
