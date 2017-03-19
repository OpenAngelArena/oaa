
-- Taken from bb template
if BossAI == nil then
  DebugPrint ( 'creating new BossAI object' )
  BossAI = class({})

  Debug.EnabledModules['boss:*'] = true
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
    leash = options.leash or 1000,
    agroDamage = options.agroDamage or 100 * options.tier,
    tier = options.tier,
    currentDamage = 0,
    state = BossAI.IDLE,

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

  if state.tier == 1 then
    NGP:GiveItemToTeam({
      item = "item_upgrade_core",
      title = "Upgrade Core",
      description = "Common crafting component for creating tier 1 boss items",
      buildsInto = {
        "item_radiance_2",
        "item_butterfly_2",
        "item_greater_power_treads_2",
        "item_heart_2"
      }
    }, team)
    NGP:GiveItemToTeam({
      item = "item_upgrade_core",
      title = "Upgrade Core",
      description = "Common crafting component for creating tier 1 boss items",
      buildsInto = {
        "item_radiance_2",
        "item_butterfly_2",
        "item_greater_power_treads_2",
        "item_heart_2"
      }
    }, team)

    for playerId = 0,19 do
      if PlayerResource:GetTeam(playerId) == teamId and PlayerResource:GetPlayer(playerId) ~= nil then
        local player = PlayerResource:GetPlayer(playerId)
        local hero = player:GetAssignedHero()

        if hero and not hero.hasFarmingCore then
          hero:AddItemByName("item_farming_core")
          hero.hasFarmingCore = true
        end
      end
    end
  elseif state.tier == 2 then
    NGP:GiveItemToTeam({
      item = "item_combiner",
      title = "Item Combiner",
      description = "Combine two items into one!",
      buildsInto = {
        "item_stoneskin"
      }
    }, team)
    NGP:GiveItemToTeam({
      item = "item_upgrade_core_2",
      title = "Upgrade Core",
      description = "Common crafting component for creating tier 2 boss items",
      buildsInto = {
        "item_radiance_3",
        "item_butterfly_3",
        "item_greater_power_treads_3",
        "item_heart_3"
      }
    }, team)
    NGP:GiveItemToTeam({
      item = "item_upgrade_core_2",
      title = "Upgrade Core",
      description = "Common crafting component for creating tier 2 boss items",
      buildsInto = {
        "item_radiance_3",
        "item_butterfly_3",
        "item_greater_power_treads_3",
        "item_heart_3"
      }
    }, team)
    NGP:GiveItemToTeam({
      item = "item_upgrade_core",
      title = "Upgrade Core",
      description = "Common crafting component for creating tier 1 boss items",
      buildsInto = {
        "item_radiance_2",
        "item_butterfly_2",
        "item_greater_power_treads_2",
        "item_heart_2"
      }
    }, team)
  elseif state.tier == 3 then

    NGP:GiveItemToTeam({
      item = "item_combiner",
      title = "Item Combiner",
      description = "Combine two items into one!",
      buildsInto = {
        "item_stoneskin"
      }
    }, team)
    NGP:GiveItemToTeam({
      item = "item_upgrade_core_3",
      title = "Upgrade Core",
      description = "Common crafting component for creating tier 2 boss items",
      buildsInto = {
        "item_radiance_4",
        "item_butterfly_4",
        "item_greater_power_treads_4",
        "item_heart_4"
      }
    }, team)
    NGP:GiveItemToTeam({
      item = "item_upgrade_core_3",
      title = "Upgrade Core",
      description = "Common crafting component for creating tier 2 boss items",
      buildsInto = {
        "item_radiance_4",
        "item_butterfly_4",
        "item_greater_power_treads_4",
        "item_heart_4"
      }
    }, team)
    NGP:GiveItemToTeam({
      item = "item_upgrade_core_2",
      title = "Upgrade Core",
      description = "Common crafting component for creating tier 1 boss items",
      buildsInto = {
        "item_radiance_3",
        "item_butterfly_3",
        "item_greater_power_treads_3",
        "item_heart_3"
      }
    }, team)
  elseif state.tier == 4 then

    NGP:GiveItemToTeam({
      item = "item_combiner",
      title = "Item Combiner",
      description = "Combine two items into one!",
      buildsInto = {
        "item_stoneskin"
      }
    }, team)
    NGP:GiveItemToTeam({
      item = "item_upgrade_core_4",
      title = "Upgrade Core",
      description = "Common crafting component for creating tier 2 boss items",
      buildsInto = {
        "item_radiance_5",
        "item_butterfly_5",
        "item_greater_power_treads_5",
        "item_heart_5"
      }
    }, team)
    NGP:GiveItemToTeam({
      item = "item_upgrade_core_4",
      title = "Upgrade Core",
      description = "Common crafting component for creating tier 2 boss items",
      buildsInto = {
        "item_radiance_5",
        "item_butterfly_5",
        "item_greater_power_treads_5",
        "item_heart_5"
      }
    }, team)
    NGP:GiveItemToTeam({
      item = "item_upgrade_core_3",
      title = "Upgrade Core",
      description = "Common crafting component for creating tier 1 boss items",
      buildsInto = {
        "item_radiance_4",
        "item_butterfly_4",
        "item_greater_power_treads_4",
        "item_heart_4"
      }
    }, team)
  elseif state.tier == 5 then

    NGP:GiveItemToTeam({
      item = "item_combiner",
      title = "Item Combiner",
      description = "Combine two items into one!",
      buildsInto = {
        "item_stoneskin"
      }
    }, team)
    NGP:GiveItemToTeam({
      item = "item_upgrade_core_5",
      title = "Upgrade Core",
      description = "Common crafting component for creating tier 2 boss items",
      buildsInto = {
        "item_radiance_6",
        "item_butterfly_6",
        "item_greater_power_treads_6",
        "item_heart_6"
      }
    }, team)
    NGP:GiveItemToTeam({
      item = "item_upgrade_core_5",
      title = "Upgrade Core",
      description = "Common crafting component for creating tier 2 boss items",
      buildsInto = {
        "item_radiance_6",
        "item_butterfly_6",
        "item_greater_power_treads_6",
        "item_heart_6"
      }
    }, team)
    NGP:GiveItemToTeam({
      item = "item_upgrade_core_4",
      title = "Upgrade Core",
      description = "Common crafting component for creating tier 1 boss items",
      buildsInto = {
        "item_radiance_5",
        "item_butterfly_5",
        "item_greater_power_treads_5",
        "item_heart_5"
      }
    }, team)
  elseif state.tier == 6 then

    NGP:GiveItemToTeam({
      item = "item_combiner",
      title = "Item Combiner",
      description = "Combine two items into one!",
      buildsInto = {
        "item_stoneskin"
      }
    }, team)
    PointsManager:AddPoints(teamId)

    NGP:GiveItemToTeam({
      item = "item_upgrade_core_5",
      title = "Upgrade Core",
      description = "Common crafting component for creating tier 2 boss items",
      buildsInto = {
        "item_radiance_6",
        "item_butterfly_6",
        "item_greater_power_treads_6",
        "item_heart_6"
      }
    }, team)
    NGP:GiveItemToTeam({
      item = "item_upgrade_core_5",
      title = "Upgrade Core",
      description = "Common crafting component for creating tier 2 boss items",
      buildsInto = {
        "item_radiance_6",
        "item_butterfly_6",
        "item_greater_power_treads_6",
        "item_heart_6"
      }
    }, team)
    NGP:GiveItemToTeam({
      item = "item_upgrade_core_4",
      title = "Upgrade Core",
      description = "Common crafting component for creating tier 1 boss items",
      buildsInto = {
        "item_radiance_5",
        "item_butterfly_5",
        "item_greater_power_treads_5",
        "item_heart_5"
      }
    }, team)
  end
end

function BossAI:Agro (state, target)
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
  local distance = (state.handle:GetAbsOrigin() - state.origin):Length()
  DebugPrint(distance)

  if distance > state.leash then
    BossAI:Leash(state)
  elseif distance < state.leash / 2 and state.state == BossAI.LEASHING then
    state.state = BossAI.IDLE
    return false
  end

  return true
end

function BossAI:Leash (state)
  local difference = state.handle:GetAbsOrigin() - state.origin
  local location = state.origin + (difference / 2)

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
