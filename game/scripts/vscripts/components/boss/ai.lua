LinkLuaModifier("modifier_boss_capture_point", "modifiers/modifier_boss_capture_point.lua", LUA_MODIFIER_MOTION_NONE)

-- Taken from bb template
if BossAI == nil then
  DebugPrint ( 'creating new BossAI object' )
  BossAI = class({})
  BossAI.hasFarmingCore = {}
  BossAI.hasSecondBoss = {}

  Debug.EnabledModules['boss:ai'] = false

  CustomNetTables:SetTableValue("stat_display_team", "BK", { value = {} })
end

BossAI.IDLE = 1
BossAI.AGRO = 2
BossAI.LEASHING = 3
BossAI.DEAD = 4

function BossAI:Create (unit, options)
  options = options or {}
  options.tier = options.tier or 1

  local state = {
    handle = unit,
    origin = unit:GetAbsOrigin(),
    leash = options.leash or BOSS_LEASH_SIZE,
    agroDamage = options.agroDamage or BOSS_AGRO_FACTOR * options.tier,
    tier = options.tier,
    currentDamage = 0,
    state = BossAI.IDLE,
    customAgro = options.customAgro or false,

    owner = options.owner,
    isProtected = options.isProtected,

    deathEvent = Event()
  }

  --unit:OnHurt(function (keys)
    --self:HurtHandler(state, keys)
  --end)
  unit:OnDeath(function (keys)
    self:DeathHandler(state, keys)
  end)

  unit:SetIdleAcquire(false)
  unit:SetAcquisitionRange(0)

  return {
    onDeath = state.deathEvent.listen
  }
end

--[[
function BossAI:HurtHandler (state, keys)
  if state.state == BossAI.IDLE then
    DebugPrint('Checking boss agro...')
    DebugPrintTable(keys)

    state.currentDamage = state.currentDamage + keys.damage

    if state.currentDamage > state.agroDamage then
      self:Agro(state, EntIndexToHScript(keys.entindex_attacker))
      state.currentDamage = 0
    end
  elseif state.state == BossAI.AGRO then --luacheck: ignore
  end
end
]]

function BossAI:GiveItemToWholeTeam (item, teamId)
  PlayerResource:GetPlayerIDsForTeam(teamId):each(function (playerId)
    local hero = PlayerResource:GetSelectedHeroEntity(playerId)

    if hero then
      hero:AddItemByName(item)
    end
  end)
end

function BossAI:RewardBossKill(state, deathEventData, teamId)
  if type(state) == "number" then
    state = {
      tier = state
    }
    teamId = teamId or deathEventData
  else
    state.deathEvent.broadcast(deathEventData)
  end
  local team = GetShortTeamName(teamId)
  if not IsPlayerTeam(teamId) then
    return
  end

  PointsManager:AddPoints(teamId)

  local bossKills = CustomNetTables:GetTableValue("stat_display_team", "BK").value
  if bossKills[tostring(teamId)] then
    bossKills[tostring(teamId)] = bossKills[tostring(teamId)] + 1
  else
    bossKills[tostring(teamId)] = 1
  end
  DebugPrint("Setting team " .. teamId .. " boss kills to " .. bossKills[tostring(teamId)])
  CustomNetTables:SetTableValue("stat_display_team", "BK", { value = bossKills })

  local tier = state.tier
  if tier == 1 then
    self:GiveItemToWholeTeam("item_upgrade_core", teamId)

    if not self.hasFarmingCore[team] then
      self.hasFarmingCore[team] = true
    elseif not self.hasSecondBoss[team] then
      self.hasSecondBoss[team] = true

      BossSpawner[team .. "Zone1"].disable()
      BossSpawner[team .. "Zone2"].disable()
    end
  elseif tier == 2 then
    -- NGP:GiveItemToTeam(BossItems["item_upgrade_core_2"], team)
    -- NGP:GiveItemToTeam(BossItems["item_upgrade_core"], team)
    self:GiveItemToWholeTeam("item_upgrade_core_2", teamId)

  elseif tier == 3 then
    -- NGP:GiveItemToTeam(BossItems["item_upgrade_core_3"], team)
    self:GiveItemToWholeTeam("item_upgrade_core_3", teamId)
  elseif tier == 4 then

    -- NGP:GiveItemToTeam(BossItems["item_upgrade_core_4"], team)
    self:GiveItemToWholeTeam("item_upgrade_core_4", teamId)
  elseif tier == 5 then

    PointsManager:AddPoints(teamId)
    -- NGP:GiveItemToTeam(BossItems["item_upgrade_core_4"], team)
    self:GiveItemToWholeTeam("item_upgrade_core_4", teamId)
  elseif tier == 6 then
    PointsManager:AddPoints(teamId)
    -- NGP:GiveItemToTeam(BossItems["item_upgrade_core_4"], team)
    self:GiveItemToWholeTeam("item_upgrade_core_4", teamId)
  end
