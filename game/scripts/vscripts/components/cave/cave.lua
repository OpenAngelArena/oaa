
if CaveHandler == nil then
  Debug.EnabledModules['cave:cave'] = true
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
      doorDistance = 260
    elseif teamID == DOTA_TEAM_BADGUYS then
      doorDistance = 330
    end

    self.caves[teamID] = {
      timescleared = 0,
      rooms = {}
    }

    for roomID = 1, 4 do
      self.caves[teamID].rooms[roomID] = {
        handle = Entities:FindByName(nil, caveName .. "_room_" .. roomID),
        creepCount = 0,
        zone = ZoneControl:CreateZone(caveName .. "_zone_" .. roomID, {
          mode = ZONE_CONTROL_EXCLUSIVE_OUT,
          players = tomap(zip(PlayerResource:GetAllTeamPlayerIDs(), duplicate(true)))
        }),
        door = Doors:UseDoors(caveName .. '_door_' .. roomID, {
          state = DOOR_STATE_CLOSED,
          distance = doorDistance,
          openingStepDelay = 1/300,
          openingStepSize = 3,
          closingStepDelay = 1/200,
          closingStepSize = 2,
        }),
        radius = 1600
      }
    end
  end

  self:InitCave(DOTA_TEAM_GOODGUYS)
  self:InitCave(DOTA_TEAM_BADGUYS)
end


function CaveHandler:InitCave (teamID)
  self.caves[teamID].rooms[1].zone.disable()
  self:ResetCave(teamID)
end

function CaveHandler:ResetCave (teamID)
  local cave = self.caves[teamID]

  for roomID, room in pairs(cave.rooms) do
    self:SpawnRoom(teamID, roomID)
    if roomID > 1 then
      room.zone.enable()
      room.door.Close()
    end
  end
end

function CaveHandler:SpawnRoom (teamID, roomID)
  DebugPrint('Spawning room ' .. roomID .. ' of team ' .. GetTeamName(teamID))

  local cave = self.caves[teamID]
  local room = cave.rooms[roomID]
  local creepList = CaveTypes[roomID][math.random(#CaveTypes[roomID])]

  for _, creep in ipairs(creepList.units) do -- spawn all creeps in list
    -- get properties for the creep
    local creepProperties = self:GetCreepProperties(creep, creepList.multiplier, cave.timescleared)

    -- spawn the creep
    local creepHandle = self:SpawnCreepInRoom(room.handle, creepProperties)

    if roomID == 4 then
      creepHandle:SetModelScale( creepHandle:GetModelScale() / (0.5 * (cave.timescleared + 1)) )
    end

    creepHandle:OnDeath(function(keys)
      self:CreepDeath(teamID, roomID)
    end)

    room.creepCount = room.creepCount + 1
  end
end

function CaveHandler:GetCreepProperties (creep, multiplier, k)
  local round = math.floor
  return {
    name = creep[1],
    hp = round(multiplier.hp(k) * creep[2]),
    mana = round(multiplier.mana(k) * creep[3]),
    damage = round(multiplier.damage(k) * creep[4]),
    armour = round(multiplier.armour(k) * creep[5]),
    gold = round(multiplier.gold(k) * creep[6]),
    exp = round(multiplier.exp(k) * creep[7]),
    magicResist = round(multiplier.magicResist(k) * creep[8]),
  }
end

function CaveHandler:SpawnCreepInRoom (room, properties, lastRoom)
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

  --GOLD BOUNTY
  creep:SetMinimumGoldBounty(properties.gold)
  creep:SetMaximumGoldBounty(properties.gold)

  if properties.magicResist ~= nil then
    creep:SetBaseMagicalResistanceValue(properties.magicResist)
  end

  --EXP BOUNTY
  local minutes = math.floor(GameRules:GetGameTime() / 60)
  if minutes > 60 then
    properties.exp = properties.exp * 1.5^(minutes - 60)
  end
  creep:SetDeathXP(properties.exp)

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
      DebugPrint('Opening next room.')
      cave.rooms[roomID + 1].door.Open()
      cave.rooms[roomID + 1].zone.disable()

      -- inform players
      Notifications:TopToTeam(teamID, {
        text = "Room " .. roomID .. " got cleared. You can now advance to the next room",
        duration = 5,
      })
    else
      -- close doors
      self:CloseDoors(teamID)

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
        local statTable = CustomNetTables:GetTableValue('stat_display', 'CC').value
        table.insert(statTable, { [tostring(playerID)] = cave.timescleared })
        CustomNetTables:SetTableValue('stat_display', 'CC', { value = statTable })
      end
      -- inform players
      Notifications:TopToTeam(teamID, {
        text = "Your last Room got cleared. Every player on your Team got " .. bounty .. " gold",
        duration = 10,
        continue = true
      })
      Notifications:TopToTeam(teamID, {
        text = "You have cleared the Cave " .. cave.timescleared .. " times. The Cave is resetting now.",
        duration = 10,
      })
    end
  end
end

function CaveHandler:CloseDoors(teamID)
  local cave = self.caves[teamID]
  for roomID, room in pairs(cave.rooms) do
    if roomID > 1 then
      room.door.Close()
    end
  end
end

function CaveHandler:GiveBounty (teamID, k)
  local roshGold = CaveTypes[4][1].units[1][7]
  local roshCount = #CaveTypes[4][1].units
  local playerCount = PlayerResource:GetPlayerCountForTeam(teamID)
  each(DebugPrint, PlayerResource:GetPlayerIDsForTeam(teamID))
  local round = math.floor

  local pool = (8 * k + 6) * roshGold * roshCount
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
  local caveOrigin = self.caves[teamID].rooms[1].zone.origin
  local bounds = self.caves[teamID].rooms[1].zone.bounds

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

-- get all heroes in all rooms
for roomID, room in pairs(cave.rooms) do
  DebugPrint('Looking for units in room ' .. roomID .. ' in a ' .. room.radius .. ' radius.')

  for team = DOTA_TEAM_GOODGUYS, DOTA_TEAM_BADGUYS do
    local result = FindUnitsInRadius(
      team, -- team
      room.zone.origin, -- location
      nil, -- cache
      room.radius, -- radius
      DOTA_UNIT_TARGET_TEAM_FRIENDLY, -- team filter
      DOTA_UNIT_TARGET_ALL, -- type filter
      DOTA_UNIT_TARGET_FLAG_NONE, -- flag filter
      FIND_ANY_ORDER, -- order
      false -- can grow cache
    )
    for _, unit in pairs(result) do
      if CaveHandler:IsInFarmingCave(teamID, unit) then
        table.insert(units, unit)
      end
    end
  end
end

DebugPrint('Teleporting units now')

for _, unit in pairs(units) do
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
  ParticleManager:SetParticleControl(target, 0, spawns[unit:GetTeamNumber()])

  Timers:CreateTimer(3, function ()
    FindClearSpaceForUnit(
    unit, -- unit
    spawns[unit:GetTeamNumber()], -- location
    false -- ???
  )

  if unit:IsHero() then
    PlayerResource:SetCameraTarget(unit:GetPlayerID(), unit)
    Timers:CreateTimer(1, function ()
      PlayerResource:SetCameraTarget(unit:GetPlayerID(), nil)
    end)
  end

  Timers:CreateTimer(0, function ()
    ParticleManager:DestroyParticle(origin, false)
    ParticleManager:DestroyParticle(target, true)
  end)

  -- stand still
  unit:Stop()
end)
end
end

function CaveHandler:GetCleares (teamID)
  return self.caves[teamID].timescleared
end
