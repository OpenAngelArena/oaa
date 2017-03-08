-- Taken from bb template
if Duels == nil then
  DebugPrint ( 'Creating new Duels object.' )
  Duels = class({})

  Debug.EnabledModules['duels:*'] = true
  Debug.EnabledModules['zonecontrol:*'] = true

  ChatCommand:LinkCommand("-duel", "StartDuel", Duels)
  ChatCommand:LinkCommand("-end_duel", "EndDuel", Duels)
end

function Duels:Init ()
  DebugPrint('Init duels')

  Duels.currentDuel = nil
  Duels.zone1 = ZoneControl:CreateZone('duel_1', {
    mode = ZONE_CONTROL_INCLUSIVE,
    players = {
    }
  })

  Duels.zone2 = ZoneControl:CreateZone('duel_2', {
    mode = ZONE_CONTROL_INCLUSIVE,
    players = {
    }
  })
end

function Duels:StartDuel ()
  if Duels.currentDuel then
    DebugPrint ('There is already a duel running')
  end
  -- respawn everyone
  local goodPlayerIndex = 1
  local badPlayerIndex = 1

  local goodPlayers = {}
  local badPlayers = {}

  for playerId = 0,19 do
    local player = PlayerResource:GetPlayer(playerId)
    if player ~= nil then
      DebugPrint ('Players team ' .. player:GetTeam())
      if player:GetTeam() == 3 then
        badPlayers[badPlayerIndex] = Duels:SavePlayerState(player:GetAssignedHero())
        badPlayers[badPlayerIndex].id = playerId
        badPlayerIndex = badPlayerIndex + 1

      elseif player:GetTeam() == 2 then
        goodPlayers[goodPlayerIndex] = Duels:SavePlayerState(player:GetAssignedHero())
        goodPlayers[goodPlayerIndex].id = playerId
        goodPlayerIndex = goodPlayerIndex + 1

      end

      Duels:ResetPlayerState(player:GetAssignedHero())
      -- disable respawn
      player:GetAssignedHero():SetRespawnsDisabled(true)
    end
  end

  goodPlayerIndex = goodPlayerIndex - 1
  badPlayerIndex = badPlayerIndex - 1

  -- split up players, put them in the duels
  local maxPlayers = math.min(goodPlayerIndex, badPlayerIndex)

  DebugPrint('Max players per team for this duel ' .. maxPlayers)

  if maxPlayers < 1 then
    DebugPrint('There aren\'t enough players to start the duel')
    ShowMessage('There aren\'t enough players to start the duel')
    return
  end

  local playerSplitOffset = math.random(1, maxPlayers)
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

    FindClearSpaceForUnit(goodPlayer:GetAssignedHero(), spawn1, true)
    FindClearSpaceForUnit(badPlayer:GetAssignedHero(), spawn2, true)

    Duels.zone1.addPlayer(goodGuy.id)
    Duels.zone1.addPlayer(badGuy.id)

    Duels:MoveCameraToPlayer(goodGuy.id, goodPlayer:GetAssignedHero())
    Duels:MoveCameraToPlayer(badGuy.id, badPlayer:GetAssignedHero())
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

    FindClearSpaceForUnit(goodPlayer:GetAssignedHero(), spawn1, true)
    FindClearSpaceForUnit(badPlayer:GetAssignedHero(), spawn2, true)

    Duels.zone2.addPlayer(goodGuy.id)
    Duels.zone2.addPlayer(badGuy.id)

    Duels:MoveCameraToPlayer(goodGuy.id, goodPlayer:GetAssignedHero())
    Duels:MoveCameraToPlayer(badGuy.id, badPlayer:GetAssignedHero())
  end

  Duels.currentDuel = {
    badPlayers = badPlayers,
    goodPlayers = goodPlayers,
    badPlayerIndex = badPlayerIndex,
    goodPlayerIndex = goodPlayerIndex
  }

  Timers:CreateTimer(60, Dynamic_Wrap(Duels, 'EndDuel'))
end

function Duels:MoveCameraToPlayer (playerId, entity)
  PlayerResource:SetCameraTarget(playerId, entity)

  Timers:CreateTimer(2, function ()
    PlayerResource:SetCameraTarget(playerId, nil)
  end)
end

function Duels:GetUnassignedPlayer (group, max)
  DebugPrint('max value is ' .. max)
  while true do
    local playerIndex = math.random(1, max)
    DebugPrint('Does a player exist at position ' .. playerIndex)
    if group[playerIndex].assigned == nil then
      group[playerIndex].assigned = true
      return group[playerIndex]
    end
  end
end

function Duels:EndDuel ()
  if Duels.currentDuel == nil then
    DebugPrint ('There is no duel running')
  end

  for playerId = 0,19 do
    Duels.zone1.removePlayer(playerId)
    Duels.zone2.removePlayer(playerId)
  end

  local currentDuel = Duels.currentDuel
  Duels.currentDuel = nil

  Timers:CreateTimer(1, function ()
    Duels:AllPlayers(currentDuel, function (state)
      DebugPrintTable(state)
      local player = PlayerResource:GetPlayer(state.id)
      Duels:RestorePlayerState (player:GetAssignedHero(), state)
      Duels:MoveCameraToPlayer(state.id, player)
    end)
  end)

end

function Duels:ResetPlayerState (hero)
  hero:RespawnUnit()
  hero:SetHealth(hero:GetMaxHealth())
  hero:SetMana(hero:GetMaxMana())

  for abilityIndex = 0,hero:GetAbilityCount() do
    local ability = hero:GetAbilityByIndex(abilityIndex)
    if ability ~= nil then
      ability:EndCooldown()
    end
  end
end

function Duels:SavePlayerState (hero)
  local state = {
    location = hero:GetAbsOrigin(),
    abilityCount = hero:GetAbilityCount(),
    maxAbility = 0,
    abilities = {},
    hp = hero:GetHealth(),
    mana = hero:GetMana()
  }

  for abilityIndex = 0,state.abilityCount do
    local ability = hero:GetAbilityByIndex(abilityIndex)
    if ability ~= nil then
      state.maxAbility = abilityIndex
      state.abilities[abilityIndex] = {
        cooldown = ability:GetCooldownTimeRemaining()
      }
    end
  end

  return state
end

function Duels:RestorePlayerState (hero, state)
  hero:SetAbsOrigin(state.location)
  hero:SetHealth(state.hp)
  hero:SetMana(state.mana)

  for abilityIndex = 0,state.maxAbility do
    local ability = hero:GetAbilityByIndex(abilityIndex)
    if ability ~= nil then
      ability:StartCooldown(state.abilities[abilityIndex].cooldown)
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
    DebugPrint('player index ' .. state.badPlayerIndex)
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
