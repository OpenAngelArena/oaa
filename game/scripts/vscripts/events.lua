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

  local name = keys.name
  local networkid = keys.networkid
  local reason = keys.reason
  local userid = keys.userid
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
  -- Strategy time started
  if newState == DOTA_GAMERULES_STATE_STRATEGY_TIME then
    OnStrategyEvent()
    GameMode:OnStrategyTime()
  -- Pre-Game started
  elseif newState == DOTA_GAMERULES_STATE_PRE_GAME then
    OnPreGameEvent(keys)
    GameMode:OnPreGame()
  elseif newState == DOTA_GAMERULES_STATE_POST_GAME then
    OnEndGameEvent(keys)
  elseif newState == DOTA_GAMERULES_STATE_GAME_IN_PROGRESS then
    GameMode:OnGameInProgress()
    OnGameInProgressEvent()
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

  -- Replace Silencer's int steal with a custom modifier
  if npc:GetUnitName() == "npc_dota_hero_silencer" then
    LinkLuaModifier("modifier_oaa_int_steal", "modifiers/modifier_oaa_int_steal.lua", LUA_MODIFIER_MOTION_NONE)
    Timers:CreateTimer(function()
      npc:RemoveModifierByName("modifier_silencer_int_steal")
      npc:AddNewModifier(npc, npc:FindAbilityByName("silencer_glaives_of_wisdom_oaa"), "modifier_oaa_int_steal", {})
    end)
  end

  if npc.GetPhysicalArmorValue then
    LinkLuaModifier("modifier_legacy_armor", "modifiers/modifier_legacy_armor.lua", LUA_MODIFIER_MOTION_NONE)
    if npc:IsRealHero() or (npc:IsConsideredHero() and (not npc:IsIllusion())) then
      npc:AddNewModifier(npc, nil, "modifier_legacy_armor", {})
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

  local damagebits = keys.damagebits -- This might always be 0 and therefore useless
  if keys.entindex_attacker ~= nil and keys.entindex_killed ~= nil then
    local entCause = EntIndexToHScript(keys.entindex_attacker)
    local entVictim = EntIndexToHScript(keys.entindex_killed)

    if entVictim.GetHealth and entVictim:GetHealth() == 0 then
      OnEntityFatalDamage(keys)
    end

    -- The ability/item used to damage, or nil if not damaged by an item/ability
    local damagingAbility = nil

    if keys.entindex_inflictor ~= nil then
      damagingAbility = EntIndexToHScript( keys.entindex_inflictor )
    end

    if entVictim.hurtEvent then
      entVictim.hurtEvent.broadcast(keys)
    end
  end
end

-- An item was picked up off the ground
-- game event object for OnItemPickedUp
local OnItemPickedUpEvent = CreateGameEvent('OnItemPickedUp')
function GameMode:OnItemPickedUp(keys)
  OnItemPickedUpEvent(keys)
  DebugPrint( '[BAREBONES] OnItemPickedUp' )
  DebugPrintTable(keys)

  local unitEntity = nil
  if keys.UnitEntitIndex then
    unitEntity = EntIndexToHScript(keys.UnitEntitIndex)
  elseif keys.HeroEntityIndex then
    unitEntity = EntIndexToHScript(keys.HeroEntityIndex)
  end

  local itemEntity = EntIndexToHScript(keys.ItemEntityIndex)
  local playerID = keys.PlayerID
  local itemname = keys.itemname
end

-- An item was picked up off the ground
-- game event object for OnItemGifted
local OnItemGiftedEvent = CreateGameEvent('OnItemGifted')
function GameMode:OnItemGifted(keys)
  OnItemGiftedEvent(keys)
  DebugPrint( '[BAREBONES] OnItemGifted' )
  DebugPrintTable(keys)

  -- itemname ( string )
  -- PlayerID ( short )
  -- ItemEntityIndex( short )
  -- HeroEntityIndex( short )

  local unitEntity = nil
  if keys.UnitEntitIndex then
    unitEntity = EntIndexToHScript(keys.UnitEntitIndex)
  elseif keys.HeroEntityIndex then
    unitEntity = EntIndexToHScript(keys.HeroEntityIndex)
  end

  local itemEntity = EntIndexToHScript(keys.ItemEntityIndex)
  local playerID = keys.PlayerID
  local itemname = keys.itemname
end

