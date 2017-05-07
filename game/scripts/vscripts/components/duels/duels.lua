-- Taken from bb template
if Duels == nil then
  DebugPrint ( 'Creating new Duels object.' )
  Duels = class({})
  Debug.EnabledModules['duels:duels'] = true

  ChatCommand:LinkCommand("-duel", "StartDuel", Duels)
  ChatCommand:LinkCommand("-end_duel", "EndDuel", Duels)
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

  GameEvents:OnHeroDied(function (keys)
    Duels:CheckDuelStatus(keys)
  end)

  GameEvents:OnPlayerReconnect(function (keys)
    local playerID = keys.PlayerID
    if playerID then
      local hero = PlayerResource:GetSelectedHeroEntity(playerID)
      if not Duels.currentDuel then
        hero:SetRespawnsDisabled(false)
        if not hero:IsAlive() then
         hero:RespawnHero(false, false, false)
        end
      end
    end
  end)

  Timers:CreateTimer(1, function ()
    Duels:StartDuel()
  end)
end

local DUEL_IS_STARTING = 21

function Duels:CheckDuelStatus (hero)
  if not Duels.currentDuel or Duels.currentDuel == DUEL_IS_STARTING then -- <- There is nothing here, git.
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
  local foundIt = false

  Duels:AllPlayers(Duels.currentDuel, function (player)
    if foundIt or player.id ~= playerId then
      return
    end
    foundIt = true
    local scoreIndex = player.team .. 'Living' .. player.duelNumber
    DebugPrint('Found dead player on ' .. player.team .. ' team with scoreindex ' .. scoreIndex)

    Duels.currentDuel[scoreIndex] = Duels.currentDuel[scoreIndex] - 1

    if Duels.currentDuel[scoreIndex] <= 0 then
      Duels.currentDuel['duelEnd' .. player.duelNumber] = true
      DebugPrint('Duel number ' .. scoreIndex .. ' is over and ' .. player.team .. ' lost')
    end

    if Duels.currentDuel.duelEnd1 and Duels.currentDuel.duelEnd2 then
      DebugPrint('both duels are over, resuming normal play!')
      Duels:EndDuel()
    end
  end)
end

function Duels:StartDuel ()
  if Duels.currentDuel then
    DebugPrint ('There is already a duel running')
    return
  end
  Duels.currentDuel = DUEL_IS_STARTING
  DuelPreparingEvent.broadcast(true)

  Notifications:TopToAll({text="A duel will start in 10 seconds!", duration=5.0})
  for index = 1,5 do
    Timers:CreateTimer(4 + index, function ()
      Notifications:TopToAll({text=(6 - index), duration=1.0})
    end)
  end

  Timers:CreateTimer(10, function ()
    Notifications:TopToAll({text="DUEL!", duration=3.0, style={color="red", ["font-size"]="110px"}})
    ZoneCleaner:CleanZone(Duels.zone1)
    ZoneCleaner:CleanZone(Duels.zone2)
    Duels:ActuallyStartDuel()
  end)
end

