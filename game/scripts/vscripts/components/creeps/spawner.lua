-- Taken from bb template
if CreepCamps == nil then
    Debug.EnabledModules['creeps:*'] = false
    DebugPrint ( 'creating new CreepCamps object.' )
    CreepCamps = class({})
end

LinkLuaModifier("modifier_creep_loot", "modifiers/modifier_creep_loot.lua", LUA_MODIFIER_MOTION_NONE)

--creep power level is from CREEP_POWER_LEVEL_MIN to CREEP_POWER_LEVEL_MAX
local CreepPowerLevel = 0.0

--creep properties enumerations
local NAME_ENUM = 1
local HEALTH_ENUM = 2
local MANA_ENUM = 3
local DAMAGE_ENUM = 4
local ARMOR_ENUM = 5
local GOLD_BOUNTY_ENUM = 6
local EXP_BOUNTY_ENUM = 7

-- we want to set a timer to spawn creeps
-- the timer scans the map for all supported creep camps and spawns the creeps
-- profit

function CreepCamps:Init ()
  DebugPrint ( 'Initializing.' )
  CreepCamps = self
  self.CampPRDCounters = {}
  self.firstSpawn = true
  if not SKIP_TEAM_SETUP then
    HudTimer:At(INITIAL_CREEP_DELAY, partial(self.CreepSpawnTimer, self))
  else
    Timers:CreateTimer(Dynamic_Wrap(self, 'CreepSpawnTimer'), self)
  end

  Minimap:InitializeCampIcons()

  ChatCommand:LinkDevCommand("-spawncamps", Dynamic_Wrap(self, 'CreepSpawnTimer'), self)
end

function CreepCamps:GetState ()
  return {
    power = CreepPowerLevel
  }
end

function CreepCamps:LoadState (state)
  self:SetPowerLevel(state.power)
end

function CreepCamps:SetPowerLevel (powerLevel)
  CreepPowerLevel = powerLevel
end

function CreepCamps:CreepSpawnTimer ()
  -- scan for creep camps and spawn them
  -- DebugPrint('[creeps/spawner] Spawning creeps')
  local camps = Entities:FindAllByName('creep_camp')

  for _,camp in pairs(camps) do
    self:DoSpawn(camp:GetAbsOrigin(), camp:GetIntAttr('CreepType'), camp:GetIntAttr('CreepMax'))
  end

  self:UpgradeCreeps()

  Minimap:Respawn()

  if self.firstSpawn then
    HudTimer:OnThe(CREEP_SPAWN_INTERVAL, partial(self.CreepSpawnTimer, self))
    self.firstSpawn = false
  end
end

function CreepCamps:UpgradeCreeps ()
  -- upgrade creeps power level every time it triggers
  self:SetPowerLevel(CreepPowerLevel + 1)
end

