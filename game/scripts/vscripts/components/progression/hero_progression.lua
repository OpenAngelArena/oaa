if HeroProgression == nil then
    HeroProgression = class({})
    Debug.EnabledModules['progression:*'] = false

    ChatCommand:LinkCommand("-levelup", "OnLevelUpChatCmd", HeroProgression)
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
  if illusionEnt.IsIllusion and illusionEnt:IsIllusion() and illusionEnt:IsHero() then
    -- Set one frame delay because illusions won't immediately have the correct level
    Timers:CreateTimer(function()
      local currentHealth = illusionEnt:GetHealth()
      local currentMana = illusionEnt:GetMana()
      local illusionLevel = illusionEnt:GetLevel()
      -- No need to do anything if the illusion isn't above level 25
      if illusionLevel <= 25 then
        return
      end

      function CalculateStatAt25(unitLevel, currentBaseStat, statGain)
        return currentBaseStat - (unitLevel - 25) * statGain
      end

      function CalculateReducedStat(unitLevel, statAt25, statGain)
        return statGain * 12 * math.log((2 * (unitLevel - 13) + 1) / (2 * 13 - 1)) + statAt25
      end

      function SetBaseStat(statName, statValue)
        illusionEnt["SetBase" .. statName](illusionEnt, statValue)
      end

      local statGains = {
        illusionEnt:GetStrengthGain(),
        illusionEnt:GetAgilityGain(),
        illusionEnt:GetIntellectGain()
      }
      local currentBaseStats = {
        illusionEnt:GetBaseStrength(),
        illusionEnt:GetBaseAgility(),
        illusionEnt:GetBaseIntellect()
      }
      local statNames = {
        "Strength",
        "Agility",
        "Intellect"
      }
      -- Calculate stats after reduction, set them, and call CalculateStatBonus to update health, mana, damage, etc.
      local statsAt25 = map(partial(CalculateStatAt25, illusionLevel), zip(currentBaseStats, statGains))
      local reducedStats = map(partial(CalculateReducedStat, illusionLevel), zip(statsAt25, statGains))
      foreach(SetBaseStat, zip(statNames, reducedStats))
      illusionEnt:CalculateStatBonus()
      -- Set health and mana back to the values the illusison spawned with
      illusionEnt:SetHealth(currentHealth)
      illusionEnt:SetMana(currentMana)
    end)
  end
end

function HeroProgression:ShouldGetAnAbilityPoint(hero, level)
  pattern = HeroProgression.customLevellingPatterns[hero:GetName()]
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

function HeroProgression:OnLevelUpChatCmd(keys)
  local hero = PlayerResource:GetSelectedHeroEntity(keys.playerid)
  DebugPrint('Levelling up ' .. hero:GetName() .. ' now at level ' .. hero:GetLevel())
  hero:HeroLevelUp(true)
end
