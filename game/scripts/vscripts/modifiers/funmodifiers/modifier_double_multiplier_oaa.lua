modifier_double_multiplier_oaa = class(ModifierBaseClass)

function modifier_double_multiplier_oaa:IsHidden()
  return false
end

function modifier_double_multiplier_oaa:IsDebuff()
  return false
end

function modifier_double_multiplier_oaa:IsPurgable()
  return false
end

function modifier_double_multiplier_oaa:RemoveOnDeath()
  local parent = self:GetParent()
  if parent:IsRealHero() and not parent:IsOAABoss() then
    return false
  end
  return true
end

function modifier_double_multiplier_oaa:OnCreated()
  self.multiplier = 2
  if IsServer() then
    self:SetStackCount(self.multiplier)
  end
end

function modifier_double_multiplier_oaa:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_OVERRIDE_ABILITY_SPECIAL,
    MODIFIER_PROPERTY_OVERRIDE_ABILITY_SPECIAL_VALUE,
    MODIFIER_PROPERTY_STATUS_RESISTANCE_CASTER,
    --MODIFIER_PROPERTY_SPELL_AMPLIFY_PERCENTAGE,
    MODIFIER_PROPERTY_TOTALDAMAGEOUTGOING_PERCENTAGE,
  }
end

local aoe_keywords = {
  aoe = true,
  area_of_effect = true,
  radius = true,
}

local ignored_abilities = {
  --arc_warden_flux = true,
  monkey_king_wukongs_command_oaa = true,
  --phantom_assassin_blur = true,
  --spectre_desolate = true,
}

local affected_kvs = {
  scepter_range = true,
  arrow_range_multiplier = true,
  wave_width = true,
  aftershock_range = true,
  echo_slam_damage_range = true,
  echo_slam_echo_search_range = true,
  echo_slam_echo_range = true,
  torrent_max_distance = true,
  cleave_ending_width = true,
  cleave_distance = true,
  ghostship_width = true,
  dragon_slave_distance = true,
  dragon_slave_width_initial = true,
  dragon_slave_width_end = true,
  width = true,
  arrow_width = true,
  requiem_line_width_start = true,
  requiem_line_width_end = true,
  orb_vision = true,
  hook_distance = true,
  flesh_heap_range = true,
  hook_width = true,
  end_distance = true,
  burrow_width = true,
  splash_width = true,
  splash_range = true,
  jump_range = true,
  bounce_range = true,
  attack_spill_range = true,
  attack_spill_width = true,
  dash_width = true,
  AbilityCooldown = true,
  AbilityManaCost = true,
  AbilityCastRange = true,
}

function modifier_double_multiplier_oaa:GetModifierOverrideAbilitySpecial(keys)
  local ability = keys.ability
  if not ability or not keys.ability_special_value then
    return 0
  end

  if ignored_abilities and ignored_abilities[ability:GetAbilityName()] then
    return 0
  end

  if ability:IsItem() then
    return 0
  end

  if aoe_keywords then
    for keyword, _ in pairs(aoe_keywords) do
      if string.find(keys.ability_special_value, keyword) then
        return 1
      end
    end
  end

  if affected_kvs and affected_kvs[keys.ability_special_value] then
    return 1
  end

  return 0
end

function modifier_double_multiplier_oaa:GetModifierOverrideAbilitySpecialValue(keys)
  local ability = keys.ability
  if not keys.ability_special_value or not keys.ability_special_level then
    return
  end

  local value = ability:GetLevelSpecialValueNoOverride(keys.ability_special_value, keys.ability_special_level)

  if ignored_abilities and ignored_abilities[ability:GetAbilityName()] then
    return value
  end

  if ability:IsItem() then
    return value
  end

  if aoe_keywords then
    for keyword, _ in pairs(aoe_keywords) do
      if string.find(keys.ability_special_value, keyword) then
        return value * self.multiplier
      end
    end
  end

  if affected_kvs and affected_kvs[keys.ability_special_value] then
    return value * self.multiplier
  end

  return value
end

if IsServer() then
  function modifier_double_multiplier_oaa:GetModifierStatusResistanceCaster()
    return 0 - ((self.multiplier - 1) * 100)
  end
end

-- function modifier_double_multiplier_oaa:GetModifierSpellAmplify_Percentage()
  -- return (self.multiplier - 1) * 100
-- end

function modifier_double_multiplier_oaa:GetModifierTotalDamageOutgoing_Percentage()
  return (self.multiplier - 1) * 100
end

function modifier_double_multiplier_oaa:GetTexture()
  return "item_talisman_of_evasion"
end
