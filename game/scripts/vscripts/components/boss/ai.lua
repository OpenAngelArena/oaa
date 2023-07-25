LinkLuaModifier("modifier_oaa_thinker", "modifiers/modifier_oaa_thinker.lua", LUA_MODIFIER_MOTION_NONE)
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

  unit:OnDeath(function (keys)
    self:DeathHandler(state, keys)
  end)

  unit:SetIdleAcquire(false)
  unit:SetAcquisitionRange(0)

  return {
    onDeath = state.deathEvent.listen
  }
end

function BossAI:GiveItemToWholeTeam (item, teamId)
  if CorePointsManager then
    CorePointsManager:GiveCorePointsToWholeTeam(CorePointsManager:GetCorePointValueOfUpdgradeCore(item), teamId)
  else
    PlayerResource:GetPlayerIDsForTeam(teamId):each(function (playerId)
      local hero = PlayerResource:GetSelectedHeroEntity(playerId)

      if hero then
        hero:AddItemByName(item)
      end
    end)
  end
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

      --BossSpawner[team .. "Zone1"].disable()
      --BossSpawner[team .. "Zone2"].disable()
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

  -- Create a capture point
  --local capturePointThinker = CreateModifierThinker(state.handle, nil, "modifier_boss_capture_point", nil, state.origin, DOTA_TEAM_SPECTATOR, false)
  local capturePointThinker = CreateUnitByName("npc_dota_custom_dummy_unit", state.origin, false, nil, nil, DOTA_TEAM_SPECTATOR)
  capturePointThinker:AddNewModifier(capturePointThinker, nil, "modifier_oaa_thinker", {})
  --local capturePointModifier = capturePointThinker:FindModifierByName("modifier_boss_capture_point")
  local capturePointModifier = capturePointThinker:AddNewModifier(capturePointThinker, nil, "modifier_boss_capture_point", {})
  capturePointModifier:SetCallback(partial(self.RewardBossKill, self, state, keys))

  -- Give the thinker some vision so that spectators can always see the capture point
  capturePointThinker:SetDayTimeVisionRange(1)
  capturePointThinker:SetNightTimeVisionRange(1)

  state.handle = nil
end
