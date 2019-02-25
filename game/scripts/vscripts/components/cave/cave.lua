
local MAX_DOORS = 2
local MAX_ZONES = 2

if CaveHandler == nil then
  DebugPrint ('creating new CaveHandler object.')
  CaveHandler = class({})
end


function CaveHandler:Init ()
  DebugPrint ('Initializing.')

  CaveHandler.caves = {}

  for teamID = DOTA_TEAM_GOODGUYS, DOTA_TEAM_BADGUYS do
    local caveName = 'cave_' .. GetShortTeamName(teamID)
    local doorDistance = 0
    if teamID == DOTA_TEAM_GOODGUYS then
      doorDistance = 400
    elseif teamID == DOTA_TEAM_BADGUYS then
      doorDistance = 400
    end

    self.caves[teamID] = {
      timescleared = 0,
      rooms = {}
    }

    self.caves[teamID].rooms[0] = {
      zones = {
        ZoneControl:CreateZone(caveName .. "_zone_0", {
          mode = ZONE_CONTROL_EXCLUSIVE_OUT,
          players = {}
        })
      },
      radius = 1600
    }
    for roomID = 1,4 do
      self.caves[teamID].rooms[roomID] = {
        handle = Entities:FindByName(nil, caveName .. "_room_" .. roomID),
        creepCount = 0,
        zones = {},
        doors = {},
        radius = 1600
      }
      self.caves[teamID].rooms[roomID].zones[0] = ZoneControl:CreateZone(caveName .. "_room_" .. roomID, {
        mode = ZONE_CONTROL_EXCLUSIVE_OUT,
        players = {}
      })
      for zoneID=1,MAX_ZONES do
        if Entities:FindByName(nil, caveName .. "_zone_" .. roomID .. '_' .. zoneID) then
          self.caves[teamID].rooms[roomID].zones[zoneID] = ZoneControl:CreateZone(caveName .. "_zone_" .. roomID .. '_' .. zoneID, {
            mode = ZONE_CONTROL_EXCLUSIVE_OUT,
            players = {}
          })
        end
      end
      for doorID=1,MAX_DOORS do
        self.caves[teamID].rooms[roomID].doors[doorID] = Doors:UseDoors(caveName .. '_door_' .. roomID .. '_' .. doorID, {
          state = DOOR_STATE_CLOSED,
          distance = doorDistance,
          openingStepDelay = 1/300,
          openingStepSize = 3,
          closingStepDelay = 1/200,
          closingStepSize = 2,
        })
      end
    end
  end

  if not SKIP_TEAM_SETUP then
    Timers:CreateTimer(INITIAL_CREEP_DELAY, Dynamic_Wrap(self, 'Start'), self)
  else
    Timers:CreateTimer(Dynamic_Wrap(self, 'Start'), self)
  end

  CustomNetTables:SetTableValue('stat_display_player', 'CC', { value = {} })
end

function CaveHandler:Start ()
  self:InitCave(DOTA_TEAM_GOODGUYS)
  self:InitCave(DOTA_TEAM_BADGUYS)
end

function CaveHandler:InitCave (teamID)
  self:ResetCave(teamID)
  CaveHandler:DisableZones(teamID, 0)
end

function CaveHandler:ResetCave (teamID)
  local cave = self.caves[teamID]

  for roomID, room in pairs(cave.rooms) do
    if roomID ~= 0 then
      self:SpawnRoom(teamID, roomID)
      self:CloseDoors(teamID, roomID)
      self:DisableZones(teamID, roomID)
    end
  end
end

