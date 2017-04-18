
LinkLuaModifier( "modifier_boss_phase_controller", "modifiers/modifier_boss_phase_controller", LUA_MODIFIER_MOTION_NONE )

function Spawn (entityKeyValues)
  thisEntity:FindAbilityByName("boss_shielder_shield")

  thisEntity:SetContextThink( "ShielderThink", partial(ShielderThink, thisEntity) , 1)
  print("Starting AI for " .. thisEntity:GetUnitName() .. " " .. thisEntity:GetEntityIndex())

  ABILITY_shield = thisEntity:FindAbilityByName("boss_shielder_shield")

  local phaseController = thisEntity:AddNewModifier(thisEntity, ABILITY_shield, "modifier_boss_phase_controller", {})
  phaseController:SetPhases({ 66, 33 })
  phaseController:SetAbilities({
    "boss_shielder_shield"
})
end

--[[Taken from bb template
if BossAI == nil then
  DebugPrint ( 'creating new BossAI object' )
  BossAI = class({})

  Debug.EnabledModules['boss:*'] = false
end]]

BossAI.IDLE = 1
BossAI.AGRO = 2
BossAI.LEASHING = 3
BossAI.DEAD = 4

function BossAI:Create (unit, options)
  options = {}
  options.tier = 1

  local state = {
    handle = unit,
    origin = unit:GetAbsOrigin(),
    leash = 1500,
    agroDamage = 100 * options.tier,
    tier = 1,
    currentDamage = 0,
    state = BossAI.IDLE,
    customAgro = options.customAgro or false,

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
  elseif state.state == BossAI.AGRO then
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

  state.deathEvent.broadcast(keys)

  if teamId == 2 then
    team = 'good'
  elseif teamId == 3 then
    team = 'bad'
  else
    return
  end

  BossAI:GiveItemToWholeTeam("item_upgrade_core", teamId)

  for playerId = 0,19 do
    if PlayerResource:GetTeam(playerId) == teamId and PlayerResource:GetPlayer(playerId) ~= nil then
      local player = PlayerResource:GetPlayer(playerId)
      local hero = player:GetAssignedHero()

      if hero then
        if not hero.hasFarmingCore then
          hero:AddItemByName("item_farming_core")
          hero.hasFarmingCore = true
        elseif not hero.hasReflexCore then
          hero:AddItemByName("item_reflex_core")
          hero.hasReflexCore = true
        end
      end
    end
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
    OrderType = DOTA_UNIT_ORDER_ATTACK_TARGET,
    --OrderType = DOTA_UNIT_ORDER_ATTACK_MOVE,
    Position = target:GetAbsOrigin(),
    Queue = 0,
  })
  ExecuteOrderFromTable({
    UnitIndex = state.handle:entindex(),
    OrderType = DOTA_UNIT_ORDER_ATTACK_TARGET,
    --OrderType = DOTA_UNIT_ORDER_ATTACK_MOVE,
    Position = state.origin,
    Queue = 1,
  })
end

function BossAI:Think (state)
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