function Duels:ActuallyStartDuel ()
  -- respawn everyone
  local goodPlayerIndex = 1
  local badPlayerIndex = 1

  local goodPlayers = {}
  local badPlayers = {}

  for playerId = 0,19 do
    local player = PlayerResource:GetPlayer(playerId)
    if player ~= nil then
      DebugPrint ('Players team ' .. player:GetTeam())
      if player:GetAssignedHero() then
        if player:GetTeam() == 3 then
          badPlayers[badPlayerIndex] = Duels:SavePlayerState(player:GetAssignedHero())
          badPlayers[badPlayerIndex].id = playerId
          -- used to generate keynames like badEnd1
          -- not used in dota apis
          badPlayers[badPlayerIndex].team = 'bad'
          badPlayerIndex = badPlayerIndex + 1

        elseif player:GetTeam() == 2 then
          goodPlayers[goodPlayerIndex] = Duels:SavePlayerState(player:GetAssignedHero())
          goodPlayers[goodPlayerIndex].id = playerId
          goodPlayers[goodPlayerIndex].team = 'good'
          goodPlayerIndex = goodPlayerIndex + 1
        end

        Duels:ResetPlayerState(player:GetAssignedHero())
      end
    end
  end

  goodPlayerIndex = goodPlayerIndex - 1
  badPlayerIndex = badPlayerIndex - 1

  -- split up players, put them in the duels
  local maxPlayers = math.min(goodPlayerIndex, badPlayerIndex)

  DebugPrint('Max players per team for this duel ' .. maxPlayers)

  if maxPlayers < 1 then
    DebugPrint('There aren\'t enough players to start the duel')
    Notifications:TopToAll({text="There aren\'t enough players to start the duel", duration=2.0})
    return
  end

  local playerSplitOffset = math.random(0, maxPlayers)
  -- local playerSplitOffset = maxPlayers
  local spawnLocations = math.random(0, 1) == 1
  local spawn1 = Entities:FindByName(nil, 'duel_1_spawn_1'):GetAbsOrigin()
  local spawn2 = Entities:FindByName(nil, 'duel_1_spawn_2'):GetAbsOrigin()

  if spawnLocations then
    local tmp = spawn1
    spawn1 = spawn2
    spawn2 = tmp
  end

  for playerNumber = 1,playerSplitOffset do
    DebugPrint('Checking player number ' .. playerNumber)
    local goodGuy = Duels:GetUnassignedPlayer(goodPlayers, goodPlayerIndex)
    local badGuy = Duels:GetUnassignedPlayer(badPlayers, badPlayerIndex)
    local goodPlayer = PlayerResource:GetPlayer(goodGuy.id)
    local badPlayer = PlayerResource:GetPlayer(badGuy.id)
    local goodHero = goodPlayer:GetAssignedHero()
    local badHero = badPlayer:GetAssignedHero()

    goodGuy.duelNumber = 1
    badGuy.duelNumber = 1

    self:SafeTeleport(goodHero, spawn1, 150)
    self:SafeTeleport(badHero, spawn2, 150)
    --FindClearSpaceForUnit(goodHero, spawn1, true)
    --FindClearSpaceForUnit(badHero, spawn2, true)


    Duels.zone1.addPlayer(goodGuy.id)
    Duels.zone1.addPlayer(badGuy.id)

    Duels:MoveCameraToPlayer(goodGuy.id, goodHero)
    Duels:MoveCameraToPlayer(badGuy.id, badHero)

    -- stop player action
    goodHero:Stop()
    badHero:Stop()

    -- disable respawn
    goodHero:SetRespawnsDisabled(true)
    badHero:SetRespawnsDisabled(true)
  end

  spawn1 = Entities:FindByName(nil, 'duel_2_spawn_1'):GetAbsOrigin()
  spawn2 = Entities:FindByName(nil, 'duel_2_spawn_2'):GetAbsOrigin()

  if spawnLocations then
    local tmp = spawn1
    spawn1 = spawn2
    spawn2 = tmp
  end

  for playerNumber = playerSplitOffset+1,maxPlayers do
    DebugPrint('Checking player number ' .. playerNumber)
    local goodGuy = Duels:GetUnassignedPlayer(goodPlayers, goodPlayerIndex)
    local badGuy = Duels:GetUnassignedPlayer(badPlayers, badPlayerIndex)
    local goodPlayer = PlayerResource:GetPlayer(goodGuy.id)
    local badPlayer = PlayerResource:GetPlayer(badGuy.id)
    local goodHero = goodPlayer:GetAssignedHero()
    local badHero = badPlayer:GetAssignedHero()

    goodGuy.duelNumber = 2
    badGuy.duelNumber = 2

    FindClearSpaceForUnit(goodHero, spawn1, true)
    FindClearSpaceForUnit(badHero, spawn2, true)

    Duels.zone2.addPlayer(goodGuy.id)
    Duels.zone2.addPlayer(badGuy.id)

    Duels:MoveCameraToPlayer(goodGuy.id, goodHero)
    Duels:MoveCameraToPlayer(badGuy.id, badHero)

    -- stop player action
    goodHero:Stop()
    badHero:Stop()

    -- disable respawn
    goodHero:SetRespawnsDisabled(true)
    badHero:SetRespawnsDisabled(true)
  end

  Duels.currentDuel = {
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
  DuelStartEvent.broadcast(Duels.currentDuel)

  Timers:CreateTimer(90, Dynamic_Wrap(Duels, 'EndDuel'))
end

function Duels:MoveCameraToPlayer (playerId, entity)
  PlayerResource:SetCameraTarget(playerId, entity)

  Timers:CreateTimer(1, function ()
    PlayerResource:SetCameraTarget(playerId, nil)
  end)
end

function Duels:GetUnassignedPlayer (group, max)
  while true do
    local playerIndex = math.random(1, max)
    if group[playerIndex].assigned == nil then
      group[playerIndex].assigned = true
      return group[playerIndex]
    end
  end
end

function Duels:EndDuel ()
  if Duels.currentDuel == nil then
    DebugPrint ('There is no duel running')
    return
  end

  DebugPrint('Duel has ended')

  local nextDuelIn = 300
  -- why dont these run?
  Timers:CreateTimer(nextDuelIn, Dynamic_Wrap(Duels, 'StartDuel'))
  Timers:CreateTimer(nextDuelIn - 50, function ()
    Notifications:TopToAll({text="A duel will start in 1 minute!", duration=10.0})
  end)

  for playerId = 0,19 do
    Duels.zone1.removePlayer(playerId, false)
    Duels.zone2.removePlayer(playerId, false)
  end

  local currentDuel = Duels.currentDuel
  Duels.currentDuel = nil

  Timers:CreateTimer(0.1, function ()
    Duels:AllPlayers(currentDuel, function (state)
      -- DebugPrintTable(state)
      DebugPrint('Is this a player id? ' .. state.id)
      local player = PlayerResource:GetPlayer(state.id)
      if player == nil then -- disconnected!
        return
      end

      local hero = player:GetAssignedHero()
      if not hero:IsAlive() then
        hero:SetRespawnsDisabled(false)
        hero:RespawnHero(false,false,false)
      end

      if not state.assigned then
        return
      end

      Duels:RestorePlayerState (hero, state)
      Duels:MoveCameraToPlayer(state.id, hero)
    end)
    DuelEndEvent.broadcast(true)
  end)
end

function Duels:ResetPlayerState (hero)
  if not hero:IsAlive() then
    hero:RespawnHero(false,false,false)
  end

  hero:SetHealth(hero:GetMaxHealth())
  hero:SetMana(hero:GetMaxMana())

  -- Reset cooldown for abilities
  for abilityIndex = 0, hero:GetAbilityCount() - 1 do
    local ability = hero:GetAbilityByIndex(abilityIndex)
    if ability ~= nil then
      ability:EndCooldown()
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
    hp = hero:GetHealth(),
    mana = hero:GetMana()
  }

  -- If hero is dead during start of the duel, make his saved location his foutain area
  if hero:IsAlive() == false then
    if hero:GetTeam() == DOTA_TEAM_GOODGUYS then
        state.location = Vector(-5221.958496, -139.014923, 387.999023)
    else
        state.location = Vector(4908.748047, -91.460907, 392.000000)
    end
  end

  for abilityIndex = 0,hero:GetAbilityCount()-1 do
    local ability = hero:GetAbilityByIndex(abilityIndex)
    if ability ~= nil then
      state.abilities[abilityIndex] = {
        cooldown = ability:GetCooldownTimeRemaining()
      }
    end
  end

  for itemIndex = DOTA_ITEM_SLOT_1, DOTA_ITEM_SLOT_6 do
    local item = hero:GetItemInSlot(itemIndex)
    if item ~= nil then
      state.items[itemIndex] = {
        cooldown = item:GetCooldownTimeRemaining()
      }
    end
  end
  return state
