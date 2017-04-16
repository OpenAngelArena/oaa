
if CaveHandler == nil then
    Debug.EnabledModules['cave:cave'] = true
    DebugPrint ('creating new CaveHandler object.')
    CaveHandler = class({})
end


function CaveHandler:Init ()
  DebugPrint ('Initializing.')

  CaveHandler.caves = {}

  for teamID=DOTA_TEAM_GOODGUYS,DOTA_TEAM_BADGUYS do
    CaveHandler.caves[teamID] = {
      timescleared = 0,
      rooms = {}
    }

    for roomID=1,4 do
      CaveHandler.caves[teamID].rooms[roomID] = {
        handle = Entities:FindByName(nil, "cave_" .. GetShortTeamName(teamID) .. "_room_" .. roomID),
        creepCount = 0,
        zone = ZoneControl:CreateZone("cave_" .. GetShortTeamName(teamID) .. "_zone_" .. roomID, {
          mode = ZONE_CONTROL_EXCLUSIVE_OUT,
          players = tomap(zip(PlayerResource:GetAllTeamPlayerIDs(), duplicate(true)))
        })
      }
    end
  end

  CaveHandler:InitCave(DOTA_TEAM_GOODGUYS)
  CaveHandler:InitCave(DOTA_TEAM_BADGUYS)
end


function CaveHandler:InitCave (teamID)
  CaveHandler.caves[teamID].rooms[1].zone.disable()
  CaveHandler:ResetCave(teamID)
end

function CaveHandler:ResetCave (teamID)
  local cave = CaveHandler.caves[teamID]

  for roomID,room in pairs(cave.rooms) do
    CaveHandler:SpawnRoom(teamID, roomID)
    if roomID > 1 then
      room.zone.enable()
    end
  end
end

