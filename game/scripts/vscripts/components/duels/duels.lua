local HeroState = require("components/duels/savestate")
local SafeTeleportAll = require("components/duels/teleport").SafeTeleportAll

DUEL_IS_STARTING = 21

Duels = Duels or {}
local zoneNames = {
  "duel_1", -- small arena
  "duel_2", -- small arena
  "duel_3",
  "duel_4",
  "duel_5",
  "duel_6",
  "duel_7",
  "duel_8",
}

local DuelPreparingEvent = Event()
local DuelStartEvent = Event()
local DuelEndEvent = Event()

Duels.onStart = DuelStartEvent.listen
Duels.onPreparing = DuelPreparingEvent.listen
Duels.onEnd = DuelEndEvent.listen

function Duels:Init ()
  self.moduleName = "Duels"
  self.currentDuel = nil
  self.allowExperienceGain = 0 -- 0 is no; 1 is yes; 2 is first duel (special no)
  iter(zoneNames):foreach(partial(self.RegisterZone, self))

  GameEvents:OnHeroKilled(function (keys)
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
        --hero:SetRespawnsDisabled(false)
        if hero:IsAlive() then
          hero:RemoveModifierByName("modifier_out_of_duel")
        else
          hero:RespawnHero(false, false)
          hero = PlayerResource:GetSelectedHeroEntity(playerID)
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
      if player.killed or not player.disconnected then
        return
      end
      player.disconnected = false
      hero:RemoveModifierByName("modifier_out_of_duel")

      Duels:UnCountPlayerDeath(player)
    else
      print("Duels module - player_reconnected event has no PlayerID key. Gj Valve.")
      return
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
    else
      print("Duels module - player_disconnect event has no PlayerID key. Gj Valve.")
      return
    end
  end)

  Duels.nextDuelTime = HudTimer:GetGameTime() + INITIAL_DUEL_DELAY -1
  Timers:CreateTimer(INITIAL_DUEL_DELAY - DUEL_START_WARN_TIME -1, function ()
  --HudTimer:At(INITIAL_DUEL_DELAY, function ()
    Duels:StartDuel({
      players = 0,
      firstDuel = true,
      timeout = Duels:GetDuelTimeout(1)
    })
  end)

  -- Add chat commands to force start and end duels
  ChatCommand:LinkDevCommand("-duel", Dynamic_Wrap(self, "StartDuel"), self)
  ChatCommand:LinkDevCommand("-end_duel", Dynamic_Wrap(self, "EndDuel"), self)
end

function Duels:RegisterZone(zoneName)
  self.zones = self.zones or {}
  local zoneExists = Entities:FindAllByName(zoneName)
  if zoneExists and #zoneExists > 0 then
    table.insert(
      self.zones,
      ZoneControl:CreateZone(zoneName, {
        mode = ZONE_CONTROL_INCLUSIVE,
        margin = 500,
        padding = 200,
        players = {}
      })
    )
  end
end

function Duels:CountPlayerDeath (player)
  local scoreIndex = player.team .. 'Living' .. player.duelNumber
  self.currentDuel[scoreIndex] = self.currentDuel[scoreIndex] - 1

  if self.currentDuel[scoreIndex] <= 0 then
    self.currentDuel['duelEnd' .. player.duelNumber] = player.team
    DebugPrint('Duel number ' .. scoreIndex .. ' is over and ' .. player.team .. ' lost')
    local winningTeam = "bad"
    local winningTeamId = DOTA_TEAM_BADGUYS
    if player.team == "bad" then
      winningTeam = "good"
      winningTeamId = DOTA_TEAM_GOODGUYS
    end

    -- Gaining a point for winning a duel -> not intuitive
    --PointsManager:AddPoints(winningTeamId, 1)

    self:AllPlayers(self.currentDuel, function (otherPlayer)
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

  if self.currentDuel.duelEnd1 and self.currentDuel.duelEnd2 then
    DebugPrint('both duels are over, resuming normal play!')
    self:EndDuel()
  end
end

function Duels:UnCountPlayerDeath (player)
  local scoreIndex = player.team .. 'Living' .. player.duelNumber
  self.currentDuel[scoreIndex] = self.currentDuel[scoreIndex] + 1
end

function Duels:IsActive ()
  if not self.currentDuel or self.currentDuel == DUEL_IS_STARTING then
    return false
  end
  return true
end

function Duels:CheckDuelStatus (event)
  if not self:IsActive() then
    return
  end

  local hero = event.killed

  if hero:IsTempestDouble() or hero:IsSpiritBearOAA() then
    return
  end

  if hero:IsClone() then
    hero = hero:GetCloneSource()
  end

  if hero:IsReincarnating() then
    --hero:SetRespawnsDisabled(false)
    --Timers:CreateTimer(1, function ()
      --hero:SetRespawnsDisabled(true)
    --end)
    return
  end

  local playerId = hero:GetPlayerOwnerID()

  local player = self:PlayerForDuel(playerId)
  if not player then
    -- player is not in this duel!
    return
  end

  if not player.assigned or not player.duelNumber then
    DebugPrint('Player died who isnt in a duel?')
    DebugPrintTable(self.currentDuel)
    DebugPrintTable(player)
    return
  end

  if player.killed then
    -- this player is already dead and shouldn't be counted again
    -- this shouldn't happen, but is nice to have here for future use cases of this method
    -- this can happen for Meepo too
    DebugPrint('Player died twice in duel?')
    DebugPrintTable(self.currentDuel)
    DebugPrintTable(player)
    return
  end

  if not player.disconnected then
    player.killed = true
  end

  self:CountPlayerDeath(player)
end

function Duels:StartDuel(options)
  if self.currentDuel then
    DebugPrint ('There is already a duel running')
    return
  end
  self.wasCanceled = false
  options = options or {}
  if not options.firstDuel then
    Music:SetMusic(12)
    self.allowExperienceGain = 1
  else
    self.allowExperienceGain = 2
  end
  Timers:RemoveTimer('EndDuel')
  self.currentDuel = DUEL_IS_STARTING
  DuelPreparingEvent.broadcast(true)

  local warning = DUEL_START_WARN_TIME - DUEL_START_COUNTDOWN
  Notifications:TopToAll({text="#duel_imminent_warning", duration=warning, style={color="red", ["font-size"]="50px"}, replacement_map={seconds_to_duel = DUEL_START_WARN_TIME}})
  -- Use only 1 timer
  local index = 0
  Timers:CreateTimer(warning, function ()
    if Duels.wasCanceled then
      return
    end
    if index < DUEL_START_COUNTDOWN then
      Notifications:TopToAll({text=tostring(DUEL_START_COUNTDOWN - index), duration=1.0})
      index = index + 1
      return 1
    end
  end)

  Timers:CreateTimer(DUEL_START_WARN_TIME, function ()
    if Duels.wasCanceled then
      return
    end
    Notifications:TopToAll({text="#duel_start", duration=3.0, style={color="red", ["font-size"]="100px"}})
    for _, zone in ipairs(Duels.zones) do
      ZoneCleaner:CleanZone(zone)
    end
    Duels:ActuallyStartDuel(options)
  end)
end

function Duels:CancelDuel()
  if self.currentDuel == DUEL_IS_STARTING and self.wasCanceled == false then
    self.wasCanceled = true
    Notifications:TopToAll({text="DUEL CANCELED", duration=3.0, style={color="red", ["font-size"]="100px"}})

    self:CleanUpDuel()
  end
end

function Duels:SplitDuelPlayers(options)
  -- respawn everyone
  local goodPlayerIndex = 1
  local badPlayerIndex = 1
  local validGoodPlayerIndex = 1
  local validBadPlayerIndex = 1

  local goodPlayers = {}
  local badPlayers = {}

  for playerId = 0, DOTA_MAX_TEAM_PLAYERS-1 do
    if PlayerResource:IsValidPlayerID(playerId) then
      local player = PlayerResource:GetPlayer(playerId)
      if player ~= nil and not player:IsNull() then
        local hero = player:GetAssignedHero()
        if hero then
          if player:GetTeam() == DOTA_TEAM_BADGUYS then
            badPlayers[badPlayerIndex] = HeroState.SaveState(hero)
            badPlayers[badPlayerIndex].id = playerId
            -- used to generate keynames like badEnd1
            -- not used in dota apis
            badPlayers[badPlayerIndex].team = 'bad'
            badPlayerIndex = badPlayerIndex + 1
            validBadPlayerIndex = validBadPlayerIndex + 1
          elseif player:GetTeam() == DOTA_TEAM_GOODGUYS then
            goodPlayers[goodPlayerIndex] = HeroState.SaveState(hero)
            goodPlayers[goodPlayerIndex].id = playerId
            goodPlayers[goodPlayerIndex].team = 'good'
            goodPlayerIndex = goodPlayerIndex + 1
            validGoodPlayerIndex = validGoodPlayerIndex + 1
          end

          HeroState.ResetState(hero)
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
  end

  goodPlayerIndex = goodPlayerIndex - 1
  badPlayerIndex = badPlayerIndex - 1
  validGoodPlayerIndex = validGoodPlayerIndex - 1
  validBadPlayerIndex = validBadPlayerIndex - 1

  -- split up players, put them in the duels
  local maxPlayers = 0
  if not options.forceAllPlayers then
    validGoodPlayerIndex = math.min(validGoodPlayerIndex, validBadPlayerIndex)
    validBadPlayerIndex = math.min(validGoodPlayerIndex, validBadPlayerIndex)
  end

  maxPlayers = math.max(validGoodPlayerIndex, validBadPlayerIndex)

  DebugPrint('Max players per team for this duel ' .. maxPlayers)

  if maxPlayers < 1 then
    DebugPrint('There aren\'t enough players to start the duel')
    Notifications:TopToAll({text="#duel_not_enough_players", duration=2.0})
    self.currentDuel = nil
    Music:PlayBackground(1, 7)
    return nil
  end
  Music:SetMusic(13)

  local playerSplitOffset = RandomInt(0, maxPlayers)
  -- Uncomment this to disable solo duels
  --if playerSplitOffset == 1 then
    --playerSplitOffset = 2
  --end
  if options.players then
    playerSplitOffset = math.min(options.players, maxPlayers)
  end

  if playerSplitOffset > maxPlayers / 2.0 then
    playerSplitOffset = maxPlayers - playerSplitOffset
  end

  if options.isFinalDuel or HeroSelection.isCM or options.forceAllPlayers then
    playerSplitOffset = 0
    if Duels.allowExperienceGain ~= 2 then
      Duels.allowExperienceGain = 1
    end
  end

  return
  {
    MaxPlayers = maxPlayers,
    MaxGoodPlayers = validGoodPlayerIndex,
    MaxBadPlayers = validBadPlayerIndex,
    PlayerSplitOffset = playerSplitOffset,
    GoodPlayers = goodPlayers,
    BadPlayers = badPlayers,
    GoodPlayerIndex = goodPlayerIndex,
    BadPlayerIndex = badPlayerIndex,
  }
end

function Duels:ActuallyStartDuel(options)
  local split = self:SplitDuelPlayers(options)
  if split == nil then
    return
  end

  DebugPrint("Duel Player Split")
  DebugPrint(split.PlayerSplitOffset)

  if #self.zones < 3 then
    return
  end

  local bigArenaIndex = RandomInt(3, #self.zones)
  local smallArenaIndex = RandomInt(1, 2)

  local gamemode = GameRules:GetGameModeEntity()
  gamemode:SetCustomBackpackSwapCooldown(1.0)

  self:SpawnPlayersOnArenas(split, smallArenaIndex, bigArenaIndex)
  self:PreparePlayersToStartDuel(options, split)
end

function Duels:SpawnPlayerOnArena(playerSplit, arenaIndex, duelNumber)
  local spawn1 = Entities:FindByName(nil, 'duel_' .. tostring(arenaIndex) .. '_spawn_1'):GetAbsOrigin()
  local spawn2 = Entities:FindByName(nil, 'duel_' .. tostring(arenaIndex) .. '_spawn_2'):GetAbsOrigin()

  local goodGuy = self:GetUnassignedPlayer(playerSplit.GoodPlayers, playerSplit.GoodPlayerIndex)
  local badGuy = self:GetUnassignedPlayer(playerSplit.BadPlayers, playerSplit.BadPlayerIndex)

  local function spawnHeroForGuy(guy, spawn)
    local player = PlayerResource:GetPlayer(guy.id)
    local hero = player:GetAssignedHero()
    guy.duelNumber = duelNumber
    Duels.zones[arenaIndex].addPlayer(guy.id)

    SafeTeleportAll(hero, spawn, 350, true)
    MoveCameraToPlayer(hero)
    hero:Stop()
    --hero:SetRespawnsDisabled(true) -- not working properly thanks to Aghs Lab 2
  end

  if goodGuy then
    spawnHeroForGuy(goodGuy, spawn1)
  end

  if badGuy then
    spawnHeroForGuy(badGuy, spawn2)
  end
end

function Duels:PreparePlayersToStartDuel(options, playerSplit)
  for _, player in ipairs(playerSplit.BadPlayers) do
    local hero = PlayerResource:GetSelectedHeroEntity(player.id)
    if player.assigned == nil then
      hero:Stop()
      hero:AddNewModifier(nil, nil, "modifier_out_of_duel", nil)
    else
      hero:AddNewModifier(nil, nil, "modifier_duel_invulnerability", {duration = DUEL_START_PROTECTION_TIME})
    end
  end
  for _, player in ipairs(playerSplit.GoodPlayers) do
    local hero = PlayerResource:GetSelectedHeroEntity(player.id)
    if player.assigned == nil then
      hero:Stop()
      hero:AddNewModifier(nil, nil, "modifier_out_of_duel", nil)
    else
      hero:AddNewModifier(nil, nil, "modifier_duel_invulnerability", {duration = DUEL_START_PROTECTION_TIME})
    end
  end

  self.currentDuel = {
    goodLiving1 = playerSplit.PlayerSplitOffset,
    badLiving1 = playerSplit.PlayerSplitOffset,
    goodLiving2 = playerSplit.MaxGoodPlayers - playerSplit.PlayerSplitOffset,
    badLiving2 = playerSplit.MaxBadPlayers - playerSplit.PlayerSplitOffset,
    duelEnd1 = playerSplit.PlayerSplitOffset == 0,
    duelEnd2 = playerSplit.MaxPlayers == playerSplit.PlayerSplitOffset,
    badPlayers = playerSplit.BadPlayers,
    goodPlayers = playerSplit.GoodPlayers,
    badPlayerIndex = playerSplit.BadPlayerIndex,
    goodPlayerIndex = playerSplit.GoodPlayerIndex
  }

  Timers:CreateTimer(2, function()
    GridNav:RegrowAllTrees()
    CreepItemDrop:ClearBottles()
    if options and options.firstDuel and playerSplit then
      for _, player in ipairs(playerSplit.BadPlayers) do
        local hero = PlayerResource:GetSelectedHeroEntity(player.id)
        hero:AddItemByName("item_madstone_bundle")
        hero:AddItemByName("item_madstone_bundle")
      end
      for _, player in ipairs(playerSplit.GoodPlayers) do
        local hero = PlayerResource:GetSelectedHeroEntity(player.id)
        hero:AddItemByName("item_madstone_bundle")
        hero:AddItemByName("item_madstone_bundle")
      end
    end
  end)

  DebugPrint("Duel Info")
  DebugPrintTable(self.currentDuel)

  DuelStartEvent.broadcast(self.currentDuel)

  if options.timeout == nil then
    options.timeout = Duels:GetDuelTimeout()
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

function Duels:SpawnPlayersOnArenas(playerSplit, arenaIndex1, arenaIndex2)

  -- Smaller Arena
  for playerNumber = 1, playerSplit.PlayerSplitOffset do
    self:SpawnPlayerOnArena(playerSplit, arenaIndex1, 1)
  end

  -- Bigger Arena
  for playerNumber = playerSplit.PlayerSplitOffset + 1, playerSplit.MaxPlayers do
    self:SpawnPlayerOnArena(playerSplit, arenaIndex2, 2)
  end

end

function Duels:GetUnassignedPlayer (group, max)
  local options = {}
  for _,player in pairs(group) do
    if not player.assigned and player.assignable and _ <= max then
      table.insert(options, player)
    end
  end
  if #options < 1 then
    return nil
  end

  local playerIndex = RandomInt(1, #options)
  options[playerIndex].assigned = true
  return options[playerIndex]
end

function Duels:TimeoutDuel ()
  if self.currentDuel == nil then
    DebugPrint ('There is no duel running')
    return
  end

  DebugPrint('timing out the duel because this isnt going well...')
  Timers:RemoveTimer('EndDuel')

  local warning = 3
  Notifications:TopToAll({text="#duel_timeout_warning", duration=warning, style={color="blue", ["font-size"]="50px"}, replacement_map={seconds_to_duel_end = DUEL_END_COUNTDOWN}})
  -- Use only 1 timer
  local index = warning
  Timers:CreateTimer(warning, function ()
    -- Check if duel ended
    if Duels.currentDuel == nil then
      return
    end
    if index < DUEL_END_COUNTDOWN then
      Notifications:TopToAll({text=tostring(DUEL_END_COUNTDOWN - index), duration=1.0})
      index = index + 1
      return 1
    end
  end)

  Timers:CreateTimer('EndDuel', {
    endTime = DUEL_END_COUNTDOWN,
    callback = function()
      Duels:EndDuel()
    end
  })
end

function Duels:SetNextDuelTime()
  Duels.nextDuelTime = HudTimer:GetGameTime() + Duels:GetDuelIntervalTime() + DUEL_START_WARN_TIME
end

function Duels:GetNextDuelTime()
  if Duels:IsActive() then return HudTimer:GetGameTime() end
  return Duels.nextDuelTime
end

function Duels:CleanUpDuel ()
  if self.currentDuel == nil then
    DebugPrint ('There is no duel running')
    return
  end

  DebugPrint('Duel has ended')
  Timers:RemoveTimer('EndDuel')

  Music:PlayBackground(1, 7)

  local nextDuelIn = Duels:GetDuelIntervalTime()
  Duels:SetNextDuelTime()

  if self.startDuelTimer then
    Timers:RemoveTimer(self.startDuelTimer)
    self.startDuelTimer = nil
  end

  self.startDuelTimer = Timers:CreateTimer(nextDuelIn - 60 + DUEL_START_WARN_TIME, function ()
    Notifications:TopToAll({text="#duel_minute_warning", duration=10.0, style={color="blue", ["font-size"]="50px"}})
    Duels.startDuelTimer = Timers:CreateTimer(60 - DUEL_START_WARN_TIME, partial(Duels.StartDuel, Duels))
  end)

  self.currentDuel = nil
end

function Duels:EndDuel ()
  if not self:IsActive() then
    DebugPrint ('There is no duel running')
    return
  end

  for playerId = 0, DOTA_MAX_TEAM_PLAYERS-1 do
    if PlayerResource:IsValidPlayerID(playerId) then
      for _, zone in ipairs(self.zones) do
        zone.removePlayer(playerId, false)
      end
    end
  end

  local gamemode = GameRules:GetGameModeEntity()
  gamemode:SetCustomBackpackSwapCooldown(3.0)

  local currentDuel = self.currentDuel
  self:CleanUpDuel() -- this sets self.currentDuel to nil

  Timers:CreateTimer(0.1, function ()
    DebugPrint('Sending all players back!')
    Duels:AllPlayers(currentDuel, function (state)
      local player = PlayerResource:GetPlayer(state.id)
      if player == nil then -- disconnected!
        return
      end

      local hero = player:GetAssignedHero()
      if not hero:IsAlive() then
        --hero:SetRespawnsDisabled(false)
        hero:RespawnHero(false, false)
        -- hero is changed on respawn sometimes
        hero = player:GetAssignedHero()
      else
        hero:RemoveModifierByName("modifier_out_of_duel")
      end

      if not state.assigned then
        return
      end

      HeroState.RestoreState(hero, state)
      MoveCameraToPlayer(hero)
      HeroState.PurgeDuelHighgroundBuffs(hero) -- needed to remove undispellable Highground buffs
    end)
    -- Remove Modifier
    for playerId = 0, DOTA_MAX_TEAM_PLAYERS-1 do
      if PlayerResource:IsValidPlayerID(playerId) then
        local player = PlayerResource:GetPlayer(playerId)
        if player then
          local hero = PlayerResource:GetSelectedHeroEntity(playerId)

          if hero ~= nil then
            hero:RemoveModifierByName("modifier_out_of_duel")
          end
        end
      end
    end
    DuelEndEvent.broadcast(currentDuel)
  end)
end

function Duels:AllPlayers(state, cb)
  if state == nil then
    for playerId = 0, DOTA_MAX_TEAM_PLAYERS-1 do
      if PlayerResource:IsValidPlayerID(playerId) then
        local player = PlayerResource:GetPlayer(playerId)
        if player ~= nil then
          cb(player)
        end
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

function Duels:PlayerForDuel(playerId)
  local foundIt = false

  Duels:AllPlayers(Duels.currentDuel, function (player)
    if foundIt or player.id ~= playerId then
      return
    end
    foundIt = player
  end)

  return foundIt
end

function Duels:GetDuelIntervalTime()
  local lowPlayerCount = GetMapName() == "tinymode"
  if HeroSelection then
    lowPlayerCount = HeroSelection.lowPlayerCount
  end
  if lowPlayerCount then
    return ONE_V_ONE_DUEL_INTERVAL
  end

  return DUEL_INTERVAL
end

function Duels:GetDuelTimeout(duelType)
  local lowPlayerCount = GetMapName() == "tinymode"
  if HeroSelection then
    lowPlayerCount = HeroSelection.lowPlayerCount
  end
  if lowPlayerCount then
    return ONE_V_ONE_DUEL_TIMEOUT
  end
  if not duelType then
    -- Duel is not first and not final
    return DUEL_TIMEOUT
  elseif duelType == 1 then
    -- First duel
    return FIRST_DUEL_TIMEOUT
  elseif duelType == 2 then
    -- Final duel
    return FINAL_DUEL_TIMEOUT
  end

  return DUEL_TIMEOUT
end