end

function Duels:RestorePlayerState (hero, state)
  hero:SetAbsOrigin(state.location)
  if state.hp > 0 then
    hero:SetHealth(state.hp)
  end
  hero:SetMana(state.mana)

  for abilityIndex = 0, hero:GetAbilityCount() - 1 do
    local ability = hero:GetAbilityByIndex(abilityIndex)
    if ability ~= nil then
      if state.abilities[abilityIndex] == nil then
        DebugPrint('Why is this ability broken?' .. abilityIndex)
        DebugPrintTable(state)
      else
        ability:StartCooldown(state.abilities[abilityIndex].cooldown)
      end
    end
  end

  for itemIndex = DOTA_ITEM_SLOT_1, DOTA_ITEM_SLOT_6 do
    local item = hero:GetItemInSlot(itemIndex)
    if item ~= nil and state.items[itemIndex] then
      item:StartCooldown(state.items[itemIndex].cooldown)
    end
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

function Duels:SafeTeleport(unit, location, maxDistance)
  FindClearSpaceForUnit(unit, location, true)
  local distance = (location - unit:GetAbsOrigin()):Length2D()
  if distance > maxDistance then
    Timers:CreateTimer(0.1, function()
      self:SafeTeleport(unit, location, maxDistance)
    end)
  end
end