end

function BossAI:DeathHandler (state, keys)
  DebugPrint('Handling death of boss ' .. state.tier)
  state.state = BossAI.DEAD

  if state.isProtected then
    self:RewardBossKill(state, keys, state.owner)
    state.handle = nil
    return
  end

  -- Create under spectator team so that spectators can always see the capture point
  local capturePointThinker = CreateModifierThinker(state.handle, nil, "modifier_boss_capture_point", nil, state.origin, DOTA_TEAM_SPECTATOR, false)
  local capturePointModifier = capturePointThinker:FindModifierByName("modifier_boss_capture_point")
  capturePointModifier:SetCallback(partial(self.RewardBossKill, self, state, keys))
  -- Give the thinker some vision so that spectators can always see the capture point
  capturePointThinker:SetDayTimeVisionRange(1)
  capturePointThinker:SetNightTimeVisionRange(1)

  state.handle = nil
end

--[[
function BossAI:Agro (state, target)
  if state.customAgro then
    DebugPrint('Running custom agro ai')
    return
  end

  Timers:CreateTimer(1, function ()
    if state.state == BossAI.DEAD then
      return
    end

    if not self:Think(state) or state.state == BossAI.IDLE then
      DebugPrint('Stopping think timer')
      return
    end
    return 1
  end)
  state.state = BossAI.AGRO
  state.agroTarget = target

  state.handle:SetIdleAcquire(true)
  state.handle:SetAcquisitionRange(128)

  ExecuteOrderFromTable({
    UnitIndex = state.handle:entindex(),
    -- OrderType = DOTA_UNIT_ORDER_ATTACK_TARGET,
    OrderType = DOTA_UNIT_ORDER_ATTACK_MOVE,
    Position = target:GetAbsOrigin(),
    Queue = 0,
  })
  ExecuteOrderFromTable({
    UnitIndex = state.handle:entindex(),
    -- OrderType = DOTA_UNIT_ORDER_ATTACK_TARGET,
    OrderType = DOTA_UNIT_ORDER_ATTACK_MOVE,
    Position = state.origin,
    Queue = 1,
  })
end
]]
--[[
function BossAI:Think (state)
  if state.handle:IsNull() then
    -- this shouldn't happen, but sometimes other bugs can cause it
    -- try to keep the bugged game running
    return false
  end

  local distance = (state.handle:GetAbsOrigin() - state.origin):Length()
  DebugPrint(distance)

  if distance > state.leash then
    self:Leash(state)
  elseif distance < state.leash / 2 and state.state == BossAI.LEASHING then
    state.state = BossAI.IDLE
    return false
  elseif distance == 0 and state.state == BossAI.AGRO then
    state.state = BossAI.IDLE
    return false
  end

  return true
end
]]
--[[
function BossAI:Leash (state)
  local difference = state.handle:GetAbsOrigin() - state.origin
  local location = state.origin + (difference / 8)

  if state.state ~= BossAI.LEASHING then
    state.handle:Stop()
  end
  state.state = BossAI.LEASHING

  state.handle:SetIdleAcquire(false)
  state.handle:SetAcquisitionRange(0)

  ExecuteOrderFromTable({
    UnitIndex = state.handle:entindex(),
    -- OrderType = DOTA_UNIT_ORDER_ATTACK_TARGET,
    OrderType = DOTA_UNIT_ORDER_MOVE_TO_POSITION,
    Position = location,
    Queue = 0,
  })
end
]]
