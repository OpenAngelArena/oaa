
-- Taken from bb template
if CreepCamps == nil then
    DebugPrint ( '[creeps/spawner] creating new CreepCamps object' )
    CreepCamps = class({})
end

-- we want to set a timer to spawn creeps
-- the timer scans the map for all supported creep camps and spawns the creeps
-- profit
CreepTypes = {
  -- 1
  {
    "npc_dota_neutral_kobold",
    "npc_dota_neutral_kobold_taskmaster",
    "npc_dota_neutral_kobold_tunneler"
  },
  -- 2
  {
    "npc_dota_neutral_harpy_storm",
    "npc_dota_neutral_harpy_scout"
  }
  -- ...
}

function CreepCamps:Init ()
  CreepCamps = self
  Timers:CreateTimer(Dynamic_Wrap(CreepCamps, 'CreepTimer'))
end

function CreepCamps:CreepTimer ()
  -- scan for creep camps and spawn them
  DebugPrint('[creeps/spawner] Spawning creeps')
  local camps = Entities:FindAllByName('creep_camp')
  for _,camp in pairs(camps) do
    local numberOfCreeps = math.random(2, 5)

    for i=1,numberOfCreeps do
      CreepCamps:DoSpawn(camp:GetAbsOrigin(), camp:GetIntAttr('CreepType'), camp:GetIntAttr('CreepMax'))
    end
  end

  return 10.0
end

function CreepCamps:DoSpawn (location, difficulty, maximumUnits)
  local creepType = CreepTypes[difficulty]
  creepType = creepType[math.random(#creepType)]

  -- ( iTeamNumber, vPosition, hCacheUnit, flRadius, iTeamFilter, iTypeFilter, iFlagFilter, iOrder, bCanGrowCache )
  local units = FindUnitsInRadius(DOTA_TEAM_NEUTRALS,
    location,
    nil,
    1000,
    DOTA_UNIT_TARGET_TEAM_FRIENDLY,
    DOTA_UNIT_TARGET_CREEP,
    DOTA_UNIT_TARGET_FLAG_NONE,
    FIND_ANY_ORDER,
    false)

  if (maximumUnits and maximumUnits < #units)
  then
    DebugPrint('[creeps/spawner] Too many creeps in camp, not spawning more')
    return false
  end

  CreateUnitByName(creepType, location, true, nil, nil, DOTA_TEAM_NEUTRALS)

  return true
end