-- An item was picked up off the ground
-- game event object for OnPlayerGotItem
local OnPlayerGotItemEvent = CreateGameEvent('OnPlayerGotItem')
function GameMode:OnPlayerGotItem(keys)
  OnPlayerGotItemEvent(keys)
  DebugPrint( '[BAREBONES] OnPlayerGotItem' )
  DebugPrintTable(keys)

  -- itemname ( string )
  -- PlayerID ( short )
  -- ItemEntityIndex( short )
  -- HeroEntityIndex( short )

  local unitEntity = nil
  if keys.UnitEntitIndex then
    unitEntity = EntIndexToHScript(keys.UnitEntitIndex)
  elseif keys.HeroEntityIndex then
    unitEntity = EntIndexToHScript(keys.HeroEntityIndex)
  end

  local itemEntity = EntIndexToHScript(keys.ItemEntityIndex)
  local playerID = keys.PlayerID
  local itemname = keys.itemname
end

-- An item was picked up off the ground
-- game event object for OnInventoryItemChanged
local OnInventoryItemChangedEvent = CreateGameEvent('OnInventoryItemChanged')
function GameMode:OnInventoryItemChanged(keys)
  OnInventoryItemChangedEvent(keys)
  DebugPrint( '[BAREBONES] OnInventoryItemChanged' )
  DebugPrintTable(keys)

  -- itemname ( string )
  -- PlayerID ( short )
  -- ItemEntityIndex( short )
  -- HeroEntityIndex( short )

  local unitEntity = nil
  if keys.UnitEntitIndex then
    unitEntity = EntIndexToHScript(keys.UnitEntitIndex)
  elseif keys.HeroEntityIndex then
    unitEntity = EntIndexToHScript(keys.HeroEntityIndex)
  end

  local itemEntity = EntIndexToHScript(keys.ItemEntityIndex)
  local playerID = keys.PlayerID
  local itemname = keys.itemname
end

-- An item was picked up off the ground
-- game event object for OnInventoryChanged
local OnInventoryChangedEvent = CreateGameEvent('OnInventoryChanged')
function GameMode:OnInventoryChanged(keys)
  OnInventoryChangedEvent(keys)
  DebugPrint( '[BAREBONES] OnInventoryChanged' )
  DebugPrintTable(keys)

  -- itemname ( string )
  -- PlayerID ( short )
  -- ItemEntityIndex( short )
  -- HeroEntityIndex( short )

  local unitEntity = nil
  if keys.UnitEntitIndex then
    unitEntity = EntIndexToHScript(keys.UnitEntitIndex)
  elseif keys.HeroEntityIndex then
    unitEntity = EntIndexToHScript(keys.HeroEntityIndex)
  end

  local itemEntity = EntIndexToHScript(keys.ItemEntityIndex)
  local playerID = keys.PlayerID
  local itemname = keys.itemname
end

-- A player has reconnected to the game.  This function can be used to repaint Player-based particles or change
-- state as necessary
-- game event object for OnPlayerReconnect
local OnPlayerReconnectEvent = CreateGameEvent('OnPlayerReconnect')
function GameMode:OnPlayerReconnect(keys)
  OnPlayerReconnectEvent(keys)
  DebugPrint( '[BAREBONES] OnPlayerReconnect' )
  DebugPrintTable(keys)

  local playerID = keys.PlayerID
end

-- An item was purchased by a player
-- game event object for OnItemPurchased
local OnItemPurchasedEvent = CreateGameEvent('OnItemPurchased')
function GameMode:OnItemPurchased(keys)
  OnItemPurchasedEvent(keys)
  DebugPrint( '[BAREBONES] OnItemPurchased' )
  DebugPrintTable(keys)

  -- The playerID of the hero who is buying something
  local playerID = keys.PlayerID

  -- The name of the item purchased
  local itemName = keys.itemname

  -- The cost of the item purchased
  local itemcost = keys.itemcost
end

-- An ability was used by a player
-- game event object for OnAbilityUsed
local OnAbilityUsedEvent = CreateGameEvent('OnAbilityUsed')
function GameMode:OnAbilityUsed(keys)
  OnAbilityUsedEvent(keys)
  DebugPrint('[BAREBONES] AbilityUsed')
  DebugPrintTable(keys)

  local playerID = keys.PlayerID
  local abilityname = keys.abilityname
end

-- A non-player entity (necro-book, chen creep, etc) used an ability
-- game event object for OnNonPlayerUsedAbility
local OnNonPlayerUsedAbilityEvent = CreateGameEvent('OnNonPlayerUsedAbility')
function GameMode:OnNonPlayerUsedAbility(keys)
  OnNonPlayerUsedAbilityEvent(keys)
  DebugPrint('[BAREBONES] OnNonPlayerUsedAbility')
  DebugPrintTable(keys)

  local abilityname = keys.abilityname
