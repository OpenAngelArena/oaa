if HeroProgression == nil then
    HeroProgression = class({})
    Debug.EnabledModules['progression:*'] = false
end

GameEvents:OnPlayerLevelUp(function(keys)
  local player = EntIndexToHScript(keys.player)
  local level = keys.level
  local hero = player:GetAssignedHero()

  HeroProgression:ReduceStatGain(hero, level)
  HeroProgression:ProcessAbilityPointGain(hero, level)
end)
GameEvents:OnNPCSpawned(function(keys)
  local npc = EntIndexToHScript(keys.entindex)
  HeroProgression:ReduceIllusionStats(npc)
end)

function HeroProgression:RegisterCustomLevellingPatterns()
  self.customLevellingPatterns = {}

  self.customLevellingPatterns['npc_dota_hero_invoker'] = (function(level)
    -- Invoker gets all dem ability points
    return true
  end)
end

function HeroProgression:Init()
  self.statNames = {
    "Strength",
    "Agility",
    "Intellect"
  }

  FilterManager:AddFilter(FilterManager.ModifyExperience, self, Dynamic_Wrap(HeroProgression, "ExperienceFilter"))
  self:RegisterCustomLevellingPatterns()
end

function HeroProgression.GetBaseStat(entity, statName)
  return entity["GetBase" .. statName](entity)
end

function HeroProgression.SetBaseStat(entity, statName, statValue)
  entity["SetBase" .. statName](entity, statValue)
end

function HeroProgression.GetStatGain(entity, statName)
  return entity["Get" .. statName .. "Gain"](entity)
end

function HeroProgression.ModifyStat(entity, statName, modifyAmount)
  entity["Modify" .. statName](entity, modifyAmount)
end

function HeroProgression:ReduceStatGain(hero, level)
  if level > 25 then
    local div = (level - 25 + 12) / 12

    local statGains = map(partial(self.GetStatGain, hero), self.statNames)

    local newStats = map(operator.div, zip(statGains, duplicate(div)))
    local statModifications = map(operator.sub, zip(newStats, statGains))

    foreach(partial(self.ModifyStat, hero), zip(self.statNames, statModifications))
  end
end

function HeroProgression:ReduceIllusionStats(illusionEnt)
  -- Support functions
  local function CalculateStatAt25(unitLevel, currentBaseStat, statGain)
    return currentBaseStat - (unitLevel - 25) * statGain
  end

  local function CalculateReducedStat(unitLevel, statAt25, statGain)
    return statGain * 12 * math.log((2 * (unitLevel - 13) + 1) / (2 * 13 - 1)) + statAt25
  end

  local GetBaseStat = partial(self.GetBaseStat, illusionEnt)
  local SetBaseStat = partial(self.SetBaseStat, illusionEnt)
  local GetStatGain = partial(self.GetStatGain, illusionEnt)

  -- Set one frame delay because illusions won't immediately have the correct level
  local function ReduceStats()
    Timers:CreateTimer(function()
      local currentHealth = illusionEnt:GetHealth()
      local currentMana = illusionEnt:GetMana()
      local illusionLevel = illusionEnt:GetLevel()
      -- No need to do anything if the illusion isn't above level 25
      -- Or if the illusion is a Hybrid
      if illusionLevel <= 25 or illusionEnt:HasModifier("modifier_morph_hybrid_special") then
        return
      end

      local statGains = map(GetStatGain, self.statNames)
      local currentBaseStats = map(GetBaseStat, self.statNames)

      -- Calculate stats after reduction, set them, and call CalculateStatBonus to update health, mana, damage, etc.
      local statsAt25 = illusionEnt.statsAt25 or map(partial(CalculateStatAt25, illusionLevel), zip(currentBaseStats, statGains))
      -- Save level 25 stats as a property on the illusion entity the first time that entity is handled by this function
      -- Mainly used for Arc Warden Tempest Double because it's a persistent entity
      if illusionEnt:IsTempestDouble() then
        illusionEnt.statsAt25 = illusionEnt.statsAt25 or totable(statsAt25)
      end
      local reducedStats = map(partial(CalculateReducedStat, illusionLevel), zip(statsAt25, statGains))

      -- Don't modify strength and agility of Morphling illusions
      if illusionEnt:GetName() == "npc_dota_hero_morphling" then
        SetBaseStat("Intellect", nth(3, reducedStats))
      else
        foreach(SetBaseStat, zip(self.statNames, reducedStats))
      end
      illusionEnt:CalculateStatBonus()
      -- Set health and mana back to the values the illusion spawned with
      illusionEnt:SetHealth(currentHealth)
      illusionEnt:SetMana(currentMana)
    end)
  end

  -- Note: Will not run on very first spawn of Tempest Double in a game due to the flag only being set on the next frame
  if illusionEnt.IsIllusion and (illusionEnt:IsIllusion() or illusionEnt:IsTempestDouble()) and illusionEnt:IsHero() then
    ReduceStats()
  else
    -- Double check for Tempest Double with one frame delay to catch first spawn
    Timers:CreateTimer(function()
      if not illusionEnt:IsNull() and illusionEnt.IsTempestDouble and illusionEnt:IsTempestDouble() then
        ReduceStats()
      end
    end)
  end
end

function HeroProgression:ShouldGetAnAbilityPoint(hero, level)
  local pattern = HeroProgression.customLevellingPatterns[hero:GetName()]
  if pattern == nil then
    -- After level 25 most heros get an additional skill point every 3 levels
    return level < 25 or math.fmod(level, 3) == 1
  else
    -- Hero levelling up has a custom levelling pattern
    -- (e.g. Invoker who gets all the skillpoints every level)
    return pattern(level)
  end
end

function HeroProgression:ProcessAbilityPointGain(hero, level)
  DebugPrint('Processing the ability point for ' .. hero:GetName() .. ' at level ' .. level)
  if not self:ShouldGetAnAbilityPoint(hero, level) then
    DebugPrint('...taken it away! (had ' .. hero:GetAbilityPoints() .. ' ability points)')
    hero:SetAbilityPoints(hero:GetAbilityPoints() - 1)
  end
end

function HeroProgression:ExperienceFilter(keys)
  local playerID = keys.player_id_const

  return PlayerResource:GetConnectionState(playerID) == DOTA_CONNECTION_STATE_CONNECTED
end
