if CaveHandler == nil then
    Debug.EnabledModules['creeps:cave'] = true
    DebugPrint ('creating new CaveHandler object.')
    CaveHandler = class({})
end


function CaveHandler:Init ()
  DebugPrint ('Initializing.')
  CaveHandler.caves = {}
  for teamID=DOTA_TEAM_GOODGUYS,DOTA_TEAM_BADGUYS do
    local cave = CaveHandler.caves[teamID]
    cave.timescleared = 0
    for roomNr=1,4 do
      local room = cave["room" .. roomNr]
      room.handle = Entities:FindByName(nil, "cave_" .. GetTeamName(teamID) .. "_room_" .. roomNr)
      room.cleared = true
      room.creepCount = 0
      if roomNr > 1 then
        room.zone = ZoneControl:CreateZone("cave_" .. GetTeamName(teamID) .. "_zone_" .. roomNr, {
          mode = ZONE_CONTROL_EXCLUSIVE_OUT,
          players = tomap(zip(PlayerResource:GetAllTeamPlayerIDs(), duplicate(true)))
        })
      end
    end
  end
  --[[CaveHandler.caves = { -- this can be automated
    [DOTA_TEAM_GOODGUYS] = {
      room1 = {
        handle = Entities:FindByName(nil, "cave_radiant_room_1"),
        cleared = true,
        zone = ZoneControl:CreateZone('cave_radiant_zone_1', {
          mode = ZONE_CONTROL_EXCLUSIVE_OUT,
          players = {
            [0] = true,
            [1] = true,
            [2] = true,
            [3] = true,
            [4] = true,
            [5] = true,
            [6] = true,
            [7] = true,
            [8] = true,
            [9] = true
          }
        })
      },
      room2 = {
        handle = Entities:FindByName(nil, "cave_radiant_room_2"),
        cleared = true,
        zone = ZoneControl:CreateZone('cave_radiant_zone_2', {
          mode = ZONE_CONTROL_EXCLUSIVE_OUT,
          players = {
            [0] = true,
            [1] = true,
            [2] = true,
            [3] = true,
            [4] = true,
            [5] = true,
            [6] = true,
            [7] = true,
            [8] = true,
            [9] = true
          }
        })
      },
      room3 = {
        handle = Entities:FindByName(nil, "cave_radiant_room_3"),
        cleared = true,
        zone = ZoneControl:CreateZone('cave_radiant_zone_3', {
          mode = ZONE_CONTROL_EXCLUSIVE_OUT,
          players = {
            [0] = true,
            [1] = true,
            [2] = true,
            [3] = true,
            [4] = true,
            [5] = true,
            [6] = true,
            [7] = true,
            [8] = true,
            [9] = true
          }
        })
      },
      room4 = {
        handle = Entities:FindByName(nil, "cave_radiant_room_4"),
        cleared = true,
        zone = ZoneControl:CreateZone('cave_radiant_zone_4', {
          mode = ZONE_CONTROL_EXCLUSIVE_OUT,
          players = {
            [0] = true,
            [1] = true,
            [2] = true,
            [3] = true,
            [4] = true,
            [5] = true,
            [6] = true,
            [7] = true,
            [8] = true,
            [9] = true
          }
        })
      },
      stats = {
        timescleared = 0,
      },
    },
    [DOTA_TEAM_BADGUYS] = {
      room1 = {
        handle = Entities:FindByName(nil, "cave_dire_room_1"),
        cleared = true,
        zone = ZoneControl:CreateZone('cave_dire_zone_1', {
          mode = ZONE_CONTROL_EXCLUSIVE_OUT,
          players = {
            [0] = true,
            [1] = true,
            [2] = true,
            [3] = true,
            [4] = true,
            [5] = true,
            [6] = true,
            [7] = true,
            [8] = true,
            [9] = true
          }
        })
      },
      room2 = {
        handle = Entities:FindByName(nil, "cave_dire_room_2"),
        cleared = true,
        zone = ZoneControl:CreateZone('cave_dire_zone_2', {
          mode = ZONE_CONTROL_EXCLUSIVE_OUT,
          players = {
            [0] = true,
            [1] = true,
            [2] = true,
            [3] = true,
            [4] = true,
            [5] = true,
            [6] = true,
            [7] = true,
            [8] = true,
            [9] = true
          }
        })
      },
      room3 = {
        handle = Entities:FindByName(nil, "cave_dire_room_3"),
        cleared = true,
        zone = ZoneControl:CreateZone('cave_dire_zone_3', {
          mode = ZONE_CONTROL_EXCLUSIVE_OUT,
          players = {
            [0] = true,
            [1] = true,
            [2] = true,
            [3] = true,
            [4] = true,
            [5] = true,
            [6] = true,
            [7] = true,
            [8] = true,
            [9] = true
          }
        })
      },
      room4 = {
        handle = Entities:FindByName(nil, "cave_dire_room_4"),
        cleared = true,
        zone = ZoneControl:CreateZone('cave_dire_zone_4', {
          mode = ZONE_CONTROL_EXCLUSIVE_OUT,
          players = {
            [0] = true,
            [1] = true,
            [2] = true,
            [3] = true,
            [4] = true,
            [5] = true,
            [6] = true,
            [7] = true,
            [8] = true,
            [9] = true
          }
        })
      },
      stats = {
        timescleared = 0,
      },
    },
  }]]

  CaveHandler:InitCave(DOTA_TEAM_GOODGUYS)
  CaveHandler:InitCave(DOTA_TEAM_BADGUYS)
end


function CaveHandler:InitCave (teamID)
  CaveHandler:ResetCave(teamID)
end

function CaveHandler:ResetCave (teamID)
  local cave = CaveHandler.caves[teamID]
  for roomName,room in pairs(cave) do
    CaveHandler:SpawnRoom(teamID, roomName)
    if roomName ~= "room1" then
      room.zone.enable()
    end
  end
end

function CaveHandler:SpawnRoom (teamID, roomName)
  local room = CaveHandler.caves[teamID][roomName]
  local creepList = CaveTypes[roomName][math.math.random(#CaveTypes[roomName])]
  for _,creep in ipairs(creepList.units) do
    local creepProperties = CaveHandler:GetCreepProperties(creep, creepList.multiplier)
    local creepHandle = CaveHandler:SpawnCreepInRoom(room.handle, creepProperties)
    creepHandle:OnDeath(function(keys)
      CaveHandler:CreepDeath(teamID, roomName)
    end)
    math.increase(room.creepCount)
  end
end

function CaveHandler:GetCreepProperties (creep, multiplier)
  local round = math.floor
  return {
    name = creep[1],
    hp = round(multiplier.hp(creep[2])),
    mana = round(multiplier.mana(creep[3])),
    damage = round(multiplier.damage(creep[4])),
    armour = round(multiplier.armour(creep[5])),
    gold = round(multiplier.armour(creep[6])),
    exp = round(multiplier.exp(creep[7])),
  }
end

function CaveHandler:SpawnCreepInRoom (room, properties)
  local creep = CreateUnitByName(properties.name, room:GetAbsOrigin(), true, nil, nil, DOTA_TEAM_NEUTRALS)

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

  --EXP BOUNTY
  creep:SetDeathXP(properties.exp)
end
