
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

  if ability_data.AbilityType == "DOTA_ABILITY_TYPE_ULTIMATE" then
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
