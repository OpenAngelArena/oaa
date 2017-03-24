if HeroProgression == nil then
    HeroProgression = class({})
    Debug.EnabledModules['progression:*'] = true
end

function HeroProgression:Init ()
    HeroProgression = self

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

function HeroProgression:ShouldGetAnAbilityPoint(level)
    -- After level 25 hero gets an additional skill point every 3 levels
    return level < 25 or math.fmod(level, 3) == 1
end

function HeroProgression:ProcessAbilityPointGain(hero, level)
    DebugPrint('Processing the ability point for ' .. hero:GetName() .. ' @ level ' .. level)
    if not self:ShouldGetAnAbilityPoint(level) then
        DebugPrint('...taken it away!')
        hero:SetAbilityPoints(hero:GetAbilityPoints() - 1)
    end
end
