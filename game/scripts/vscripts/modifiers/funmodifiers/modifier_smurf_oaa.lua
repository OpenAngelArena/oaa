
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
  self:ReEquipAllItems()
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
}

local ignored_abilities = {
  --arc_warden_flux = true,
  --monkey_king_wukongs_command_oaa = true,
  --phantom_assassin_blur = true,
  --spectre_desolate = true,
  item_bloodstone = true,
  item_satanic_core = true,
  item_satanic_core_2 = true,
  item_satanic_core_3 = true,
  item_satanic_core_4 = true,
  item_satanic_core_5 = true,
  item_spell_breaker_1 = true,
  item_spell_breaker_2 = true,
  item_spell_breaker_3 = true,
  item_spell_breaker_4 = true,
  item_spell_breaker_5 = true,
}

function modifier_smurf_oaa:OnDestroy()
  self:ReEquipAllItems()
end

function modifier_smurf_oaa:ReEquipAllItems()
  if not IsServer() then
    return
  end

  local parent = self:GetParent()

  for i = DOTA_ITEM_SLOT_1, DOTA_ITEM_SLOT_6 do
    local item = parent:GetItemInSlot(i)
    if item then
      local name = item:GetAbilityName()
      if not string.find(name, "ultimate_scepter") and not string.find(name, "aghanims_scepter") then
        item:OnUnequip()
        item:OnEquip()
      end
    end
  end

  local tp_scroll = parent:GetItemInSlot(DOTA_ITEM_TP_SCROLL)
  if tp_scroll and tp_scroll:GetAbilityName() == "item_tpscroll" then
    tp_scroll:OnUnequip()
    tp_scroll:OnEquip()
  end

  local neutral_item = parent:GetItemInSlot(DOTA_ITEM_NEUTRAL_SLOT)
  if neutral_item and neutral_item:IsNeutralDrop() then
    neutral_item:OnUnequip()
    neutral_item:OnEquip()
  end
end

function modifier_smurf_oaa:GetModifierOverrideAbilitySpecial(keys)
  if not keys.ability or not keys.ability_special_value then
    return 0
  end

  if ignored_abilities and ignored_abilities[keys.ability:GetAbilityName()] then
    return 0
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
  local value = keys.ability:GetLevelSpecialValueNoOverride(keys.ability_special_value, keys.ability_special_level)

  if ignored_abilities and ignored_abilities[keys.ability:GetAbilityName()] then
    return value
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
  return "custom/reduction_orb"
end
