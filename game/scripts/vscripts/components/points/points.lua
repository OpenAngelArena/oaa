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
  self.moduleName = "PointsManager (Score)"

  self.hasGameEnded = false
  self.extend_counter = 0
  self.limitConstant = 16

  local scoreLimit = NORMAL_KILL_LIMIT
  if HeroSelection.is10v10 then
    scoreLimit = TEN_V_TEN_KILL_LIMIT
    self.limitConstant = 10
  elseif HeroSelection.lowPlayerCount then
    scoreLimit = ONE_V_ONE_KILL_LIMIT
    self.limitConstant = 10
  end

  scoreLimit = self.limitConstant + scoreLimit * PlayerResource:SafeGetTeamPlayerCount()

  CustomNetTables:SetTableValue( 'team_scores', 'limit', { value = scoreLimit, name = 'normal' } )

  CustomNetTables:SetTableValue( 'team_scores', 'score', {
    goodguys = 0,
    badguys = 0,
  })

  GameEvents:OnHeroKilled(function (keys)
    local killed = keys.killed
    local killer = keys.killer
    -- increment points
    if not killer or not killed then
      return
    end
    if killer:GetTeam() ~= killed:GetTeam() and not killed:IsReincarnating() and not killed:IsTempestDouble() and not killed:IsSpiritBearOAA() and killed:GetTeam() ~= DOTA_TEAM_NEUTRALS then
      self:AddPoints(killer:GetTeam())
    end
  end)

  GameEvents:OnPlayerAbandon(function (keys)
    -- Reduce the score limit when player abandons but only if game time is after MIN_MATCH_TIME
    if HudTimer and HudTimer:GetGameTime() > MIN_MATCH_TIME then
      PointsManager:RefreshLimit()
    end
  end)

  GameEvents:OnPlayerReconnect(function (keys)
    -- Try to refresh the score limit to the correct value if player reconnected
    Timers:CreateTimer(1, function()
      PointsManager:RefreshLimit()
    end)
  end)

  -- Register chat commands
  ChatCommand:LinkDevCommand("-addpoints", Dynamic_Wrap(PointsManager, "AddPointsCommand"), self)
  ChatCommand:LinkDevCommand("-add_enemy_points", Dynamic_Wrap(PointsManager, "AddEnemyPointsCommand"), self)
  ChatCommand:LinkDevCommand("-kill_limit", Dynamic_Wrap(PointsManager, "SetLimitCommand"), self)

  -- Find fountains
  local fountains = Entities:FindAllByClassname("ent_dota_fountain")
  local radiant_fountain
  local dire_fountain
  for _, entity in pairs(fountains) do
    if entity:GetTeamNumber() == DOTA_TEAM_GOODGUYS then
      radiant_fountain = entity
    elseif entity:GetTeamNumber() == DOTA_TEAM_BADGUYS then
      dire_fountain = entity
    end
  end

  -- Find fountain triggers
  local radiant_fountain_t = Entities:FindByName(nil, "fountain_good_trigger")
  local dire_fountain_t = Entities:FindByName(nil, "fountain_bad_trigger")

  -- Find radiant shrine location(s)
  local radiant_shrine
  if radiant_fountain_t then
    local radiant_fountain_bounds = radiant_fountain_t:GetBounds()
    local radiant_fountain_origin = radiant_fountain_t:GetAbsOrigin()
    radiant_shrine = Vector(radiant_fountain_bounds.Maxs.x + radiant_fountain_origin.x + 400, radiant_fountain_origin.y, 512)
  else
    radiant_shrine = radiant_fountain:GetAbsOrigin() + 400 * Vector(1, 0, 0)
  end

  -- Find dire shrine location(s)
  local dire_shrine
  if dire_fountain_t then
    local dire_fountain_bounds = dire_fountain_t:GetBounds()
    local dire_fountain_origin = dire_fountain_t:GetAbsOrigin()
    dire_shrine = Vector(dire_fountain_bounds.Mins.x + dire_fountain_origin.x - 400, dire_fountain_origin.y, 512)
  else
    dire_shrine = dire_fountain:GetAbsOrigin() - 400 * Vector(1, 0, 0)
  end

  -- Create shrines in front of the fountains
  local coreDude = CreateUnitByName("npc_dota_core_guy", radiant_shrine, true, radiant_fountain, radiant_fountain, DOTA_TEAM_GOODGUYS)
  coreDude = CreateUnitByName("npc_dota_core_guy", dire_shrine, true, dire_fountain, dire_fountain, DOTA_TEAM_BADGUYS)

  -- Store their locations
  PointsManager.radiant_shrine = radiant_shrine
  PointsManager.dire_shrine = dire_shrine