function CaveHandler:SpawnRoom (teamID, roomID)
  DebugPrint('Spawning room ' .. roomID .. ' of team ' .. GetTeamName(teamID))

  local cave = CaveHandler.caves[teamID]
  local room = cave.rooms[roomID]
  local creepList = CaveTypes[roomID][math.random(#CaveTypes[roomID])]

  for _,creep in ipairs(creepList.units) do -- spawn all creeps in list
    -- get properties for the creep
    local creepProperties = CaveHandler:GetCreepProperties(creep, creepList.multiplier, cave.timescleared)

    -- spawn the creep
    local creepHandle = CaveHandler:SpawnCreepInRoom(room.handle, creepProperties)

    if roomID == 4 then
      creepHandle:SetModelScale( creepHandle:GetModelScale() / (0.5  * (cave.timescleared + 1)) )
    end

    creepHandle:OnDeath(function(keys)
      CaveHandler:CreepDeath(teamID, roomID)
    end)

    room.creepCount = room.creepCount + 1
  end
end

function CaveHandler:GetCreepProperties (creep, multiplier, k)
  local round = math.floor
  return {
    name   =                              creep[1],
    hp     = round(multiplier.hp(k)     * creep[2]),
    mana   = round(multiplier.mana(k)   * creep[3]),
    damage = round(multiplier.damage(k) * creep[4]),
    armour = round(multiplier.armour(k) * creep[5]),
    gold   = round(multiplier.gold(k)   * creep[6]),
    exp    = round(multiplier.exp(k)    * creep[7]),
    magicResist    = round(multiplier.magicResist(k)    * creep[8]),
  }
end

function CaveHandler:SpawnCreepInRoom (room, properties, lastRoom)
  local creep = CreateUnitByName(
    properties.name,      -- name
    room:GetAbsOrigin(),  -- location
    true,                 --
    nil,                  --
    nil,                  --
    DOTA_TEAM_NEUTRALS    -- team
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
  local cave = CaveHandler.caves[teamID]
  local room = cave.rooms[roomID]

  room.creepCount = room.creepCount - 1

  if room.creepCount == 0 then -- all creeps are dead
    DebugPrint('Room ' .. roomID .. ' of Team ' .. GetTeamName(teamID) .. ' got cleared.')

    if roomID < 4 then -- last room
      -- let players advance to next room
      DebugPrint('Opening next room.')
      cave.rooms[roomID + 1].zone.disable()
      -- inform players
      Notifications:TopToTeam(teamID,{
        text="Room " .. roomID .. " got cleared. You can now advance to the next room",
        duration=5,
      })
    else
      -- give all players gold
      local bounty = CaveHandler:GiveBounty(teamID, cave.timescleared)

      -- teleport player back to base
      CaveHandler:KickPlayers(teamID)

      -- reset cave
      Timers:CreateTimer(4, function ()
        CaveHandler:ResetCave(teamID)
      end)

      cave.timescleared = cave.timescleared + 1
      -- inform players
      Notifications:TopToTeam(teamID,{
        text="Your last Room got cleared. Every player on your Team got " .. bounty .. " gold",
        duration=10,
        continue=true
      })
      Notifications:TopToTeam(teamID,{
        text="You have cleared the Cave " .. cave.timescleared .. " times. The Cave is resetting now.",
        duration=10,
      })
    end
  end
end

function CaveHandler:GiveBounty (teamID, k)
  local roshGold = CaveTypes[4][1].units[1][7]
  local roshCount = #CaveTypes[4][1].units
  local playerCount = PlayerResource:GetPlayerCountForTeam(teamID)
  each(DebugPrint, PlayerResource:GetPlayerIDsForTeam(teamID))
  local round = math.floor

  local pool = (56 * k^2 + 85 * k + 37) / 37 * roshGold * roshCount
  local bounty = round(pool / playerCount)
  DebugPrint("Giving " .. playerCount .. " players " .. bounty .. " gold each from a pool of " .. pool .. " gold.")

  each(function(playerID)
    PlayerResource:ModifyGold(
      playerID,                  -- player
      bounty,                    -- amount
      true,                      -- is reliable gold
      DOTA_ModifyGold_RoshanKill -- reason
    )
  end, PlayerResource:GetPlayerIDsForTeam(teamID))

  return bounty
end

function CaveHandler:KickPlayers (teamID)
  DebugPrint('Kicking Players out of the cave.')

  local cave = CaveHandler.caves[teamID]
  local spawns = {
    [DOTA_TEAM_GOODGUYS] = Entities:FindByClassname(nil, 'info_player_start_goodguys'):GetAbsOrigin(),
    [DOTA_TEAM_BADGUYS]  = Entities:FindByClassname(nil, 'info_player_start_badguys' ):GetAbsOrigin(),
  }
  local units = {}

  -- get all heroes in all rooms
  for roomID,room in pairs(cave.rooms) do
    local radius = max(
      max(room.zone.bounds.Mins.x, room.zone.bounds.Maxs.x),
      max(room.zone.bounds.Mins.y, room.zone.bounds.Maxs.y)
    )
    DebugPrint('Looking for units in room ' .. roomID .. ' in a ' .. radius .. ' radius.')

    for team=DOTA_TEAM_GOODGUYS,DOTA_TEAM_BADGUYS do
      local result = FindUnitsInRadius(
        team,                           -- team
        room.zone.origin,               -- location
        nil,                            -- cache
        radius,                         -- radius
        DOTA_UNIT_TARGET_TEAM_FRIENDLY, -- team filter
        DOTA_UNIT_TARGET_ALL,           -- type filter
        DOTA_UNIT_TARGET_FLAG_NONE,     -- flag filter
        FIND_ANY_ORDER,                 -- order
        false                           -- can grow cache
      )
      for _,unit in pairs(result) do
        table.insert(units, unit)
      end
    end
  end

  DebugPrint('Teleporting units now')

  for _,unit in pairs(units) do
    local origin = ParticleManager:CreateParticle(
      'particles/econ/events/ti6/teleport_start_ti6_lvl3.vpcf', -- particle path
      PATTACH_ABSORIGIN_FOLLOW,                                 -- attach point
      unit                                                      -- owner
    )

    local target  = ParticleManager:CreateParticle(
      'particles/econ/events/ti6/teleport_end_ti6_lvl3.vpcf', -- particle path
      PATTACH_CUSTOMORIGIN,                                     -- attach point
      unit                                                      -- owner
    )
    ParticleManager:SetParticleControl(target, 0, spawns[unit:GetTeamNumber()])

    Timers:CreateTimer(3, function ()
      FindClearSpaceForUnit(
        unit,                         -- unit
        spawns[unit:GetTeamNumber()], -- location
        false                         -- ???
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
