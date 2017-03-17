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

  DebugPrint( "heroLevel: " .. heroLevel )
  DebugPrintTable( ability )
  DebugPrint( "abilityLevel: " .. abilityLevel )
  DebugPrint( "abilityType: " .. abilityKV['AbilityType'] )

  -- 28 / 40
  -- 37 / 49
  if abilityKV['AbilityType'] == 'DOTA_ABILITY_TYPE_BASIC' then
    if abilityLevel >= 5 and heroLevel < 28 then
      ability:SetLevel(4)
      hero:SetAbilityPoints(hero:GetAbilityPoints() + 1)
      AbilityLevels:sendLevelToast(player, 28)
    elseif abilityLevel >= 6 and heroLevel < 40 then
      ability:SetLevel(5)
      hero:SetAbilityPoints(hero:GetAbilityPoints() + 1)
      AbilityLevels:sendLevelToast(player, 40)
    end
  elseif abilityKV['AbilityType'] == 'DOTA_ABILITY_TYPE_ULTIMATE' then
    if abilityLevel >= 4 and heroLevel < 37 then
      ability:SetLevel(3)
      hero:SetAbilityPoints(hero:GetAbilityPoints() + 1)
      AbilityLevels:sendLevelToast(player, 37)
    elseif abilityLevel >= 5 and heroLevel < 49 then
      ability:SetLevel(4)
      hero:SetAbilityPoints(hero:GetAbilityPoints() + 1)
      AbilityLevels:sendLevelToast(player, 49)
    end
  end
end

function AbilityLevels:sendLevelToast (player, neededLevel)
  Notifications:RemoveBottom(player, 1)
  Notifications:Bottom(player, {
    text="You need to be level " .. neededLevel .. " to level this ability up!",
    duration=2.5,
    style={
      color="red",
      --border="1px solid black"
    }
  })
end
