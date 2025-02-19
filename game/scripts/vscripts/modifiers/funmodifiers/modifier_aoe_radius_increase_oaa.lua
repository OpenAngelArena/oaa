modifier_aoe_radius_increase_oaa = class(ModifierBaseClass)

function modifier_aoe_radius_increase_oaa:IsHidden()
  return false
end

function modifier_aoe_radius_increase_oaa:IsDebuff()
  return false
end

function modifier_aoe_radius_increase_oaa:IsPurgable()
  return false
end

function modifier_aoe_radius_increase_oaa:RemoveOnDeath()
  local parent = self:GetParent()
  if parent:IsRealHero() and not parent:IsOAABoss() then
    return false
  end
  return true
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
  arc_warden_flux = true,
  monkey_king_wukongs_command_oaa = true,
  phantom_assassin_blur = true,
  spectre_desolate = true,
  item_bloodstone = true,
  item_satanic_core_1 = true,
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

local forbidden_kvs = {
  ancient_apparition_ice_blast = {radius_grow = true,},
  --dawnbreaker_celestial_hammer = {hammer_aoe_radius = true,},
  grimstroke_soul_chain = {leash_radius_buffer = true,},
  --legion_commander_overwhelming_odds = {duel_radius_bonus = true,}, -- uncomment if flat change
  --leshrac_split_earth_oaa = {shard_extra_radius_per_instance = true,}, -- uncomment if flat change
  lich_frost_nova = {aoe_damage = true,},
  --pudge_rot = {scepter_rot_radius_bonus = true,}, -- uncomment if flat change
  sandking_epicenter = {epicenter_radius_increment = true, scepter_explosion_radius_pct = true,},
  sandking_sand_storm = {scepter_explosion_radius_pct = true,},
}

function modifier_aoe_radius_increase_oaa:OnCreated()
  self.aoe_multiplier = 1.5
  self:ReEquipAllItems()
end

function modifier_aoe_radius_increase_oaa:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_OVERRIDE_ABILITY_SPECIAL,
    MODIFIER_PROPERTY_OVERRIDE_ABILITY_SPECIAL_VALUE
  }
end

function modifier_aoe_radius_increase_oaa:OnDestroy()
  self:ReEquipAllItems()
end

function modifier_aoe_radius_increase_oaa:ReEquipAllItems()
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

  -- local neutral_item = parent:GetItemInSlot(DOTA_ITEM_NEUTRAL_SLOT)
  -- if neutral_item then
  --   neutral_item:OnUnequip()
  --   neutral_item:OnEquip()
  -- end
end

function modifier_aoe_radius_increase_oaa:GetModifierOverrideAbilitySpecial(keys)
  local ability = keys.ability
  if not ability or not keys.ability_special_value then
    return 0
  end

  if ignored_abilities and ignored_abilities[ability:GetAbilityName()] then
    return 0
  end

  if forbidden_kvs and forbidden_kvs[ability:GetAbilityName()] then
    local t = forbidden_kvs[ability:GetAbilityName()]
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

function modifier_aoe_radius_increase_oaa:GetModifierOverrideAbilitySpecialValue(keys)
  local ability = keys.ability
  local value = ability:GetLevelSpecialValueNoOverride(keys.ability_special_value, keys.ability_special_level)

  if ignored_abilities and ignored_abilities[ability:GetAbilityName()] then
    return value
  end

  if forbidden_kvs and forbidden_kvs[ability:GetAbilityName()] then
    local t = forbidden_kvs[ability:GetAbilityName()]
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

function modifier_aoe_radius_increase_oaa:GetTexture()
  return "void_spirit_dissimilate"
end
