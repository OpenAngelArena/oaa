
-- Taken from bb template
if BossAI == nil then
  DebugPrint ( 'creating new BossAI object' )
  BossAI = class({})
  BossAI.hasFarmingCore = {}
  BossAI.hasReflexCore = {}

  Debug.EnabledModules['boss:ai'] = false
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
    leash = options.leash or 1500,
    agroDamage = options.agroDamage or 100 * options.tier,
    tier = options.tier,
    currentDamage = 0,
    state = BossAI.IDLE,
    customAgro = options.customAgro or false,

    owner = options.owner,
    isProtected = options.isProtected,

    deathEvent = Event()
  }

  unit:OnHurt(function (keys)
    BossAI:HurtHandler(state, keys)
  end)
  unit:OnDeath(function (keys)
    BossAI:DeathHandler(state, keys)
  end)

  unit:SetIdleAcquire(false)
  unit:SetAcquisitionRange(0)

  return {
    onDeath = state.deathEvent.listen
  }
end

function BossAI:HurtHandler (state, keys)
  if state.state == BossAI.IDLE then
    DebugPrint('Checking boss agro...')
    DebugPrintTable(keys)

    state.currentDamage = state.currentDamage + keys.damage

    if state.currentDamage > state.agroDamage then
      BossAI:Agro(state, EntIndexToHScript(keys.entindex_attacker))
      state.currentDamage = 0
    end
  elseif state.state == BossAI.AGRO then --luacheck: ignore
  end
end

function BossAI:GiveItemToWholeTeam (item, teamId)
  for playerId = 0,19 do
    if PlayerResource:GetTeam(playerId) == teamId and PlayerResource:GetPlayer(playerId) ~= nil then
      local player = PlayerResource:GetPlayer(playerId)
      local hero = player:GetAssignedHero()

      hero:AddItemByName(item)
    end
  end
end

function BossAI:DeathHandler (state, keys)
  DebugPrint('Handling death of boss ' .. state.tier)
  state.state = BossAI.DEAD

  state.handle = nil
  local killer = EntIndexToHScript(keys.entindex_attacker)
  local teamId = killer:GetTeam()
  local team = nil

  state.deathEvent.broadcast(keys)

  if state.isProtected then
    teamId = state.owner
  end
  if teamId == 2 then
    team = 'good'
  elseif teamId == 3 then
    team = 'bad'
  else
    return
  end

  PointsManager:AddPoints(teamId)

  if state.tier == 1 then
    BossAI:GiveItemToWholeTeam("item_upgrade_core", teamId)

    if not BossAI.hasFarmingCore[team] then
      BossAI.hasFarmingCore[team] = true
    elseif not BossAI.hasReflexCore[team] then
      BossAI.hasReflexCore[team] = true

      BossSpawner[team .. "Zone1"].disable()
      BossSpawner[team .. "Zone2"].disable()
    end

    for playerId = 0,19 do
      if PlayerResource:GetTeam(playerId) == teamId and PlayerResource:GetPlayer(playerId) ~= nil then
        local player = PlayerResource:GetPlayer(playerId)
        local hero = player:GetAssignedHero()

        if hero then
          if BossAI.hasFarmingCore[team] and not hero.hasFarmingCore then
            hero:AddItemByName("item_farming_core")
            hero.hasFarmingCore = true
          elseif BossAI.hasReflexCore[team] and not hero.hasReflexCore then
            hero:AddItemByName("item_reflex_core")
            hero.hasReflexCore = true
          end
        end
      end
    end

  elseif state.tier == 2 then
    NGP:GiveItemToTeam(BossItems["item_upgrade_core_2"], team)
    NGP:GiveItemToTeam(BossItems["item_upgrade_core"], team)
    BossAI:GiveItemToWholeTeam("item_upgrade_core_2", teamId)

  elseif state.tier == 3 then
    NGP:GiveItemToTeam(BossItems["item_upgrade_core_3"], team)
    BossAI:GiveItemToWholeTeam("item_upgrade_core_3", teamId)
  elseif state.tier == 4 then

    NGP:GiveItemToTeam(BossItems["item_upgrade_core_4"], team)
    BossAI:GiveItemToWholeTeam("item_upgrade_core_4", teamId)
  elseif state.tier == 5 then

    NGP:GiveItemToTeam(BossItems["item_upgrade_core_4"], team)
    BossAI:GiveItemToWholeTeam("item_upgrade_core_4", teamId)
  elseif state.tier == 6 then
    NGP:GiveItemToTeam(BossItems["item_upgrade_core_4"], team)
    BossAI:GiveItemToWholeTeam("item_upgrade_core_4", teamId)
  end
end

function BossAI:Agro (state, target)
  if state.customAgro then
    DebugPrint('Running custom agro ai')
    return
  end

  Timers:CreateTimer(1, function ()
    if state.state == BossAI.DEAD then
      return
    end

    if not BossAI:Think(state) or state.state == BossAI.IDLE then
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

function BossAI:Think (state)
  if state.handle:IsNull() then
    -- this shouldn't happen, but sometimes other bugs can cause it
    -- try to keep the bugged game running
    return false
  end

  local distance = (state.handle:GetAbsOrigin() - state.origin):Length()
  DebugPrint(distance)

  if distance > state.leash then
    BossAI:Leash(state)
  elseif distance < state.leash / 2 and state.state == BossAI.LEASHING then
    state.state = BossAI.IDLE
    return false
  elseif distance == 0 and state.state == BossAI.AGRO then
    state.state = BossAI.IDLE
    return false
  end

  return true
end

function BossAI:Leash (state)
  local difference = state.handle:GetAbsOrigin() - state.origin
  local location = state.origin + (difference / 8)

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
  ExecuteOrderFromTable({
    UnitIndex = state.handle:entindex(),
    -- OrderType = DOTA_UNIT_ORDER_ATTACK_TARGET,
    OrderType = DOTA_UNIT_ORDER_ATTACK_MOVE,
    Position = state.origin,
    Queue = 1,
  })
end
