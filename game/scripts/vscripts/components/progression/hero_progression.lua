if HeroProgression == nil then
    HeroProgression = class({})
    Debug.EnabledModules['progression:*'] = false

    ChatCommand:LinkCommand("-levelup", "OnLevelUpChatCmd", HeroProgression)
end

function HeroProgression:RegisterCustomLevellingPatterns()
  HeroProgression.customLevellingPatterns = {}

  HeroProgression.customLevellingPatterns['npc_dota_hero_invoker'] = (function(level)
    -- Invoker gets all dem ability points
    return true
  end)
end

function HeroProgression:Init()
  HeroProgression = self

  self:RegisterCustomLevellingPatterns()
  GameEvents:OnPlayerLevelUp(function (keys)
    local player = EntIndexToHScript(keys.player)
    local level = keys.level
    local hero = player:GetAssignedHero()

    self:ReduceStatGain(hero, level)
    self:ProcessAbilityPointGain(hero, level)
  end)
  GameEvents:OnNPCSpawned(function(keys)
    local npc = EntIndexToHScript(keys.entindex)
    self:ReduceIllusionStats(npc)
  end)
end

function HeroProgression:ReduceStatGain(hero, level)
  if level > 25 then
    local div = (level - 25 + 12) / 12

    local gainStr = hero:GetStrengthGain()
    local gainAgi = hero:GetAgilityGain()
    local gainInt = hero:GetIntellectGain()

    local newStr = gainStr / div
    local newAgi = gainAgi / div
    local newInt = gainInt / div

    hero:ModifyStrength(newStr - gainStr)
    hero:ModifyAgility(newAgi - gainAgi)
    hero:ModifyIntellect(newInt - gainInt)
  end
end

function HeroProgression:ReduceIllusionStats(illusionEnt)
  if illusionEnt.IsIllusion and illusionEnt:IsIllusion() and illusionEnt:IsHero() then
    -- Set short delay because illusions won't immediately have the correct level
    Timers:CreateTimer(.02, function()
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
