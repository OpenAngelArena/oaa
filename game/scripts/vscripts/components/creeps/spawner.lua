-- Taken from bb template
if CreepCamps == nil then
  Debug.EnabledModules['creeps:*'] = false
  DebugPrint ( 'creating new CreepCamps object.' )
  CreepCamps = class({})
end

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

local NEUTRAL_ABILITIES_UPGRADE_TIME = 7*60 -- every 7 minutes

-- we want to set a timer to spawn creeps
-- the timer scans the map for all supported creep camps and spawns the creeps
-- profit

function CreepCamps:Init ()
  self.moduleName = "CreepCamps Spawner"

  self.CampPRDCounters = {}
  self.firstSpawn = true
  if HudTimer then
    HudTimer:At(INITIAL_CREEP_DELAY, partial(self.CreepSpawnTimer, self))
  else
    Timers:CreateTimer(INITIAL_CREEP_DELAY, function()
      CreepCamps:CreepSpawnTimer()
	  --return CREEP_SPAWN_INTERVAL
    end)
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
  self.creep_upgrade_table = nil

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
  local units = FindUnitsInRadius(
    DOTA_TEAM_NEUTRALS,
    location,
    nil,
    400,
    DOTA_UNIT_TARGET_TEAM_FRIENDLY,
    DOTA_UNIT_TARGET_CREEP,
    DOTA_UNIT_TARGET_FLAG_NONE,
    FIND_ANY_ORDER,
    false
  )

  -- Upgrade creep abilities (edge cases: creeps that are out of the camp)
  for _, unit in pairs(units) do
    if unit then
      self:SetCreepAbilityLevels(unit)
    end
  end

  -- Properties of the creep that is supposed to spawn
  local newCreepProperties = self:AdjustCreepPropertiesByPowerLevel(creepProperties, CreepPowerLevel)

  -- Check if the camp is full
  if (maximumUnits and maximumUnits <= #units) then
    -- DebugPrint('[creeps/spawner] Too many creeps in camp, not spawning more')
    local distributedScale = 1.0 / #units
    local found = false
    -- In the full camp, upgrade creeps with the same name as the creep that is supposed to spawn
    for _, unit in pairs(units) do
      local unitProperties = self:GetCreepProperties(unit)
      -- Check if unit's name is equal to the name of the creep that was about to be spawned
      if unitProperties[NAME_ENUM] == newCreepProperties[NAME_ENUM] then
        found = true
        -- Upgrade only if that unit was not upgraded already in the previous instance of SpawnCreepInCamp
        if not self:IsAlreadyUpgradedAtThisMinute(unit, CreepPowerLevel) then
          --DebugPrint("Standard Upgrade for "..tostring(unitProperties[NAME_ENUM]).." with index "..tostring(unit:GetEntityIndex()).." at minute "..tostring(CreepPowerLevel))
          if unitProperties[NAME_ENUM] == "npc_dota_neutral_custom_black_dragon" then
            -- Change stats of the dragons in a unique way
            unitProperties = self:AddCreepPropertiesWithScale(unitProperties, 1.0, newCreepProperties, distributedScale)
          else
            -- Change stats of the old creep to be the same as the new creep (except gold and xp)
            unitProperties = self:UpgradeCreepProperties(unitProperties, newCreepProperties, 1.0)
          end
          self:SetCreepPropertiesOnHandle(unit, unitProperties)
          self:MarkAsUpgradedAtThisMinute(unit, CreepPowerLevel, true)
          --DebugPrint("XP bounty for "..tostring(unitProperties[NAME_ENUM]).." with index "..tostring(unit:GetEntityIndex()).." at minute "..tostring(CreepPowerLevel).." : ")
          --DebugPrint("Is "..tostring(unitProperties[EXP_BOUNTY_ENUM]).." equal to "..tostring(unit:GetDeathXP()))
        end
      end
    end

    -- If there were no units in the camp with the same name as the creep that is supposed to spawn then
    if not found then
      local scale = math.min(1/12, distributedScale)
      -- Upgrade all non-upgraded creeps based on max possible number of units in the camp (distributedScale)
      for _, unit in pairs(units) do
        local unitProperties = self:GetCreepProperties(unit)
        if not self:IsAlreadyUpgradedAtThisMinute(unit, CreepPowerLevel) and not self:AlreadyDidDistributedScaleUpgrade(unit, CreepPowerLevel) then
          --DebugPrint("Distributed Upgrade for "..tostring(unitProperties[NAME_ENUM]).." with index "..tostring(unit:GetEntityIndex()).." at minute "..tostring(CreepPowerLevel))
          unitProperties = self:UpgradeCreepProperties(unitProperties, unitProperties, scale)
          self:SetCreepPropertiesOnHandle(unit, unitProperties)
          self:MarkAsUpgradedAtThisMinute(unit, CreepPowerLevel, false)
          --DebugPrint("XP bounty for "..tostring(unitProperties[NAME_ENUM]).." with index "..tostring(unit:GetEntityIndex()).." at minute "..tostring(CreepPowerLevel).." : ")
          --DebugPrint("Is "..tostring(unitProperties[EXP_BOUNTY_ENUM]).." equal to "..tostring(unit:GetDeathXP()))
        end
      end
    end

    -- Don't create a new creep
    return false
  end

  -- Creating a new creep
  local creepHandle = CreateUnitByName(newCreepProperties[NAME_ENUM], location, true, nil, nil, DOTA_TEAM_NEUTRALS)
  local locationString = location.x .. "," .. location.y

  if not self.CampPRDCounters[locationString] then
    self.CampPRDCounters[locationString] = 1
  end

  if creepHandle ~= nil then
    self:SetCreepPropertiesOnHandle(creepHandle, newCreepProperties)
    creepHandle:AddNewModifier(creepHandle, nil, "modifier_creep_loot", {locationString = locationString}) -- this handles madstones too, not just bottles
    self:SetCreepAbilityLevels(creepHandle)
  end

  return true
end

function CreepCamps:GetCreepProperties(creepHandle)
  local creepProperties = {}

  creepProperties[NAME_ENUM] = creepHandle:GetUnitName()
  creepProperties[HEALTH_ENUM] = creepHandle:GetMaxHealth()
  creepProperties[MANA_ENUM] = creepHandle:GetMaxMana()
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
  adjustedCreepProperties[MANA_ENUM] = creepProperties[MANA_ENUM]
  adjustedCreepProperties[DAMAGE_ENUM] = creepProperties[DAMAGE_ENUM] * creepPowerTable[DAMAGE_ENUM]
  adjustedCreepProperties[ARMOR_ENUM] = creepProperties[ARMOR_ENUM] * creepPowerTable[ARMOR_ENUM]
  adjustedCreepProperties[GOLD_BOUNTY_ENUM] = creepProperties[GOLD_BOUNTY_ENUM] * creepPowerTable[GOLD_BOUNTY_ENUM]
  adjustedCreepProperties[EXP_BOUNTY_ENUM] = creepProperties[EXP_BOUNTY_ENUM] * creepPowerTable[EXP_BOUNTY_ENUM]

  return adjustedCreepProperties
end

function CreepCamps:AddCreepPropertiesWithScale( propertiesOne, scaleOne, propertiesTwo, scaleTwo )
  local addedCreepProperties = {}

  if propertiesOne[NAME_ENUM] ~= propertiesTwo[NAME_ENUM] then
    --DebugPrint("Upgrading a creep with stats of a different creep")
    return
  end

  addedCreepProperties[NAME_ENUM] = propertiesOne[NAME_ENUM]
  addedCreepProperties[HEALTH_ENUM] = propertiesOne[HEALTH_ENUM] * scaleOne + propertiesTwo[HEALTH_ENUM] * scaleTwo
  if addedCreepProperties[HEALTH_ENUM] > propertiesTwo[HEALTH_ENUM] * CREEP_POWER_MAX then
    addedCreepProperties[HEALTH_ENUM] = propertiesTwo[HEALTH_ENUM] * CREEP_POWER_MAX
  end
  addedCreepProperties[MANA_ENUM] = propertiesOne[MANA_ENUM]
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

function CreepCamps:UpgradeCreepProperties(propertiesOne, propertiesTwo, scale)
  local upgradedCreepProperties = {}

  if propertiesOne[NAME_ENUM] ~= propertiesTwo[NAME_ENUM] then
    --DebugPrint("Upgrading a creep with stats of a different creep.")
    return
  end

  upgradedCreepProperties[NAME_ENUM] = propertiesOne[NAME_ENUM]

  -- Never downgrade stats
  upgradedCreepProperties[HEALTH_ENUM] = math.max(propertiesOne[HEALTH_ENUM], propertiesTwo[HEALTH_ENUM] * scale)
  upgradedCreepProperties[MANA_ENUM] = propertiesOne[MANA_ENUM]
  upgradedCreepProperties[DAMAGE_ENUM] = math.max(propertiesOne[DAMAGE_ENUM], propertiesTwo[DAMAGE_ENUM] * scale)
  upgradedCreepProperties[ARMOR_ENUM] = math.max(propertiesOne[ARMOR_ENUM], propertiesTwo[ARMOR_ENUM] * scale)

  -- Sum up bounties
  upgradedCreepProperties[GOLD_BOUNTY_ENUM] = propertiesOne[GOLD_BOUNTY_ENUM] + propertiesTwo[GOLD_BOUNTY_ENUM] * scale
  upgradedCreepProperties[EXP_BOUNTY_ENUM] = propertiesOne[EXP_BOUNTY_ENUM] + propertiesTwo[EXP_BOUNTY_ENUM] * scale

  return upgradedCreepProperties
end

function CreepCamps:SetCreepPropertiesOnHandle(creepHandle, creepProperties)
  if not creepProperties then
    DebugPrint("creepProperties is nil. Usually when upgrading a creep with stats of a different creep.")
    return
  end
  --HEALTH
  local intendedMaxHealth = creepProperties[HEALTH_ENUM]
  local currentHealthPercent = creepHandle:GetHealth() / creepHandle:GetMaxHealth()
  local missingHealth = creepHandle:GetMaxHealth() - creepHandle:GetHealth()
  local targetHealth = math.max(1, currentHealthPercent * intendedMaxHealth, intendedMaxHealth - missingHealth)

  creepHandle:SetBaseMaxHealth(math.ceil(intendedMaxHealth))
  creepHandle:SetMaxHealth(math.ceil(intendedMaxHealth))
  creepHandle:SetHealth(math.ceil(targetHealth))

  --MANA
  --creepHandle:SetMaxMana(math.ceil(creepProperties[MANA_ENUM]))
  --creepHandle:SetMana(math.ceil(creepProperties[MANA_ENUM]))

  --DAMAGE
  creepHandle:SetBaseDamageMin(math.ceil(creepProperties[DAMAGE_ENUM]))
  creepHandle:SetBaseDamageMax(math.ceil(creepProperties[DAMAGE_ENUM]))

  --ARMOR
  creepHandle:SetPhysicalArmorBaseValue(creepProperties[ARMOR_ENUM])

  --GOLD BOUNTY
  creepHandle:SetMinimumGoldBounty(math.ceil(creepProperties[GOLD_BOUNTY_ENUM]))
  creepHandle:SetMaximumGoldBounty(math.ceil(creepProperties[GOLD_BOUNTY_ENUM]))

  --EXP BOUNTY
  creepHandle:SetDeathXP(math.floor(creepProperties[EXP_BOUNTY_ENUM]))
end

function CreepCamps:MarkAsUpgradedAtThisMinute(creepHandle, minute, found)
  if self.creep_upgrade_table == nil then
    self.creep_upgrade_table = {}
  end

  local index = creepHandle:GetEntityIndex()
  if self.creep_upgrade_table[index] == nil then
    self.creep_upgrade_table[index] = {}
  end

  if self.creep_upgrade_table[index][minute] == nil then
    self.creep_upgrade_table[index][minute] = {}
  end

  if found then
    self.creep_upgrade_table[index][minute][1] = true
  else
    self.creep_upgrade_table[index][minute][2] = true
  end
end

function CreepCamps:IsAlreadyUpgradedAtThisMinute(creepHandle, minute)
  if self.creep_upgrade_table == nil then
    return false
  end

  local index = creepHandle:GetEntityIndex()
  if self.creep_upgrade_table[index] == nil then
    return false
  end

  if self.creep_upgrade_table[index][minute] == nil then
    return false
  end

  if self.creep_upgrade_table[index][minute][1] == true then
    return true
  end

  return false
end

function CreepCamps:AlreadyDidDistributedScaleUpgrade(creepHandle, minute)
  if self.creep_upgrade_table == nil then
    return false
  end

  local index = creepHandle:GetEntityIndex()
  if self.creep_upgrade_table[index] == nil then
    return false
  end

  if self.creep_upgrade_table[index][minute] == nil then
    return false
  end

  if self.creep_upgrade_table[index][minute][2] == true then
    return true
  end

  return false
end

function CreepCamps:SetCreepAbilityLevels(creepHandle)
  if HudTimer:GetGameTime() < NEUTRAL_ABILITIES_UPGRADE_TIME then
    for i = 0, creepHandle:GetAbilityCount() - 1 do
      local ability = creepHandle:GetAbilityByIndex(i)
      if ability then
        ability:SetLevel(1)
      end
    end
  elseif HudTimer:GetGameTime() >= NEUTRAL_ABILITIES_UPGRADE_TIME and HudTimer:GetGameTime() < 2*NEUTRAL_ABILITIES_UPGRADE_TIME then
    for i = 0, creepHandle:GetAbilityCount() - 1 do
      local ability = creepHandle:GetAbilityByIndex(i)
      if ability then
        ability:SetLevel(2)
      end
    end
  elseif HudTimer:GetGameTime() >= 2*NEUTRAL_ABILITIES_UPGRADE_TIME and HudTimer:GetGameTime() < 3*NEUTRAL_ABILITIES_UPGRADE_TIME then
    for i = 0, creepHandle:GetAbilityCount() - 1 do
      local ability = creepHandle:GetAbilityByIndex(i)
      if ability then
        ability:SetLevel(3)
      end
    end
  elseif HudTimer:GetGameTime() >= 3*NEUTRAL_ABILITIES_UPGRADE_TIME then
    for i = 0, creepHandle:GetAbilityCount() - 1 do
      local ability = creepHandle:GetAbilityByIndex(i)
      if ability then
        ability:SetLevel(4)
      end
    end
  end
end
