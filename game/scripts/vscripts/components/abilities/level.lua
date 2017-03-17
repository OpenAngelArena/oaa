-- Taken from bb template
if AbilityLevels == nil then
    DebugPrint ( 'creating new ability level requirement object.' )
    AbilityLevels = class({})
    Debug.EnabledModules["abilities:*"] = true
end

function AbilityLevels:Init ()
  GameRules:GetGameModeEntity():SetExecuteOrderFilter(Dynamic_Wrap(AbilityLevels, "FilterAbilityUpgradeOrder"), nil)
end

function AbilityLevels:FilterAbilityUpgradeOrder (keys)
  -- Immediately return true if intercepted order isn't an ability upgrade order
  if keys.order_type ~= DOTA_UNIT_ORDER_TRAIN_ABILITY then
    return true
  end

  -- Ability hero level requirements
  local basicLevel5Req = 28
  local basicLevel6Req = 40
  local ultimateLevel4Req = 37
  local ultimateLevel5Req = 49

  local ability = EntIndexToHScript(keys.entindex_ability)
  local player = PlayerResource:GetPlayer(keys.issuer_player_id_const)
  local hero = EntIndexToHScript(keys.units["0"])
  local heroLevel = hero:GetLevel()
  local abilityLevel = ability:GetLevel()
  local abilityType = ability:GetAbilityType()
  local abilityCanUpgrade = true
  local requriedHeroLevel = -1

  if abilityType == 0 then -- Ability is DOTA_ABILITY_TYPE_BASIC
    if abilityLevel >= 4 and heroLevel < basicLevel5Req then
      abilityCanUpgrade = false
      requiredHeroLevel = basicLevel5Req
    elseif abilityLevel >= 5 and heroLevel < basicLevel6Req then
      abilityCanUpgrade = false
      requiredHeroLevel = basicLevel6Req
    end
  elseif abilityType == 1 then -- Ability is DOTA_ABILITY_TYPE_ULTIMATE
    if abilityLevel >= 3 and heroLevel < ultimateLevel4Req then
      abilityCanUpgrade = false
      requiredHeroLevel = ultimateLevel4Req
    elseif abilityLevel >= 4 and heroLevel < ultimateLevel5Req then
      abilityCanUpgrade = false
      requiredHeroLevel = ultimateLevel5Req
    end
  end

  if abilityCanUpgrade then
    return true
  else
    -- Send event to client to display error message about hero level requirement
    CustomGameEventManager:Send_ServerToPlayer(player, "ability_level_error", {requiredLevel = requiredHeroLevel})
    -- Return false to reject ability upgrade order
    return false
  end
end