end

-- A player changed their name
-- game event object for OnPlayerChangedName
local OnPlayerChangedNameEvent = CreateGameEvent('OnPlayerChangedName')
function GameMode:OnPlayerChangedName(keys)
  OnPlayerChangedNameEvent(keys)
  DebugPrint('[BAREBONES] OnPlayerChangedName')
  DebugPrintTable(keys)

  local newName = keys.newname
  local oldName = keys.oldName
end

-- A player leveled up an ability
-- game event object for OnPlayerLearnedAbility
local OnPlayerLearnedAbilityEvent = CreateGameEvent('OnPlayerLearnedAbility')
function GameMode:OnPlayerLearnedAbility(keys)
  OnPlayerLearnedAbilityEvent(keys)
  DebugPrint('[BAREBONES] OnPlayerLearnedAbility')
  DebugPrintTable(keys)

  local playerID = keys.PlayerID
  local abilityname = keys.abilityname
end

-- A channelled ability finished by either completing or being interrupted
-- game event object for OnAbilityChannelFinished
local OnAbilityChannelFinishedEvent = CreateGameEvent('OnAbilityChannelFinished')
function GameMode:OnAbilityChannelFinished(keys)
  OnAbilityChannelFinishedEvent(keys)
  DebugPrint('[BAREBONES] OnAbilityChannelFinished')
  DebugPrintTable(keys)

  local abilityname = keys.abilityname
  local interrupted = keys.interrupted == 1
end

-- A player leveled up
-- game event object for OnPlayerLevelUp
local OnPlayerLevelUpEvent = CreateGameEvent('OnPlayerLevelUp')
function GameMode:OnPlayerLevelUp(keys)
  OnPlayerLevelUpEvent(keys)
  DebugPrint('[BAREBONES] OnPlayerLevelUp')
  DebugPrintTable(keys)
end

-- A player last hit a creep, a tower, or a hero
-- game event object for OnLastHit
local OnLastHitEvent = CreateGameEvent('OnLastHit')
function GameMode:OnLastHit(keys)
  OnLastHitEvent(keys)
  DebugPrint('[BAREBONES] OnLastHit')
  DebugPrintTable(keys)

  local isFirstBlood = keys.FirstBlood == 1
  local isHeroKill = keys.HeroKill == 1
  local isTowerKill = keys.TowerKill == 1
  local playerID = keys.PlayerID
  local killedEnt = EntIndexToHScript(keys.EntKilled)
end

-- A tree was cut down by tango, quelling blade, etc
-- game event object for OnTreeCut
local OnTreeCutEvent = CreateGameEvent('OnTreeCut')
function GameMode:OnTreeCut(keys)
  OnTreeCutEvent(keys)
  DebugPrint('[BAREBONES] OnTreeCut')
  DebugPrintTable(keys)

  local treeX = keys.tree_x
  local treeY = keys.tree_y
end

-- A rune was activated by a player
-- game event object for OnRuneActivated
local OnRuneActivatedEvent = CreateGameEvent('OnRuneActivated')
function GameMode:OnRuneActivated(keys)
  OnRuneActivatedEvent(keys)
  DebugPrint('[BAREBONES] OnRuneActivated')
  DebugPrintTable(keys)

  local playerID = keys.PlayerID
  local rune = keys.rune
end

-- A player took damage from a tower
-- game event object for OnPlayerTakeTowerDamage
local OnPlayerTakeTowerDamageEvent = CreateGameEvent('OnPlayerTakeTowerDamage')
function GameMode:OnPlayerTakeTowerDamage(keys)
  OnPlayerTakeTowerDamageEvent(keys)
  DebugPrint('[BAREBONES] OnPlayerTakeTowerDamage')
  DebugPrintTable(keys)

  local playerID = keys.PlayerID
  local damage = keys.damage
end

-- A player picked a hero
-- game event object for OnPlayerPickHero
local OnPlayerPickHeroEvent = CreateGameEvent('OnPlayerPickHero')
function GameMode:OnPlayerPickHero(keys)
  OnPlayerPickHeroEvent(keys)
  DebugPrint('[BAREBONES] OnPlayerPickHero')
  DebugPrintTable(keys)

  local heroClass = keys.hero
  local heroEntity = EntIndexToHScript(keys.heroindex)
  local player_index = keys.player