function CreepCamps:DoSpawn (location, difficulty, maximumUnits)
  local creepCategory = CreepTypes[difficulty]
  local creepGroup = creepCategory[RandomInt(1, #creepCategory)]
  for i=1, #creepGroup do
    self:SpawnCreepInCamp (location, creepGroup[i], maximumUnits)
  end
end
function CreepCamps:SpawnCreepInCamp (location, creepProperties, maximumUnits)
  if creepProperties == nil then
    DebugPrint ('[creeps/spawner] unknown creep type ')
    return false
  end

  -- ( iTeamNumber, vPosition, hCacheUnit, flRadius, iTeamFilter, iTypeFilter, iFlagFilter, iOrder, bCanGrowCache )
  local units = FindUnitsInRadius(DOTA_TEAM_NEUTRALS,
    location,
    nil,
    800,
    DOTA_UNIT_TARGET_TEAM_FRIENDLY,
    DOTA_UNIT_TARGET_CREEP,
    DOTA_UNIT_TARGET_FLAG_NONE,
    FIND_ANY_ORDER,
    false)

  creepProperties = self:AdjustCreepPropertiesByPowerLevel( creepProperties, CreepPowerLevel )

  if (maximumUnits and maximumUnits <= #units) then
    -- DebugPrint('[creeps/spawner] Too many creeps in camp, not spawning more')
    for _,unit in pairs(units) do
      local unitProperties = self:GetCreepProperties(unit)
      local distributedScale = 1.0 / #units

      unitProperties = self:AddCreepPropertiesWithScale(unitProperties, 1.0, creepProperties, distributedScale)
      self:SetCreepPropertiesOnHandle(unit, unitProperties)
    end
    return false
  end

  local creepHandle = CreateUnitByName(creepProperties[NAME_ENUM], location, true, nil, nil, DOTA_TEAM_NEUTRALS)
  local locationString = location.x .. "," .. location.y

  if not self.CampPRDCounters[locationString] then
    self.CampPRDCounters[locationString] = 1
  end

  if creepHandle ~= nil then
    self:SetCreepPropertiesOnHandle(creepHandle, creepProperties)
    creepHandle:AddNewModifier(nil, nil, "modifier_creep_loot", {locationString = locationString})
  end

  return true
end

function CreepCamps:GetCreepProperties(creepHandle)
  local creepProperties = {}

  creepProperties[HEALTH_ENUM] = creepHandle:GetMaxHealth()
  creepProperties[MANA_ENUM] = creepHandle:GetMana()
  creepProperties[DAMAGE_ENUM] = (creepHandle:GetBaseDamageMin() + creepHandle:GetBaseDamageMax()) / 2
  creepProperties[ARMOR_ENUM] = creepHandle:GetPhysicalArmorBaseValue()
  creepProperties[GOLD_BOUNTY_ENUM] = (creepHandle:GetMinimumGoldBounty() + creepHandle:GetMaximumGoldBounty()) / 2
  creepProperties[EXP_BOUNTY_ENUM] = creepHandle:GetDeathXP()

  return creepProperties
end

function CreepCamps:AdjustCreepPropertiesByPowerLevel( creepProperties, powerLevel )
  local adjustedCreepProperties = {}
  local creepPowerTable = CreepPower:GetPowerForMinute(powerLevel)

  adjustedCreepProperties[NAME_ENUM] = creepProperties[NAME_ENUM]
  adjustedCreepProperties[HEALTH_ENUM] = creepProperties[HEALTH_ENUM] * creepPowerTable[HEALTH_ENUM]
  adjustedCreepProperties[MANA_ENUM] = creepProperties[MANA_ENUM] * creepPowerTable[MANA_ENUM]
  adjustedCreepProperties[DAMAGE_ENUM] = creepProperties[DAMAGE_ENUM] * creepPowerTable[DAMAGE_ENUM]
  adjustedCreepProperties[ARMOR_ENUM] = creepProperties[ARMOR_ENUM] * creepPowerTable[ARMOR_ENUM]
  adjustedCreepProperties[GOLD_BOUNTY_ENUM] = creepProperties[GOLD_BOUNTY_ENUM] * creepPowerTable[GOLD_BOUNTY_ENUM]
  adjustedCreepProperties[EXP_BOUNTY_ENUM] = creepProperties[EXP_BOUNTY_ENUM] * creepPowerTable[EXP_BOUNTY_ENUM]

  return adjustedCreepProperties
end

function CreepCamps:AddCreepPropertiesWithScale( propertiesOne, scaleOne, propertiesTwo, scaleTwo )
  local addedCreepProperties = {}

  addedCreepProperties[HEALTH_ENUM] = propertiesOne[HEALTH_ENUM] * scaleOne + propertiesTwo[HEALTH_ENUM] * scaleTwo
  if addedCreepProperties[HEALTH_ENUM] > propertiesTwo[HEALTH_ENUM] * CREEP_POWER_MAX then
    addedCreepProperties[HEALTH_ENUM] = propertiesTwo[HEALTH_ENUM] * CREEP_POWER_MAX
  end
  addedCreepProperties[MANA_ENUM] = propertiesOne[MANA_ENUM] * scaleOne + propertiesTwo[MANA_ENUM] * scaleTwo
  if addedCreepProperties[MANA_ENUM] > propertiesTwo[MANA_ENUM] * CREEP_POWER_MAX then
    addedCreepProperties[MANA_ENUM] = propertiesTwo[MANA_ENUM] * CREEP_POWER_MAX
  end
  addedCreepProperties[DAMAGE_ENUM] = propertiesOne[DAMAGE_ENUM] * scaleOne + propertiesTwo[DAMAGE_ENUM] * scaleTwo
  if addedCreepProperties[DAMAGE_ENUM] > propertiesTwo[DAMAGE_ENUM] * CREEP_POWER_MAX then
    addedCreepProperties[DAMAGE_ENUM] = propertiesTwo[DAMAGE_ENUM] * CREEP_POWER_MAX
  end
  addedCreepProperties[ARMOR_ENUM] = propertiesOne[ARMOR_ENUM] * scaleOne + propertiesTwo[ARMOR_ENUM] * scaleTwo
  if addedCreepProperties[ARMOR_ENUM] > propertiesTwo[ARMOR_ENUM] * CREEP_POWER_MAX then
    addedCreepProperties[ARMOR_ENUM] = propertiesTwo[ARMOR_ENUM] * CREEP_POWER_MAX
  end
  addedCreepProperties[GOLD_BOUNTY_ENUM] = propertiesOne[GOLD_BOUNTY_ENUM] * scaleOne + propertiesTwo[GOLD_BOUNTY_ENUM] * scaleTwo
  addedCreepProperties[EXP_BOUNTY_ENUM] = propertiesOne[EXP_BOUNTY_ENUM] * scaleOne + propertiesTwo[EXP_BOUNTY_ENUM] * scaleTwo

  return addedCreepProperties
end

function CreepCamps:SetCreepPropertiesOnHandle(creepHandle, creepProperties)
  --HEALTH
  local currentHealthMissing = creepHandle:GetMaxHealth() - creepHandle:GetHealth()
  local targetHealth = creepProperties[HEALTH_ENUM]

  if currentHealthMissing > 0 then
    targetHealth = math.max(1, creepProperties[HEALTH_ENUM] - currentHealthMissing)
  end

  creepHandle:SetBaseMaxHealth(math.ceil(creepProperties[HEALTH_ENUM]))
  creepHandle:SetMaxHealth(math.ceil(creepProperties[HEALTH_ENUM]))
  creepHandle:SetHealth(math.ceil(targetHealth))

  --MANA
  creepHandle:SetMana(math.ceil(creepProperties[MANA_ENUM]))

  --DAMAGE
  creepHandle:SetBaseDamageMin(math.ceil(creepProperties[DAMAGE_ENUM]))
  creepHandle:SetBaseDamageMax(math.ceil(creepProperties[DAMAGE_ENUM]))

  --ARMOR
  creepHandle:SetPhysicalArmorBaseValue(creepProperties[ARMOR_ENUM])

  --GOLD BOUNTY
  creepHandle:SetMinimumGoldBounty(math.ceil(creepProperties[GOLD_BOUNTY_ENUM]))
  creepHandle:SetMaximumGoldBounty(math.ceil(creepProperties[GOLD_BOUNTY_ENUM]))

  --EXP BOUNTY
  creepHandle:SetDeathXP(math.ceil(creepProperties[EXP_BOUNTY_ENUM]))
end
