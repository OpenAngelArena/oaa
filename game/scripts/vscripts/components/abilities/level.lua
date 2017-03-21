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
  local basic_reqs = {0, 0, 0, 0, 28, 40}
  local ultimate_reqs = {0, 0, 0, 37, 49}

  local ability = EntIndexToHScript(keys.entindex_ability)
  local player = PlayerResource:GetPlayer(keys.issuer_player_id_const)
  local hero = EntIndexToHScript(keys.units["0"])
  local heroLevel = hero:GetLevel()
  local abilityLevel = ability:GetLevel()
  local abilityType = ability:GetAbilityType()

  if abilityType == 0 then -- Ability is DOTA_ABILITY_TYPE_BASIC
    req_table = basic_reqs
  elseif abilityType == 1 then -- Ability is DOTA_ABILITY_TYPE_ULTIMATE
    req_table = ultimate_reqs
  end
  
  if abilityLevel >= #req_table then
    requirement = req_table[#req_table]
  else
    requirement = req_table[abilityLevel+1]
  end
  
  if heroLevel >= requirement then
    return true
  else
    -- Send event to client to display error message about hero level requirement
    CustomGameEventManager:Send_ServerToPlayer(player, "ability_level_error", {requiredLevel = requirement})
    -- Return false to reject ability upgrade order
    return false
  end
end
