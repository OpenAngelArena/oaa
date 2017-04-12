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
