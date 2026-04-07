
modifier_smurf_oaa = class(ModifierBaseClass)

function modifier_smurf_oaa:IsHidden()
  return false
end

function modifier_smurf_oaa:IsDebuff()
  return false
end

function modifier_smurf_oaa:IsPurgable()
  return false
end

function modifier_smurf_oaa:RemoveOnDeath()
  return false
end

function modifier_smurf_oaa:OnCreated()
  self.bonus_str_per_lvl = 5
  self.scale = -50
  self.aoe_multiplier = 0.75
end

function modifier_smurf_oaa:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
    MODIFIER_PROPERTY_MODEL_SCALE,
    MODIFIER_PROPERTY_OVERRIDE_ABILITY_SPECIAL,
    MODIFIER_PROPERTY_OVERRIDE_ABILITY_SPECIAL_VALUE,
  }
end

function modifier_smurf_oaa:GetModifierBonusStats_Strength()
  local parent = self:GetParent()
  return self.bonus_str_per_lvl * parent:GetLevel()
end

function modifier_smurf_oaa:GetModifierModelScale()
  return self.scale
end

local aoe_keywords = {
  aoe = true,
  area_of_effect = true,
  radius = true,
}

local other_keywords = {
  aftershock_range = true,
  arrow_range_multiplier = true,
  arrow_width = true,
  attack_spill_range = true,
  attack_spill_width = true,
  bounce_range = true,
  burrow_width = true,
  cleave_distance = true,
  cleave_ending_width = true,
  dash_width = true,
  dragon_slave_distance = true,
  dragon_slave_width_end = true,
  dragon_slave_width_initial = true,
  echo_slam_damage_range = true,
  echo_slam_echo_range = true,
  echo_slam_echo_search_range = true,
  end_distance = true,
  flesh_heap_range = true,
  ghostship_width = true,
  hook_distance = true,
  hook_width = true,
  jump_range = true,
  orb_vision = true,
  requiem_line_width_end = true,
  requiem_line_width_start = true,
  scepter_range = true,
  splash_range = true,
  splash_width = true,
  torrent_max_distance = true,
  wave_width = true,
  width = true,
}

local ignored_abilities = {
  --arc_warden_flux = true,
  --monkey_king_wukongs_command_oaa = true,
  --phantom_assassin_blur = true,
  --spectre_desolate = true,
}

local forbidden_kvs = {
  ancient_apparition_ice_blast = {radius_grow = true,},
  dawnbreaker_celestial_hammer = {hammer_aoe_radius = true,},
  grimstroke_soul_chain = {leash_radius_buffer = true,},
  leshrac_split_earth_oaa = {shard_extra_radius_per_instance = true,},
  lich_frost_nova = {aoe_damage = true,},
  sandking_epicenter = {epicenter_radius_increment = true, scepter_explosion_radius_pct = true,},
}

function modifier_smurf_oaa:GetModifierOverrideAbilitySpecial(keys)
  local ability = keys.ability
  if not ability or not keys.ability_special_value then
    return 0
  end

  local name = ability:GetAbilityName()
  if (ignored_abilities and ignored_abilities[name]) or ability:IsItem() then
    return 0
  end

  if forbidden_kvs and forbidden_kvs[name] then
    local t = forbidden_kvs[name]
    if t[keys.ability_special_value] then
      return 0
    end
  end

  if aoe_keywords then
    for keyword, _ in pairs(aoe_keywords) do
      if string.find(keys.ability_special_value, keyword) then
        return 1
      end
    end
  end

  if other_keywords and other_keywords[keys.ability_special_value] then
    return 1
  end

  return 0
end

function modifier_smurf_oaa:GetModifierOverrideAbilitySpecialValue(keys)
  local ability = keys.ability
  if not ability or not keys.ability_special_value then
    return 0
  end

  local value = ability:GetLevelSpecialValueNoOverride(keys.ability_special_value, keys.ability_special_level)
  if not value then
    return 0
  end
  if value == 0 then
    return 0
  end

  local name = ability:GetAbilityName()
  if (ignored_abilities and ignored_abilities[name]) or ability:IsItem() then
    return value
  end

  if forbidden_kvs and forbidden_kvs[name] then
    local t = forbidden_kvs[name]
    if t[keys.ability_special_value] then
      return value
    end
  end

  if aoe_keywords then
    for keyword, _ in pairs(aoe_keywords) do
      if string.find(keys.ability_special_value, keyword) then
        return value * self.aoe_multiplier
      end
    end
  end

  if other_keywords and other_keywords[keys.ability_special_value] then
    return value * self.aoe_multiplier
  end

  return value
end

function modifier_smurf_oaa:GetTexture()
  return "custom/modifiers/smurf"
end
