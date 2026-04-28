
function IsTalentCustom(ability)
  local ability_name
  if type(ability) == "string" then
    ability_name = ability
    if ability_name == "" then
      return false
    end
    local ability_data = GetAbilityKeyValuesByName(ability_name)
    if not ability_data then
      print("IsTalentCustom: Ability "..ability_name.." does not exist!")
      return false
    end
  else
    if not ability or ability:IsNull() then
      print("IsTalentCustom: Passed parameter does not exist!")
      return false
    end
    if not ability.GetAbilityName then
      print("IsTalentCustom: Passed parameter is not an ability!")
      return false
    end
    ability_name = ability:GetAbilityName()
  end

  return string.find(ability_name, "special_bonus_") and ability_name ~= "special_bonus_attributes"
end

function IsInnateCustom(ability)
  local ability_name
  if type(ability) == "string" then
    ability_name = ability
    if ability_name == "" then
      return false
    end
  else
    if not ability or ability:IsNull() then
      print("IsInnateCustom: Passed parameter does not exist!")
      return false
    end
    if not ability.GetAbilityName then
      print("IsInnateCustom: Passed parameter is not an ability!")
      return false
    end
    ability_name = ability:GetAbilityName()
  end

  local ability_data = GetAbilityKeyValuesByName(ability_name)
  if not ability_data then
    print("IsInnateCustom: Ability "..ability_name.." does not exist!")
    return false
  end

  if ability_data.Innate ~= nil then
    if tonumber(ability_data.Innate) == 1 then
      return true
    end
  end
  return false
end

function IsUltimateAbilityCustom(ability)
  local ability_name
  if type(ability) == "string" then
    ability_name = ability
    if ability_name == "" then
      return false
    end
  else
    if not ability or ability:IsNull() then
      print("IsUltimateAbilityCustom: Passed parameter does not exist!")
      return false
    end
    if not ability.GetAbilityName then
      print("IsUltimateAbilityCustom: Passed parameter is not an ability!")
      return false
    end
    ability_name = ability:GetAbilityName()
  end

  local ability_data = GetAbilityKeyValuesByName(ability_name)
  if not ability_data then
    print("IsUltimateAbilityCustom: Ability "..ability_name.." does not exist!")
    return false
  end

  if ability_data.AbilityType == nil then
    return false
  end

  if ability_data.AbilityType == "ABILITY_TYPE_ULTIMATE" then
    return true
  end

  return false
end

function IsFakeItemCustom(ability)
  local ability_name
  if type(ability) == "string" then
    ability_name = ability
    if ability_name == "" then
      return false
    end
  else
    if not ability or ability:IsNull() then
      print("IsFakeItemCustom: Passed parameter does not exist!")
      return false
    end
    if not ability.GetAbilityName then
      print("IsFakeItemCustom: Passed parameter is not an ability!")
      return false
    end
    ability_name = ability:GetAbilityName()
  end

  local ability_data = GetAbilityKeyValuesByName(ability_name)
  if not ability_data then
    print("IsFakeItemCustom: Ability "..ability_name.." does not exist!")
    return false
  end

  if ability_data.AbilityBehavior == nil then
    return false
  end

  local b = tostring(ability_data.AbilityBehavior)

  return string.find(b, "DOTA_ABILITY_BEHAVIOR_IS_FAKE_ITEM")
end

function IsAttackAbilityCustom(ability)
  local ability_name
  if type(ability) == "string" then
    ability_name = ability
    if ability_name == "" then
      return false
    end
  else
    if not ability or ability:IsNull() then
      print("IsAttackAbilityCustom: Passed parameter does not exist!")
      return false
    end
    if not ability.GetAbilityName then
      print("IsAttackAbilityCustom: Passed parameter is not an ability!")
      return false
    end
    ability_name = ability:GetAbilityName()
  end

  local ability_data = GetAbilityKeyValuesByName(ability_name)
  if not ability_data then
    print("IsAttackAbilityCustom: Ability "..ability_name.." does not exist!")
    return false
  end

  if ability_data.AbilityBehavior == nil then
    return false
  end

  local b = tostring(ability_data.AbilityBehavior)

  return string.find(b, "DOTA_ABILITY_BEHAVIOR_ATTACK")
end

-- Server-only
function AllowedToRefresh(ability, notDuel)
  if not ability or ability:IsNull() then
    print("AllowedToRefresh: Passed ability parameter does not exist!")
    return false
  end
  if type(ability) == "string" then
    print("AllowedToRefresh: Passed ability parameter is a string, strings are not supported for AllowedToRefresh!")
    return false
  end
  if not ability.GetAbilityName then
    print("AllowedToRefresh: Passed ability parameter is not an ability!")
    return false
  end
  -- notDuel is ommited in duels and savestate code
  if not notDuel then
    -- Non-ultimate abilities that shouldn't be refreshed in Duels
    local exempt_ability_table = {
      centaur_mount = true,
      centaur_work_horse = true,
      lycan_wolf_bite = true,
      shadow_demon_demonic_cleanse = true,
      undying_ceaseless_dirge = true,
    }
    return ability:GetAbilityType() ~= ABILITY_TYPE_ULTIMATE and not exempt_ability_table[ability:GetAbilityName()]
  else
    -- used in Refresher item code
    local exempt_ability_table = {
      --dazzle_good_juju = true,
      oaa_rearm = true,
      riki_permanent_invisibility = true,
      tinker_rearm = true,
      --treant_natures_guise = true,
      undying_ceaseless_dirge = true,
    }
    return not exempt_ability_table[ability:GetAbilityName()] and ability:IsRefreshable()
  end
end
