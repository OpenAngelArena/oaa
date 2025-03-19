-- This file contains all barebones-registered events and has already set up the passed-in parameters for your use.

-- Cleanup a player when they leave
-- game event object for OnDisconnect
local OnDisconnectEvent = CreateGameEvent('OnDisconnect')
-- GameEvents is usually read only, so we luacheck ignore :D
GameEvents.OnPlayerDisconnect = GameEvents.OnDisconnect -- luacheck: ignore
function GameMode:OnDisconnect(keys)
  OnDisconnectEvent(keys)
  DebugPrint('[BAREBONES] Player Disconnected ' .. tostring(keys.userid))
  DebugPrintTable(keys)
end
-- The overall game state has changed
-- game event object for OnGameRulesStateChange
local OnGameRulesStateChangeEvent = CreateGameEvent('OnGameRulesStateChange')
local OnStrategyEvent = CreateGameEvent('OnStrategy')
local OnPreGameEvent = CreateGameEvent('OnPreGame')
local OnEndGameEvent = CreateGameEvent('OnEndGame')
function GameMode:OnGameRulesStateChange(keys)
  OnGameRulesStateChangeEvent(keys)
  DebugPrint("[BAREBONES] GameRules State Changed")
  DebugPrintTable(keys)
  local newState = GameRules:State_Get()
  if newState == DOTA_GAMERULES_STATE_STRATEGY_TIME then
    OnStrategyEvent()
  elseif newState == DOTA_GAMERULES_STATE_PRE_GAME then
    OnPreGameEvent(keys)
    GameMode:OnPreGame()
  elseif newState == DOTA_GAMERULES_STATE_POST_GAME then
    OnEndGameEvent(keys)
  elseif newState == DOTA_GAMERULES_STATE_GAME_IN_PROGRESS then
    print("Modules in OnGameInProgress are trying to be initialized again when the state changes to DOTA_GAMERULES_STATE_GAME_IN_PROGRESS.")
    GameMode:OnGameInProgress()
  end
end

-- An NPC has spawned somewhere in game.  This includes heroes
-- game event object for OnNPCSpawned
local OnNPCSpawnedEvent = CreateGameEvent('OnNPCSpawned')
local function DecorateNPC(npc)
  npc.deathEvent = Event()
  function npc:OnDeath(fn)
    return npc.deathEvent.listen(fn)
  end

  npc.hurtEvent = Event()
  function npc:OnHurt(fn)
    return npc.hurtEvent.listen(fn)
  end
end
function GameMode:OnNPCSpawned(keys)
  OnNPCSpawnedEvent(keys)
  DebugPrint("[BAREBONES] NPC Spawned")
  DebugPrintTable(keys)

  local npc = EntIndexToHScript(keys.entindex)
  DecorateNPC(npc)

  --[[ -- legacy armor formula
  if npc.GetPhysicalArmorValue then
    if npc:IsRealHero() or (npc:IsConsideredHero() and (not npc:IsIllusion()) and npc:GetTeamNumber() ~= DOTA_TEAM_NEUTRALS) then
      npc:AddNewModifier(npc, nil, "modifier_legacy_armor", {})
    end
  end
  ]]
  --[[ -- Fixing greater treants created with old shard sprout
  if npc.GetUnitName then
    if npc:GetUnitName() == "npc_dota_furion_treant_large" then
      local playerID = UnitVarToPlayerID(npc)
      local hero = PlayerResource:GetSelectedHeroEntity(playerID)
      if hero then
        local force_of_nature_ability = hero:FindAbilityByName("furion_force_of_nature_oaa")
        if force_of_nature_ability then
          local ability_level = force_of_nature_ability:GetLevel()
          if ability_level > 0 then
            local correct_damage = force_of_nature_ability:GetLevelSpecialValueFor("treant_large_damage", ability_level-1)
            local correct_hp = force_of_nature_ability:GetLevelSpecialValueFor("treant_large_health", ability_level-1)
            local correct_speed = force_of_nature_ability:GetLevelSpecialValueFor("treant_move_speed", ability_level-1)
            local correct_armor = force_of_nature_ability:GetLevelSpecialValueFor("treant_armor", ability_level-1)

            -- Fix DAMAGE
            npc:SetBaseDamageMin(correct_damage)
            npc:SetBaseDamageMax(correct_damage)
            -- Fix HP
            npc:SetBaseMaxHealth(correct_hp)
            npc:SetMaxHealth(correct_hp)
            npc:SetHealth(correct_hp)
            -- Fix ARMOR
            npc:SetPhysicalArmorBaseValue(correct_armor)
            -- Fix Movement speed
            npc:SetBaseMoveSpeed(correct_speed)
          end
        end
      end
    end
  end
  ]]

  if npc.RemoveAbility then
    local abilities_to_remove = {
      ability_capture = GetMapName() ~= "oaa_bigmode",
      ability_lamp_use = GetMapName() ~= "oaa_bigmode" and GetMapName() ~= "tinymode",
      abyssal_underlord_portal_warp = true,
      neutral_upgrade = true,
      twin_gate_portal_warp = GetMapName() ~= "oaa_bigmode",
      --special_bonus_attributes = true,
    }

    local max_ability_count = npc:GetAbilityCount() - 1 -- DOTA_MAX_ABILITIES - 1

    for i = 0, max_ability_count do
      local ab = npc:GetAbilityByIndex(i)
      if ab then
        local name = ab:GetAbilityName()
        if abilities_to_remove[name] then
          npc:RemoveAbility(name)
        end
      end
    end
  end
end

-- Custom event that fires when an entity takes damage that reduces its health to 0
local OnEntityFatalDamage = CreateGameEvent('OnEntityFatalDamage')

