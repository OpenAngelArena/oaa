-- Taken from bb template
if AbilityLevels == nil then
    DebugPrint ( 'creating new ability level requirement object.' )
    AbilityLevels = class({})
end

function AbilityLevels:Init ()
  GameEvents:OnPlayerLearnedAbility(Dynamic_Wrap(AbilityLevels, 'OnPlayerLearnedAbility'))
end

function AbilityLevels.OnPlayerLearnedAbility (keys, keys2)
  DebugPrint('Checking ability on level up if it should be in-level-uped')
  local player = EntIndexToHScript(keys.player)
  if player == nil then
    return
  end
  local hero = player:GetAssignedHero()
  if not hero then
    return
  end

  local heroLevel = hero:GetLevel()
  local ability = hero:FindAbilityByName(keys.abilityname)
  local abilityLevel = ability:GetLevel()
  local abilityKV = ability:GetAbilityKeyValues()

  -- 28 / 40
  -- 37 / 49
  if abilityKV['AbilityType'] == 'DOTA_ABILITY_TYPE_BASIC' then
    if abilityLevel >= 5 and heroLevel < 28 then
      ability:SetLevel(4)
      hero:SetAbilityPoints(hero:GetAbilityPoints() + 1)
    elseif abilityLevel >= 6 and heroLevel < 40 then
      ability:SetLevel(5)
      hero:SetAbilityPoints(hero:GetAbilityPoints() + 1)
    end
  elseif abilityKV['AbilityType'] == 'DOTA_ABILITY_TYPE_ULTIMATE' then
    if abilityLevel >= 4 and heroLevel < 37 then
      ability:SetLevel(3)
      hero:SetAbilityPoints(hero:GetAbilityPoints() + 1)
    elseif abilityLevel >= 5 and heroLevel < 49 then
      ability:SetLevel(4)
      hero:SetAbilityPoints(hero:GetAbilityPoints() + 1)
    end
  end
end