function CaveHandler:SpawnRoom (teamID, roomID)
  DebugPrint('Spawning room ' .. roomID .. ' of team ' .. GetTeamName(teamID))

  local cave = self.caves[teamID]
  local room = cave.rooms[roomID]
  local creepList = CaveTypes[roomID][RandomInt(1, #CaveTypes[roomID])]

  for _,creep in ipairs(creepList.units) do -- spawn all creeps in list
    -- get properties for the creep
    local creepProperties = self:GetCreepProperties(creep, creepList.multiplier, cave.timescleared)

    -- spawn the creep
    local creepHandle = self:SpawnCreepInRoom(room.handle, creepProperties, teamID, roomID)

    if roomID == 4 then
      creepHandle:SetModelScale( creepHandle:GetModelScale() / (0.5 * (cave.timescleared + 1)) )
    end

    room.creepCount = room.creepCount + 1
  end
end

function CaveHandler:GetCreepProperties (creep, multiplier, k)
  local round = math.floor
  return {
    name = creep[1],
    hp = round(multiplier.hp(k) * creep[CAVE_TYPE_STATS_HEALTH]),
    mana = round(multiplier.mana(k) * creep[CAVE_TYPE_STATS_MANA]),
    damage = round(multiplier.damage(k) * creep[CAVE_TYPE_STATS_DAMAGE]),
    armour = round(multiplier.armour(k) * creep[CAVE_TYPE_STATS_ARMOUR]),
    gold = round(multiplier.gold(k) * creep[CAVE_TYPE_STATS_GOLD]),
    exp = round(multiplier.exp(k) * creep[CAVE_TYPE_STATS_EXP]),
    magicResist = round(multiplier.magicResist(k) * creep[CAVE_TYPE_STATS_RESITS]),
  }
end

function CaveHandler:SpawnCreepInRoom (room, properties, teamID, roomID)
  -- get random position
  local randPosition = room:GetAbsOrigin() + RandomVector(RandomFloat(10, 300))

  local creep = CreateUnitByName(
    properties.name, -- name
    randPosition, -- location
    true, --
    nil, --
    nil, --
    DOTA_TEAM_NEUTRALS -- team
  )

  -- HEALTH
  creep:SetBaseMaxHealth(properties.hp)
  creep:SetMaxHealth(properties.hp)
  creep:SetHealth(properties.hp)

  --MANA
  creep:SetMana(properties.mana)

  --DAMAGE
  creep:SetBaseDamageMin(properties.damage)
  creep:SetBaseDamageMax(properties.damage)

  --ARMOR
  creep:SetPhysicalArmorBaseValue(properties.armour)

  -- BOUNTY
  -- bounty is given on death to whole team
  creep:SetMinimumGoldBounty(0)
  creep:SetMaximumGoldBounty(0)
  creep:SetDeathXP(0)

  local function calculateMultiplier (myTeamID)
    local function getHeroNetworth (playerId)
      local hero = PlayerResource:GetSelectedHeroEntity(playerId)
      if not hero then
        return 0
      end
      return hero:GetNetworth() + XP_PER_LEVEL_TABLE[hero:GetLevel()]
    end

    local otherTeamID = nil

    if myTeamID == DOTA_TEAM_BADGUYS then
      otherTeamID = DOTA_TEAM_GOODGUYS
    elseif myTeamID == DOTA_TEAM_GOODGUYS then
      otherTeamID = DOTA_TEAM_BADGUYS
    else
      error('Got bad myTeamID value, should be goodguys or badguys ' .. tostring(myTeamID))
    end

    local myTeamNW = reduce(operator.add, 0, map(getHeroNetworth, PlayerResource:GetPlayerIDsForTeam(myTeamID)))
    local theirTeamNW = reduce(operator.add, 0, map(getHeroNetworth, PlayerResource:GetPlayerIDsForTeam(otherTeamID)))

    -- generate a number between -1 and 1
    -- 0 is when teams are even
    -- -1 is when my team is max amount ahead (and gets the least)
    -- 1 is when my team is max amount behind (and gets the most)
    local maxTeamDifference = math.max(1, math.min(theirTeamNW, myTeamNW))

    local nwFactor = CAVE_RELEVANCE_FACTOR * ((theirTeamNW - myTeamNW) / maxTeamDifference)
    local multiplier = math.exp(math.log(CAVE_MAX_MULTIPLIER) * nwFactor / (1 + math.abs(nwFactor)))

    DebugPrint('Multiplier: ' .. multiplier .. ' based on nwFactor ' .. nwFactor)

    return multiplier
    -- scales between doubling in either direction
    -- local newFactor = math.min(1, math.max(-1, (theirTeamNW - myTeamNW) / maxTeamDifference)) + 1

    -- -- figure out multiplier...
    -- -- base guarenteed value
    -- local multiplier = 0.10
    -- multiplier = multiplier + (newFactor * 0.95)
    -- -- multiplier is between 0.10 and 2.0

    -- return multiplier
  end

  local function giveBounty (bounty, exp, playerID)
    PlayerResource:ModifyGold(
      playerID, -- player
      bounty, -- amount
      true, -- is reliable gold
      DOTA_ModifyGold_RoshanKill -- reason
    )
    local hero = PlayerResource:GetSelectedHeroEntity(playerID)

    if hero then
      hero:AddExperience(exp, DOTA_ModifyXP_Unspecified, false, true)
      local player = hero:GetPlayerOwner()
      if player then
        SendOverheadEventMessage(player, OVERHEAD_ALERT_GOLD, creep, bounty, player)
      end
    end
  end

  local function handleCreepDeath (gold, exp, _teamID, _roomID)
    local playerIDs = PlayerResource:GetPlayerIDsForTeam(_teamID)
    local bounty = math.ceil(gold / playerIDs:length())
    exp = exp / playerIDs:length()

    local multiplier = calculateMultiplier(_teamID)
    bounty = bounty * multiplier
    exp = exp * multiplier

    each(partial(giveBounty, bounty, exp), playerIDs)

    self:CreepDeath(_teamID, _roomID)
  end

  creep:OnDeath(partial(handleCreepDeath, properties.gold, properties.exp, teamID, roomID))

  if properties.magicResist ~= nil then
    creep:SetBaseMagicalResistanceValue(properties.magicResist)
  end

  return creep
end

function CaveHandler:CreepDeath (teamID, roomID)
  local cave = self.caves[teamID]
  local room = cave.rooms[roomID]

  room.creepCount = room.creepCount - 1

  if room.creepCount == 0 then -- all creeps are dead
    DebugPrint('Room ' .. roomID .. ' of Team ' .. GetTeamName(teamID) .. ' got cleared.')

    if roomID < 4 then -- not last room
      -- let players advance to next room
      DebugPrint('Opening room.')
      self:OpenDoors(teamID, roomID + 1)
      self:DisableZones(teamID, roomID)

      local result = FindUnitsInRadius(
        teamID, -- team
        cave.rooms[roomID].zones[0].origin, -- location
        nil, -- cache
        cave.rooms[roomID].radius, -- radius
        DOTA_UNIT_TARGET_TEAM_FRIENDLY, -- team filter
        DOTA_UNIT_TARGET_ALL, -- type filter
        DOTA_UNIT_TARGET_FLAG_NONE, -- flag filter
        FIND_ANY_ORDER, -- order
        false -- can grow cache
      )

      local hasSeenNotification = {}

      for _, unit in pairs(result) do
        if not hasSeenNotification[unit:GetPlayerOwnerID()] then
          -- inform players
          Notifications:Top(unit:GetPlayerOwner(), {
            text = "#cave_room_cleared",
            duration = 5,
            replacement_map = {
              room_id = roomID,
            },
          })
          hasSeenNotification[unit:GetPlayerOwnerID()] = true
        end
      end
    else -- roomID >= 4
      -- close doors
      self:CloseCaveDoors(teamID)
      self:EnableCaveZones(teamID)

      -- give all players gold
      local bounty = self:GiveBounty(teamID, cave.timescleared)

      -- teleport player back to base
      self:KickPlayers(teamID)

      -- reset cave
      Timers:CreateTimer(4, function ()
        self:ResetCave(teamID)
      end)

      cave.timescleared = cave.timescleared + 1
      for playerID in PlayerResource:GetPlayerIDsForTeam(teamID) do
        local statTable = CustomNetTables:GetTableValue('stat_display_player', 'CC').value

        if statTable[tostring(playerID)] then
          statTable[tostring(playerID)] = statTable[tostring(playerID)] + 1
        else
          statTable[tostring(playerID)] = 1
        end

        CustomNetTables:SetTableValue('stat_display_player', 'CC', { value = statTable })
      end
      -- inform players
      Notifications:TopToTeam(teamID, {
        text = "#cave_fully_cleared_reward",
        duration = 10,
        replacement_map = {
          reward_amount = bounty,
        },
      })
      Notifications:TopToTeam(teamID, {
        text = "#cave_fully_cleared_num_clears",
        duration = 10,
        replacement_map = {
          num_clears = cave.timescleared,
        },
      })
    end
  end
end

function CaveHandler:CloseCaveDoors(teamID)
  local cave = self.caves[teamID]
  for roomID,_ in pairs(cave.rooms) do
    if roomID ~= 0 then
      self:CloseDoors(teamID, roomID)
    end
  end
end

function CaveHandler:CloseDoors(teamID, roomID)
  local room = self.caves[teamID].rooms[roomID]
  for doorID=1,MAX_DOORS do
    if room.doors[doorID] then
      room.doors[doorID].Close()
    end
  end
end

function CaveHandler:OpenCaveDoors(teamID)
  local cave = self.caves[teamID]
  for roomID,_ in pairs(cave.rooms) do
    if roomID ~= 0 then
      self:OpenDoors(teamID, roomID)
    end
  end
end

function CaveHandler:OpenDoors(teamID, roomID)
  local room = self.caves[teamID].rooms[roomID]
  for doorID=1,MAX_DOORS do
    if room.doors[doorID] then
      room.doors[doorID].Open()
    end
  end
end

function CaveHandler:DisableCaveZones(teamID)
  local cave = self.caves[teamID]
  for roomID,_ in pairs(cave.rooms) do
    if roomID ~= 0 then
      self:DisableZones(teamID, roomID)
    end
  end
end

function CaveHandler:DisableZones(teamID, roomID)
  local room = self.caves[teamID].rooms[roomID]
  for zoneID=1,MAX_ZONES do
    if room.zones[zoneID] then
      room.zones[zoneID].disable()
    end
  end
end

function CaveHandler:EnableCaveZones(teamID)
  local cave = self.caves[teamID]
  for roomID,_ in pairs(cave.rooms) do
    if roomID ~= 0 then
      self:EnableZones(teamID, roomID)
    end
  end
end

function CaveHandler:EnableZones(teamID, roomID)
  local room = self.caves[teamID].rooms[roomID]
  for zoneID=1,MAX_ZONES do
    if room.zones[zoneID] then
      room.zones[zoneID].enable()
    end
  end
end

function CaveHandler:GiveBounty (teamID, k)
  local roshGold = CaveTypes[4][1].units[1][CAVE_TYPE_STATS_GOLD]
  local roshCount = #CaveTypes[4][1].units
  local playerCount = PlayerResource:GetPlayerCountForTeam(teamID)
  each(DebugPrint, PlayerResource:GetPlayerIDsForTeam(teamID))
  local round = math.floor
  local BaseCreepXPGOLDMultiplier = 4 * _G.CAVE_ROOM_INTERVAL
  local CaveXPGOLDBuff = _G.CAVE_BOUNTY
  local ExpectClear = BaseCreepXPGOLDMultiplier * k + 3*_G.CAVE_ROOM_INTERVAL

  local pool = round((1 + CaveXPGOLDBuff * ((23 * ExpectClear^2 + 375 * ExpectClear + 7116) / 7116 - 1)) * roshGold * roshCount)
  local bounty = round(pool / playerCount)
  DebugPrint("Giving " .. playerCount .. " players " .. bounty .. " gold each from a pool of " .. pool .. " gold.")

  each(function(playerID)
    PlayerResource:ModifyGold(
      playerID, -- player
      bounty, -- amount
      true, -- is reliable gold
      DOTA_ModifyGold_RoshanKill -- reason
    )
  end, PlayerResource:GetPlayerIDsForTeam(teamID))

  return bounty
end

function CaveHandler:IsInFarmingCave (teamID, entity)
  local caveOrigin = self.caves[teamID].rooms[0].zones[1].origin
  local bounds = self.caves[teamID].rooms[0].zones[1].bounds

  local origin = entity
  if entity.GetAbsOrigin then
    origin = entity:GetAbsOrigin()
  end

  if origin.x < bounds.Mins.x + caveOrigin.x then
    -- DebugPrint('x is too small')
    return false
  end
  if origin.y < bounds.Mins.y + caveOrigin.y then
    -- DebugPrint('y is too small')
    return false
  end
  if origin.x > bounds.Maxs.x + caveOrigin.x then
    -- DebugPrint('x is too large')
    return false
  end
  if origin.y > bounds.Maxs.y + caveOrigin.y then
    -- DebugPrint('y is too large')
    return false
  end

  return true
end

function CaveHandler:KickPlayers (teamID)
  DebugPrint('Kicking Players out of the cave.')

  local cave = CaveHandler.caves[teamID]
  local spawns = {
    [DOTA_TEAM_GOODGUYS] = Entities:FindByClassname(nil, 'info_player_start_goodguys'):GetAbsOrigin(),
    [DOTA_TEAM_BADGUYS] = Entities:FindByClassname(nil, 'info_player_start_badguys' ):GetAbsOrigin(),
  }
  local units = {}

  -- get all heroes in the cave
  local result = FindUnitsInRadius(
    teamID, -- team
    Vector(0,0,0), -- location
    nil, -- cache
    20000, -- radius
    DOTA_UNIT_TARGET_TEAM_BOTH, -- team filter
    DOTA_UNIT_TARGET_ALL, -- type filter
    DOTA_UNIT_TARGET_FLAG_NONE, -- flag filter
    FIND_ANY_ORDER, -- order
    false -- can grow cache
  )
  for _,unit in pairs(result) do
    if CaveHandler:IsInFarmingCave(teamID, unit) then
      table.insert(units, unit)
    end
  end

  DebugPrint('Teleporting units now')

  Timers:CreateTimer(function()
      self:TeleportAll(units, spawns)
  end)
end

function CaveHandler:GetCleares (teamID)
  return self.caves[teamID].timescleared
end

function CaveHandler:TeleportAll(units, spawns)
  for _,unit in pairs(units) do
    if unit:GetTeam() == DOTA_TEAM_GOODGUYS or unit:GetTeam() == DOTA_TEAM_BADGUYS then
      local origin = ParticleManager:CreateParticle(
        'particles/econ/events/ti6/teleport_start_ti6_lvl3.vpcf', -- particle path
        PATTACH_ABSORIGIN_FOLLOW, -- attach point
        unit -- owner
      )

      local target = ParticleManager:CreateParticle(
        'particles/econ/events/ti6/teleport_end_ti6_lvl3.vpcf', -- particle path
        PATTACH_CUSTOMORIGIN, -- attach point
        unit -- owner
      )
      ParticleManager:SetParticleControl(target, 0, spawns[unit:GetTeam()])

      Timers:CreateTimer(3, function ()
        if IsValidEntity(unit) then
          if not Duels.currentDuel or Duels.currentDuel == DUEL_IS_STARTING then
            FindClearSpaceForUnit(
              unit, -- unit
              spawns[unit:GetTeam()], -- location
              false -- ???
            )
            MoveCameraToPlayer(unit)
            unit:Stop()
          else
            local unlisten = Duels.onEnd(function ()

            FindClearSpaceForUnit(
              unit, -- unit
              spawns[unit:GetTeamNumber()], -- location
              false -- ???
            )
            MoveCameraToPlayer(unit)
            unit:Stop()
            end)
          end
        end
        Timers:CreateTimer(0, function ()
          ParticleManager:DestroyParticle(origin, false)
          ParticleManager:DestroyParticle(target, true)
          ParticleManager:ReleaseParticleIndex(origin)
          ParticleManager:ReleaseParticleIndex(target)
        end)
      end)
    end
  end
end
