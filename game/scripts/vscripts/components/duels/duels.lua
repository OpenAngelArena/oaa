LinkLuaModifier('modifier_offside', 'modifiers/modifier_offside.lua', LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_out_of_duel", "modifiers/modifier_out_of_duel.lua", LUA_MODIFIER_MOTION_NONE)

DUEL_IS_STARTING = 21

-- Taken from bb template
if Duels == nil then
  DebugPrint ( 'Creating new Duels object.' )
  Duels = class({})
  Debug.EnabledModules['duels:duels'] = true
end

--[[
 TODO: Refactor this file into a few modules so that there's less of a wall of code here
]]

local DuelPreparingEvent = Event()
local DuelStartEvent = Event()
local DuelEndEvent = Event()

Duels.onStart = DuelStartEvent.listen
Duels.onPreparing = DuelPreparingEvent.listen
Duels.onEnd = DuelEndEvent.listen

local function RefreshAbilityFilter (ability)
  return ability:GetAbilityType() ~= 1
end

function Duels:Init ()
  DebugPrint('Init duels')

  Duels.currentDuel = nil
  Duels.zone1 = ZoneControl:CreateZone('duel_1', {
    mode = ZONE_CONTROL_INCLUSIVE,
    margin = 500,
    padding = 200,
    players = {
    }
  })

  Duels.zone2 = ZoneControl:CreateZone('duel_2', {
    mode = ZONE_CONTROL_INCLUSIVE,
    margin = 500,
    padding = 200,
    players = {
    }
  })

  Duels.zone3 = ZoneControl:CreateZone('duel_3', {
    mode = ZONE_CONTROL_INCLUSIVE,
    margin = 500,
    padding = 200,
    players = {
    }
  })

  Duels.zone4 = ZoneControl:CreateZone('duel_4', {
    mode = ZONE_CONTROL_INCLUSIVE,
    margin = 500,
    padding = 200,
    players = {
    }
  })

  GameEvents:OnHeroDied(function (keys)
    Duels:CheckDuelStatus(keys)
  end)

  GameEvents:OnPlayerReconnect(function (keys)
-- [VScript] [components\duels\duels:64] PlayerID: 1
-- [VScript] [components\duels\duels:64] name: Minnakht
-- [VScript] [components\duels\duels:64] networkid: [U:1:53917791]
-- [VScript] [components\duels\duels:64] reason: 2
-- [VScript] [components\duels\duels:64] splitscreenplayer: -1
-- [VScript] [components\duels\duels:64] userid: 3
-- [VScript] [components\duels\duels:64] xuid: 76561198014183519
    local playerID = keys.PlayerID
    if playerID then
      local hero = PlayerResource:GetSelectedHeroEntity(playerID)
      if hero and not Duels.currentDuel then
        hero:SetRespawnsDisabled(false)
        if hero:IsAlive() then
          hero:RemoveModifierByName("modifier_out_of_duel")
        else
          hero:RespawnHero(false, false)
        end
      end

      if not Duels:IsActive() then
        return
      end

      local player = Duels:PlayerForDuel(playerID)
      if not player or not player.assigned or not player.duelNumber then
        -- player is not in a duel, they can just chill tf out
        return
      end
      player.disconnected = false
      if player.killed or not player.disconnected then
        return
      end

      Duels:UnCountPlayerDeath(player)
    end
  end)

  GameEvents:OnPlayerDisconnect(function(keys)
-- [VScript] [components\duels\duels:48] PlayerID: 1
-- [VScript] [components\duels\duels:48] splitscreenplayer: -1
    local playerID = keys.PlayerID
    if playerID then
      local hero = PlayerResource:GetSelectedHeroEntity(playerID)
      if hero then
        hero:Stop()
        hero:AddNewModifier(nil, nil, "modifier_out_of_duel", nil)
      end

      if not Duels:IsActive() then
        return
      end

      local player = Duels:PlayerForDuel(playerID)
      if not player or not player.assigned or not player.duelNumber then
        -- player is not in a duel, they can just chill tf out
        return
      end
      player.disconnected = true
      if player.killed then
        return
      end

      Duels:CountPlayerDeath(player)
    end
  end)

  Timers:CreateTimer(INITIAL_DUEL_DELAY, function ()
    Duels:StartDuel({
      players = 5,
      firstDuel = true,
      timeout = FIRST_DUEL_TIMEOUT
    })
  end)

  ChatCommand:LinkCommand("-duel", Dynamic_Wrap(Duels, "StartDuel"), Duels)
  ChatCommand:LinkCommand("-end_duel", Dynamic_Wrap(Duels, "EndDuel"), Duels)
  ChatCommand:LinkCommand("-tptest", Dynamic_Wrap(Duels, "TestSafeTeleport"), Duels)
  ChatCommand:LinkCommand("-tpstate", Dynamic_Wrap(Duels, "TestSaveAndLoadState"), Duels)
end

function Duels:CountPlayerDeath (player)
  local scoreIndex = player.team .. 'Living' .. player.duelNumber
  Duels.currentDuel[scoreIndex] = Duels.currentDuel[scoreIndex] - 1

  if Duels.currentDuel[scoreIndex] <= 0 then
    Duels.currentDuel['duelEnd' .. player.duelNumber] = player.team
    DebugPrint('Duel number ' .. scoreIndex .. ' is over and ' .. player.team .. ' lost')
    local winningTeam = "bad"
    if player.team == "bad" then
      winningTeam = "good"
    end

    Duels:AllPlayers(Duels.currentDuel, function (otherPlayer)
      if player.duelNumber ~= otherPlayer.duelNumber then
        return
      end
      Notifications:Top(otherPlayer.id, {
        text = "#DOTA_Winner_" .. winningTeam .. "Guys",
        duration = 5.0,
        style = {
          color = "red",
          ["font-size"] = "110px"
        }
      })
    end)


  end

  if Duels.currentDuel.duelEnd1 and Duels.currentDuel.duelEnd2 then
    DebugPrint('both duels are over, resuming normal play!')
    Duels:EndDuel()
  end
end

function Duels:UnCountPlayerDeath (player)
  local scoreIndex = player.team .. 'Living' .. player.duelNumber
  Duels.currentDuel[scoreIndex] = Duels.currentDuel[scoreIndex] + 1
end

function Duels:IsActive ()
  if not Duels.currentDuel or Duels.currentDuel == DUEL_IS_STARTING then
    return false
  end
  return true
end
function Duels:CheckDuelStatus (hero)
  if not Duels:IsActive() then
    return
  end
  if hero:IsReincarnating() then
    hero:SetRespawnsDisabled(false)
    Timers:CreateTimer(1, function ()
      hero:SetRespawnsDisabled(true)
    end )
    return
  end

  local playerId = hero:GetPlayerOwnerID()

  local player = Duels:PlayerForDuel(playerId)
  if not player then
    -- player is not in this duel!
    return
  end

  if not player.assigned or not player.duelNumber then
    DebugPrint('Player died who isnt in a duel?')
    DebugPrintTable(Duels.currentDuel)
    DebugPrintTable(player)
    return
  end

  if player.killed then
    -- this player is already dead and shouldn't be counted again
    -- this shouldn't happen, but is nice to have here for future use cases of this method
    DebugPrint('Player died twice in duel?')
    DebugPrintTable(Duels.currentDuel)
    DebugPrintTable(player)
    return
  end

  if not player.disconnected then
    player.killed = true
  end

  Duels:CountPlayerDeath(player)
end

function Duels:StartDuel (options)
  if Duels.currentDuel then
    DebugPrint ('There is already a duel running')
    return
  end
  options = options or {}
  if not options.firstDuel then
    Music:SetMusic(12)
  end
  Timers:RemoveTimer('EndDuel')
  Duels.currentDuel = DUEL_IS_STARTING
  DuelPreparingEvent.broadcast(true)

  Notifications:TopToAll({text="#duel_imminent_warning", duration=math.min(DUEL_START_WARN_TIME, 5.0), replacement_map={seconds_to_duel = DUEL_START_WARN_TIME}})
  for index = 0,(DUEL_START_COUNTDOWN - 1) do
    Timers:CreateTimer(DUEL_START_WARN_TIME - DUEL_START_COUNTDOWN + index, function ()
      Notifications:TopToAll({text=(DUEL_START_COUNTDOWN - index), duration=1.0})
    end)
  end

  Timers:CreateTimer(DUEL_START_WARN_TIME, function ()
    Notifications:TopToAll({text="#duel_start", duration=3.0, style={color="red", ["font-size"]="110px"}})
    ZoneCleaner:CleanZone(Duels.zone1)
    ZoneCleaner:CleanZone(Duels.zone2)
    ZoneCleaner:CleanZone(Duels.zone3)
    ZoneCleaner:CleanZone(Duels.zone4)
    Duels:ActuallyStartDuel(options)
  end)
end

function Duels:ActuallyStartDuel (options)
  -- respawn everyone
  local goodPlayerIndex = 1
  local badPlayerIndex = 1
  local validGoodPlayerIndex = 1
  local validBadPlayerIndex = 1

  local goodPlayers = {}
  local badPlayers = {}

  for playerId = 0,19 do
    local player = PlayerResource:GetPlayer(playerId)
    if player ~= nil then
      if player:GetAssignedHero() then
        if player:GetTeam() == DOTA_TEAM_BADGUYS then
          badPlayers[badPlayerIndex] = self:SavePlayerState(player:GetAssignedHero())
          badPlayers[badPlayerIndex].id = playerId
          -- used to generate keynames like badEnd1
          -- not used in dota apis
          badPlayers[badPlayerIndex].team = 'bad'
          badPlayerIndex = badPlayerIndex + 1
          validBadPlayerIndex = validBadPlayerIndex + 1

        elseif player:GetTeam() == DOTA_TEAM_GOODGUYS then
          goodPlayers[goodPlayerIndex] = self:SavePlayerState(player:GetAssignedHero())
          goodPlayers[goodPlayerIndex].id = playerId
          goodPlayers[goodPlayerIndex].team = 'good'
          goodPlayerIndex = goodPlayerIndex + 1
          validGoodPlayerIndex = validGoodPlayerIndex + 1
        end

        self:ResetPlayerState(player:GetAssignedHero())
      end
    else
      local hero = PlayerResource:GetSelectedHeroEntity(playerId)
      local function CreateDisonnectedPlayer ()
        return {
          assignable = false
        }
      end
      if hero ~= nil then
        if PlayerResource:GetTeam(playerId) == DOTA_TEAM_BADGUYS then
          badPlayers[badPlayerIndex] = CreateDisonnectedPlayer()
          badPlayers[badPlayerIndex].id = playerId
          badPlayers[badPlayerIndex].team = 'bad'
          badPlayerIndex = badPlayerIndex + 1
        elseif PlayerResource:GetTeam(playerId) == DOTA_TEAM_GOODGUYS then
          goodPlayers[goodPlayerIndex] = CreateDisonnectedPlayer()
          goodPlayers[goodPlayerIndex].id = playerId
          goodPlayers[goodPlayerIndex].team = 'good'
          goodPlayerIndex = goodPlayerIndex + 1
        end
      end
    end
  end

  goodPlayerIndex = goodPlayerIndex - 1
  badPlayerIndex = badPlayerIndex - 1
  validGoodPlayerIndex = validGoodPlayerIndex - 1
  validBadPlayerIndex = validBadPlayerIndex - 1

  -- split up players, put them in the duels
  local maxPlayers = math.min(validGoodPlayerIndex, validBadPlayerIndex)

  DebugPrint('Max players per team for this duel ' .. maxPlayers)

  if maxPlayers < 1 then
    DebugPrint('There aren\'t enough players to start the duel')
    Notifications:TopToAll({text="#duel_not_enough_players", duration=2.0})
    self.currentDuel = nil
    Music:PlayBackground(1, 7)
    return
  end

  Music:SetMusic(13)

  local playerSplitOffset = RandomInt(0, maxPlayers)
  if options.players then
    playerSplitOffset = math.min(options.players, maxPlayers)
  end
  -- local playerSplitOffset = maxPlayers
  local spawnLocations = RandomInt(0, 1) == 1
  local arenaChoice = RandomInt(0, 1) == 1
  local duel_1 = 'duel_1'
  local duel_2 = 'duel_2'
  if arenaChoice then
    duel_1 = 'duel_3'
  end
  local spawn1 = Entities:FindByName(nil, duel_1 .. '_spawn_1'):GetAbsOrigin()
  local spawn2 = Entities:FindByName(nil, duel_1 .. '_spawn_2'):GetAbsOrigin()

  if spawnLocations then
    local tmp = spawn1
    spawn1 = spawn2
    spawn2 = tmp
  end

  for playerNumber = 1,playerSplitOffset do
    DebugPrint('Adding player number ' .. playerNumber)
    local goodGuy = self:GetUnassignedPlayer(goodPlayers, goodPlayerIndex)
    local badGuy = self:GetUnassignedPlayer(badPlayers, badPlayerIndex)
    local goodPlayer = PlayerResource:GetPlayer(goodGuy.id)
    local badPlayer = PlayerResource:GetPlayer(badGuy.id)
    local goodHero = goodPlayer:GetAssignedHero()
    local badHero = badPlayer:GetAssignedHero()

    goodGuy.duelNumber = 1
    badGuy.duelNumber = 1

    self:SafeTeleportAll(goodHero, spawn1, 150)
    self:SafeTeleportAll(badHero, spawn2, 150)

    if arenaChoice then
      self.zone3.addPlayer(goodGuy.id)
      self.zone3.addPlayer(badGuy.id)
    else
      self.zone1.addPlayer(goodGuy.id)
      self.zone1.addPlayer(badGuy.id)
    end

    MoveCameraToPlayer(goodHero)
    MoveCameraToPlayer(badHero)

    -- stop player action
    goodHero:Stop()
    badHero:Stop()

    -- disable respawn
    goodHero:SetRespawnsDisabled(true)
    badHero:SetRespawnsDisabled(true)
  end

  spawnLocations = RandomInt(0, 1) == 1
  arenaChoice = RandomInt(0, 1) == 1
  if arenaChoice then
    duel_2 = 'duel_4'
  end

  spawn1 = Entities:FindByName(nil, duel_2 .. '_spawn_1'):GetAbsOrigin()
  spawn2 = Entities:FindByName(nil, duel_2 .. '_spawn_2'):GetAbsOrigin()

  if spawnLocations then
    local tmp = spawn1
    spawn1 = spawn2
    spawn2 = tmp
  end

  for playerNumber = playerSplitOffset+1,maxPlayers do
    DebugPrint('Adding player number ' .. playerNumber)
    local goodGuy = self:GetUnassignedPlayer(goodPlayers, goodPlayerIndex)
    local badGuy = self:GetUnassignedPlayer(badPlayers, badPlayerIndex)
    local goodPlayer = PlayerResource:GetPlayer(goodGuy.id)
    local badPlayer = PlayerResource:GetPlayer(badGuy.id)
    local goodHero = goodPlayer:GetAssignedHero()
    local badHero = badPlayer:GetAssignedHero()

    goodGuy.duelNumber = 2
    badGuy.duelNumber = 2

    self:SafeTeleportAll(goodHero, spawn1, 150)
    self:SafeTeleportAll(badHero, spawn2, 150)

    if arenaChoice then
      self.zone4.addPlayer(goodGuy.id)
      self.zone4.addPlayer(badGuy.id)
    else
      self.zone2.addPlayer(goodGuy.id)
      self.zone2.addPlayer(badGuy.id)
    end

    MoveCameraToPlayer(goodHero)
    MoveCameraToPlayer(badHero)

    -- stop player action
    goodHero:Stop()
    badHero:Stop()

    -- disable respawn
    goodHero:SetRespawnsDisabled(true)
    badHero:SetRespawnsDisabled(true)
  end

  for _,player in ipairs(badPlayers) do
    if player.assigned == nil then
      local hero = PlayerResource:GetSelectedHeroEntity(player.id)
      hero:Stop()
      hero:AddNewModifier(nil, nil, "modifier_out_of_duel", nil)
    end
  end
  for _,player in ipairs(goodPlayers) do
    if player.assigned == nil then
      local hero = PlayerResource:GetSelectedHeroEntity(player.id)
      hero:Stop()
      hero:AddNewModifier(nil, nil, "modifier_out_of_duel", nil)
    end
  end

  self.currentDuel = {
    goodLiving1 = playerSplitOffset,
    badLiving1 = playerSplitOffset,
    goodLiving2 = maxPlayers - playerSplitOffset,
    badLiving2 = maxPlayers - playerSplitOffset,
    duelEnd1 = playerSplitOffset == 0,
    duelEnd2 = maxPlayers == playerSplitOffset,
    badPlayers = badPlayers,
    goodPlayers = goodPlayers,
    badPlayerIndex = badPlayerIndex,
    goodPlayerIndex = goodPlayerIndex
  }
  DuelStartEvent.broadcast(self.currentDuel)

  if options.timeout == nil then
    options.timeout = DUEL_TIMEOUT
  end

  if options.timeout ~= 0 then
    Timers:CreateTimer('EndDuel', {
      endTime = options.timeout,
      callback = function()
        Duels:TimeoutDuel()
      end
    })
  end
end

function Duels:GetUnassignedPlayer (group, max)
  while true do
    local playerIndex = RandomInt(1, max)
    if group[playerIndex].assignable and group[playerIndex].assigned == nil then
      group[playerIndex].assigned = true
      return group[playerIndex]
    end
  end
end

function Duels:TimeoutDuel ()
  if self.currentDuel == nil then
    DebugPrint ('There is no duel running')
    return
  end

  DebugPrint('timing out the duel because this isnt going well...')
  Timers:RemoveTimer('EndDuel')

  for i = 0,(DUEL_END_COUNTDOWN - 1) do
    Timers:CreateTimer(i, function ()
      if self.currentDuel == nil then
        return
      end
      Notifications:TopToAll({text=tostring(DUEL_END_COUNTDOWN - i), duration=1.0})
    end)
  end

  Timers:CreateTimer('EndDuel', {
    endTime = DUEL_END_COUNTDOWN,
    callback = function()
      Duels:EndDuel()
    end
  })
end

function Duels:EndDuel ()
  if self.currentDuel == nil then
    DebugPrint ('There is no duel running')
    return
  end

  DebugPrint('Duel has ended')
  Timers:RemoveTimer('EndDuel')

  Music:PlayBackground(1, 7)

  local nextDuelIn = DUEL_INTERVAL
  -- why dont these run?
  Timers:CreateTimer(nextDuelIn, Dynamic_Wrap(Duels, 'StartDuel'))
  Timers:CreateTimer(nextDuelIn - 60 + DUEL_START_WARN_TIME, function ()
    Notifications:TopToAll({text="#duel_minute_warning", duration=10.0})
  end)

  for playerId = 0,19 do
    self.zone1.removePlayer(playerId, false)
    self.zone2.removePlayer(playerId, false)
    self.zone3.removePlayer(playerId, false)
    self.zone4.removePlayer(playerId, false)
  end

  local currentDuel = self.currentDuel
  self.currentDuel = nil

  Timers:CreateTimer(0.1, function ()
    DebugPrint('Sending all players back!')
    self:AllPlayers(currentDuel, function (state)
      local player = PlayerResource:GetPlayer(state.id)
      if player == nil then -- disconnected!
        return
      end

      local hero = player:GetAssignedHero()
      if not hero:IsAlive() then
        hero:SetRespawnsDisabled(false)
        hero:RespawnHero(false,false)
      else
        hero:RemoveModifierByName("modifier_out_of_duel")
      end

      if not state.assigned then
        return
      end

      self:RestorePlayerState (hero, state)
      MoveCameraToPlayer(hero)
      self:PurgeAfterDuel(hero)
    end)
    -- Remove Modifier
    for playerId = 0,19 do
      local player = PlayerResource:GetPlayer(playerId)
      if player then
        local hero = PlayerResource:GetSelectedHeroEntity(playerId)

        if hero ~= nil then
          hero:RemoveModifierByName("modifier_out_of_duel")
        end
      end
    end
    DuelEndEvent.broadcast(currentDuel)
  end)
end

function Duels:PurgeAfterDuel (hero)
  local modifierList = {
    "modifier_rune_haste",
    "modifier_rune_doubledamage",
    "modifier_rune_invis",
    "modifier_rune_hill_tripledamage",
  }
  for _,modifierName in ipairs(modifierList) do
    local modifier = hero:FindModifierByName(modifierName)
    if modifier then
      modifier:Destroy()
    end
  end
end

function Duels:ResetPlayerState (hero)
  if hero:HasModifier("modifier_skeleton_king_reincarnation_scepter_active") then
    hero:RemoveModifierByName("modifier_skeleton_king_reincarnation_scepter_active")
  end
  if hero:HasModifier("modifier_offside") then
    hero:RemoveModifierByName("modifier_offside")
  end
  if hero:HasModifier("modifier_is_in_offside") then
    hero:RemoveModifierByName("modifier_is_in_offside")
  end

  if not hero:IsAlive() then
    hero:RespawnHero(false,false)
  end

  hero:SetHealth(hero:GetMaxHealth())
  hero:SetMana(hero:GetMaxMana())

  -- Reset cooldown for abilities
  for abilityIndex = 0, hero:GetAbilityCount() - 1 do
    local ability = hero:GetAbilityByIndex(abilityIndex)
    if ability ~= nil and RefreshAbilityFilter(ability) then
      ability:EndCooldown()
      ability:RefreshCharges()
    end
  end

  -- Reset cooldown for items
  for i = DOTA_ITEM_SLOT_1, DOTA_ITEM_SLOT_6 do
    local item = hero:GetItemInSlot(i)
    if item  then
      item:EndCooldown()
    end
  end
end

function Duels:SavePlayerState (hero)
  local state = {
    location = hero:GetAbsOrigin(),
    abilityCount = hero:GetAbilityCount(),
    abilities = {},
    items = {},
    modifiers = {},
    offsidesStacks = 0,
    hp = hero:GetHealth(),
    mana = hero:GetMana(),
    assignable = true -- basically just for for clearer code
  }

  -- If hero is dead during start of the duel, make his saved location his foutain area
  if hero:IsAlive() == false then
    if hero:GetTeam() == DOTA_TEAM_GOODGUYS then
        state.location = Vector(-5221.958496, -139.014923, 387.999023)
    else
        state.location = Vector(4908.748047, -91.460907, 392.000000)
    end
  else
    -- hero is alive, lets check for offsides protection aura
    local modifier = hero:FindModifierByName("modifier_offside")
    if modifier then
      state.offsidesStacks = modifier:GetStackCount()
    end
  end

  for abilityIndex = 0,hero:GetAbilityCount()-1 do
    local ability = hero:GetAbilityByIndex(abilityIndex)
    if ability ~= nil and RefreshAbilityFilter(ability) then
      state.abilities[abilityIndex] = {
        cooldown = ability:GetCooldownTimeRemaining()
      }
    end
  end

  local function last()
    return true
  end
  local restoreItems = last

  for itemIndex = DOTA_ITEM_SLOT_1, DOTA_ITEM_SLOT_6 do
    local item = hero:GetItemInSlot(itemIndex)
    if item ~= nil then
      local itemCooldown = item:GetCooldownTimeRemaining()
      local lastRestore = restoreItems
      restoreItems = function()
        if not item:IsNull() then
          item:EndCooldown()
          item:StartCooldown(itemCooldown)
        end
        return lastRestore()
      end
    end
  end
  state.items = restoreItems
  return state
end

function Duels:RestorePlayerState (hero, state)
  self:SafeTeleportAll(hero, state.location, 150)

  if state.hp > 0 then
    hero:SetHealth(state.hp)
  end
  hero:SetMana(state.mana)

  for abilityIndex = 0, hero:GetAbilityCount() - 1 do
    local ability = hero:GetAbilityByIndex(abilityIndex)
    if ability ~= nil and RefreshAbilityFilter(ability) then
      if state.abilities[abilityIndex] == nil then
        DebugPrint('Why is this ability broken?' .. abilityIndex)
        DebugPrintTable(state)
      else
        ability:EndCooldown()
        ability:StartCooldown(state.abilities[abilityIndex].cooldown)
      end
    end
  end

  state.items()

  if state.offsidesStacks > 0 then
    local modifier = hero:AddNewModifier(hero, nil, "modifier_offside", {})
    modifier:SetStackCount(state.offsidesStacks)
  end
end

function Duels:AllPlayers (state, cb)
  if state == nil then
    for playerId = 0,19 do
      local player = PlayerResource:GetPlayer(playerId)
      if player ~= nil then
        cb(player)
      end
    end
  else
    for playerIndex = 1,state.badPlayerIndex do
      if state.badPlayers[playerIndex] ~= nil then
        cb(state.badPlayers[playerIndex])
      end
    end
    for playerIndex = 1,state.goodPlayerIndex do
      if state.goodPlayers[playerIndex] ~= nil then
        cb(state.goodPlayers[playerIndex])
      end
    end
  end
end

function Duels:PlayerForDuel (playerId)
  local foundIt = false

  Duels:AllPlayers(Duels.currentDuel, function (player)
    if foundIt or player.id ~= playerId then
      return
    end
    foundIt = player
  end)

  return foundIt
end

function Duels:SafeTeleportAll(owner, location, maxDistance)
  self:SafeTeleport(owner, location, maxDistance)
  local children = FindUnitsInRadius(owner:GetTeam(),
                                     owner:GetAbsOrigin(),
                                     nil,
                                     FIND_UNITS_EVERYWHERE,
                                     DOTA_UNIT_TARGET_TEAM_FRIENDLY,
                                     bit.bor(DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_BASIC),
                                     DOTA_UNIT_TARGET_FLAG_PLAYER_CONTROLLED,
                                     FIND_ANY_ORDER,
                                     false)
  for _,child in pairs(children) do
    if child:HasMovementCapability() then
      if child:GetPlayerOwner() == owner:GetPlayerOwner() then
        self:SafeTeleport(child, location, maxDistance)
      end
    end
  end
end

function Duels:SafeTeleport(unit, location, maxDistance)
  if unit:FindModifierByName("modifier_life_stealer_infest") then
    DebugPrint("Found LS infesting.")
    local ability = assert(unit:FindAbilityByName("life_stealer_consume"), 'Missing Ability "life_stealer_consume"')
    assert(ability:IsActivated(), 'Ability is not activated')
    ExecuteOrderFromTable({
      UnitIndex = unit:entindex(),
      OrderType = DOTA_UNIT_ORDER_CAST_NO_TARGET,
      AbilityIndex = ability:entindex(), --Optional.  Only used when casting abilities
      Queue = 0 --Optional.  Used for queueing up abilities
    })
  end
  if unit:IsOutOfGame() then
    unit:RemoveModifierByName("modifier_obsidian_destroyer_astral_imprisonment_prison")
  end
  location = GetGroundPosition(location, unit)
  FindClearSpaceForUnit(unit, location, true)
  Timers:CreateTimer(0.1, function()
    local distance = (location - unit:GetAbsOrigin()):Length2D()
    if distance > maxDistance then
      self:SafeTeleport(unit, location, maxDistance + 100)
    end
  end)
end

-- Test Duels:SafeTeleport function
function Duels:TestSafeTeleport(keys)
  local hero = PlayerResource:GetSelectedHeroEntity(keys.playerid)
  self:SafeTeleportAll(hero, Vector(0, 0, 0), 150)
end

function Duels:TestSaveAndLoadState(keys)
  local hero = PlayerResource:GetSelectedHeroEntity(keys.playerid)
  local state = self:SavePlayerState(hero)
  state.location = Vector(0, 0, 0)
  self:RestorePlayerState(hero,state)
end