end

-- A player killed another player in a multi-team context
-- game event object for OnTeamKillCredit
local OnTeamKillCreditEvent = CreateGameEvent('OnTeamKillCredit')
function GameMode:OnTeamKillCredit(keys)
  OnTeamKillCreditEvent(keys)
  DebugPrint('[BAREBONES] OnTeamKillCredit')
  DebugPrintTable(keys)
end

-- game event object for OnTeamKillCredit
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

-- This function is called 1 to 2 times as the player connects initially but before they
-- have completely connected
function GameMode:PlayerConnect(keys)
  DebugPrint('[BAREBONES] PlayerConnect')
  DebugPrintTable(keys)
end

-- This function is called once when the player fully connects and becomes "Ready" during Loading
-- game event object for OnConnectFull
local OnConnectFullEvent = CreateGameEvent('OnConnectFull')
function GameMode:OnConnectFull(keys)
  OnConnectFullEvent(keys)
  DebugPrint('[BAREBONES] OnConnectFull')
  DebugPrintTable(keys)

  local index = keys.index  -- player slot
  local playerID = keys.PlayerID
  local userID = keys.userid  -- user ID on server
end

-- This function is called whenever illusions are created and tells you which was/is the original entity
-- game event object for OnIllusionsCreated
local OnIllusionsCreatedEvent = CreateGameEvent('OnIllusionsCreated')
function GameMode:OnIllusionsCreated(keys)
  OnIllusionsCreatedEvent(keys)
  DebugPrint('[BAREBONES] OnIllusionsCreated')
  DebugPrintTable(keys)

  local originalEntity = EntIndexToHScript(keys.original_entindex)
end

-- This function is called whenever an item is combined to create a new item
-- game event object for OnItemCombined
local OnItemCombinedEvent = CreateGameEvent('OnItemCombined')
function GameMode:OnItemCombined(keys)
  OnItemCombinedEvent(keys)
  DebugPrint('[BAREBONES] OnItemCombined')
  DebugPrintTable(keys)

  -- The playerID of the hero who is buying something
  local playerID = keys.PlayerID

  -- The name of the item purchased
  local itemName = keys.itemname

  -- The cost of the item purchased
  local itemcost = keys.itemcost
end

-- This function is called whenever an ability begins its PhaseStart phase (but before it is actually cast)
-- game event object for OnAbilityCastBegins
local OnAbilityCastBeginsEvent = CreateGameEvent('OnAbilityCastBegins')
function GameMode:OnAbilityCastBegins(keys)
  OnAbilityCastBeginsEvent(keys)
  DebugPrint('[BAREBONES] OnAbilityCastBegins')
  DebugPrintTable(keys)

  local playerID = keys.PlayerID
  local abilityName = keys.abilityname
end

-- This function is called whenever a tower is killed
-- game event object for OnTowerKill
local OnTowerKillEvent = CreateGameEvent('OnTowerKill')
function GameMode:OnTowerKill(keys)
  OnTowerKillEvent(keys)
  DebugPrint('[BAREBONES] OnTowerKill')
  DebugPrintTable(keys)

  local gold = keys.gold
  local team = keys.teamnumber
end

-- This function is called whenever a player changes there custom team selection during Game Setup
-- game event object for OnPlayerSelectedCustomTeam
local OnPlayerSelectedCustomTeamEvent = CreateGameEvent('OnPlayerSelectedCustomTeam')
function GameMode:OnPlayerSelectedCustomTeam(keys)
  OnPlayerSelectedCustomTeamEvent(keys)
  DebugPrint('[BAREBONES] OnPlayerSelectedCustomTeam')
  DebugPrintTable(keys)

  local playerID = keys.player_id
  local success = (keys.success == 1)
  local team = keys.team_id
end

-- This function is called whenever an NPC reaches its goal position/target
-- game event object for OnNPCGoalReached
local OnNPCGoalReachedEvent = CreateGameEvent('OnNPCGoalReached')
function GameMode:OnNPCGoalReached(keys)
  OnNPCGoalReachedEvent(keys)
  DebugPrint('[BAREBONES] OnNPCGoalReached')
  DebugPrintTable(keys)
end

-- This function is called whenever any player sends a chat message to team or All
-- game event object for OnPlayerChat
local OnPlayerChatEvent = CreateGameEvent('OnPlayerChat')
function GameMode:OnPlayerChat(keys)
  OnPlayerChatEvent(keys)
end