-- An entity somewhere has been hurt.  This event fires very often with many units so don't do too many expensive
-- operations here
-- game event object for OnEntityHurt
local OnEntityHurtEvent = CreateGameEvent('OnEntityHurt')
function GameMode:OnEntityHurt(keys)
  OnEntityHurtEvent(keys)
  --DebugPrint("[BAREBONES] Entity Hurt")
  --DebugPrintTable(keys)

  if keys.entindex_attacker and keys.entindex_killed then
    --local entCause = EntIndexToHScript(keys.entindex_attacker)
    local entVictim = EntIndexToHScript(keys.entindex_killed)

    if entVictim.GetHealth and entVictim:GetHealth() == 0 then
      OnEntityFatalDamage(keys)
    end

    -- The ability/item used to damage, or nil if not damaged by an item/ability
    local damagingAbility
    if keys.entindex_inflictor then
      damagingAbility = EntIndexToHScript( keys.entindex_inflictor )
    end

    if entVictim.hurtEvent then
      entVictim.hurtEvent.broadcast(keys)
    end
  end
end

-- A player has reconnected to the game.  This function can be used to repaint Player-based particles or change
-- state as necessary
-- game event object for OnPlayerReconnect
local OnPlayerReconnectEvent = CreateGameEvent('OnPlayerReconnect')
function GameMode:OnPlayerReconnect(keys)
  OnPlayerReconnectEvent(keys)
  DebugPrint( '[BAREBONES] OnPlayerReconnect' )
  DebugPrintTable(keys)
end

-- A player leveled up an ability
-- game event object for OnPlayerLearnedAbility
local OnPlayerLearnedAbilityEvent = CreateGameEvent('OnPlayerLearnedAbility')
function GameMode:OnPlayerLearnedAbility(keys)
  OnPlayerLearnedAbilityEvent(keys)
  DebugPrint('[BAREBONES] OnPlayerLearnedAbility')
  DebugPrintTable(keys)

  --local playerID = keys.PlayerID
  --local abilityname = keys.abilityname
end

-- A player leveled up
-- game event object for OnPlayerLevelUp
local OnPlayerLevelUpEvent = CreateGameEvent('OnPlayerLevelUp')
function GameMode:OnPlayerLevelUp(keys)
  OnPlayerLevelUpEvent(keys)
  DebugPrint('[BAREBONES] OnPlayerLevelUp')
  DebugPrintTable(keys)
end

-- A rune was activated by a player
-- game event object for OnRuneActivated
local OnRuneActivatedEvent = CreateGameEvent('OnRuneActivated')
function GameMode:OnRuneActivated(keys)
  OnRuneActivatedEvent(keys)
  DebugPrint('[BAREBONES] OnRuneActivated')
  DebugPrintTable(keys)

  --local playerID = keys.PlayerID
  --local rune = keys.rune
end

-- game event object for OnHeroKilled
local OnHeroKilledEvent = CreateGameEvent('OnHeroKilled')
function GameMode:OnHeroKilled(keys)
  OnHeroKilledEvent(keys)
end

-- An entity died
-- game event object for keys
local OnEntityKilledEvent = CreateGameEvent('OnEntityKilled')
local OnHeroDiedEvent = CreateGameEvent('OnHeroDied')
function GameMode:OnEntityKilled(keys)
  OnEntityKilledEvent(keys)
  DebugPrint( '[BAREBONES] OnEntityKilled Called' )
  DebugPrintTable( keys )

  -- Indexes:
  local killed_entity_index = keys.entindex_killed
  local attacker_entity_index = keys.entindex_attacker
  local inflictor_index = keys.entindex_inflictor -- it can be nil if not killed by an item/ability

  -- The Unit that was Killed
  local killedUnit
  if killed_entity_index then
    killedUnit = EntIndexToHScript(killed_entity_index)
  end

  -- Find the entity (killer) that killed the entity mentioned above
  local killerEntity
  if attacker_entity_index then
    killerEntity = EntIndexToHScript(attacker_entity_index)
  end

  -- Find the ability/item used to kill, or nil if not killed by an item/ability
  local killerAbility
  if inflictor_index then
    killerAbility = EntIndexToHScript(inflictor_index)
  end

  -- Fire ent killed event
  if killedUnit.deathEvent then
    killedUnit.deathEvent.broadcast(keys)
  end

  if killedUnit.IsRealHero and killedUnit:IsRealHero() then
    OnHeroDiedEvent(killedUnit)
  end
end

-- This function is called once when the player fully connects and becomes "Ready" during Loading
-- game event object for OnConnectFull
local OnConnectFullEvent = CreateGameEvent('OnConnectFull')
function GameMode:OnConnectFull(keys)
  OnConnectFullEvent(keys)
  DebugPrint('[BAREBONES] OnConnectFull')
  DebugPrintTable(keys)
end

-- This function is called whenever an item is combined to create a new item
-- game event object for OnItemCombined
local OnItemCombinedEvent = CreateGameEvent('OnItemCombined')
function GameMode:OnItemCombined(keys)
  OnItemCombinedEvent(keys)
  DebugPrint('[BAREBONES] OnItemCombined')
  DebugPrintTable(keys)

  -- The playerID of the hero who is buying something
  --local playerID = keys.PlayerID

  -- The name of the item purchased
  --local itemName = keys.itemname

  -- The cost of the item purchased
  --local itemcost = keys.itemcost
end

local OnHeroSwapedEvent = CreateGameEvent('OnHeroSwapped')
function GameMode:OnHeroSwapped(keys)
  OnHeroSwapedEvent(keys)
end