end

function PointsManager:GetState ()
  return {
    limit = self:GetLimit(),
    goodScore = self:GetPoints(DOTA_TEAM_GOODGUYS),
    badScore = self:GetPoints(DOTA_TEAM_BADGUYS),
    extend_counter = self.extend_counter
  }
end

function PointsManager:LoadState (state)
  self:SetLimit(state.limit)
  self:SetPoints(DOTA_TEAM_GOODGUYS, state.goodScore)
  self:SetPoints(DOTA_TEAM_BADGUYS, state.badScore)
  self.extend_counter = state.extend_counter
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
  self.hasGameEnded = true
  Music:FinishMatch(teamID)
  GAME_WINNER_TEAM = teamID
  GAME_TIME_ELAPSED = GameRules:GetDOTATime(false, false)

  Bottlepass:SendWinner(teamID)

  Timers:CreateTimer(2, function()
    GameRules:SetGameWinner(teamID)
    --if teamID == DOTA_TEAM_GOODGUYS then
      --GameRules:SetCustomVictoryMessage("#dota_post_game_radiant_victory")
    --elseif teamID == DOTA_TEAM_BADGUYS then
      --GameRules:SetCustomVictoryMessage("#dota_post_game_dire_victory")
    --end
    GameRules:SetCustomVictoryMessageDuration(POST_GAME_TIME)
  end)
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

function PointsManager:GetLimit()
  return CustomNetTables:GetTableValue('team_scores', 'limit').value
end

function PointsManager:SetLimit(killLimit)
  CustomNetTables:SetTableValue('team_scores', 'limit', {value = killLimit})
  LimitChangedEvent.broadcast(true)
end

function PointsManager:IncreaseLimit(limit_increase)
  local extend_amount = 0
  local player_count = PlayerResource:SafeGetTeamPlayerCount()
  local standard_extend_amount = player_count * KILL_LIMIT_INCREASE
  if HeroSelection.is10v10 then
    standard_extend_amount = player_count * TEN_V_TEN_LIMIT_INCREASE
  elseif HeroSelection.lowPlayerCount then
    standard_extend_amount = player_count * ONE_V_ONE_LIMIT_INCREASE
  end
  if not limit_increase then
    extend_amount = standard_extend_amount
  elseif type(limit_increase) == "number" then
    extend_amount = limit_increase
  elseif limit_increase == "grendel" then
    extend_amount = standard_extend_amount//2
  else
    print("limit_increase argument must be a number or 'grendel' string! When ommited it will use the standard value.")
  end

  self.extend_counter = self.extend_counter + extend_amount/standard_extend_amount

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

function PointsManager:RefreshLimit()
  -- Current limit:
  local limit = self:GetLimit()
  local maxPoints = math.max(self:GetPoints(DOTA_TEAM_GOODGUYS), self:GetPoints(DOTA_TEAM_BADGUYS))
  local base_limit = NORMAL_KILL_LIMIT
  local current_player_count = PlayerResource:SafeGetTeamPlayerCount()
  local extend_amount = KILL_LIMIT_INCREASE * current_player_count
  if HeroSelection.is10v10 then
    base_limit = TEN_V_TEN_KILL_LIMIT
    extend_amount = TEN_V_TEN_LIMIT_INCREASE * current_player_count
  elseif HeroSelection.lowPlayerCount then
    base_limit = ONE_V_ONE_KILL_LIMIT
    extend_amount = ONE_V_ONE_LIMIT_INCREASE * current_player_count
  end
  -- Expected score limit with changed number of players connected:
  -- Expected behavior: Disconnects should reduce player_count and reconnects should increase player_count.
  local newLimit = self.limitConstant + base_limit * current_player_count + math.floor(self.extend_counter * extend_amount)
  if newLimit < limit then
    local limitChange = limit - newLimit -- this used to be constant 10 and not dependent on number of players
    newLimit = math.min(limit, math.max(maxPoints + limitChange, limit - limitChange))
  end

  self:SetLimit(newLimit)
end
