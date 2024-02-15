LinkLuaModifier("modifier_item_spell_breaker_passive", "items/spell_breaker.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_spell_breaker_active", "items/spell_breaker.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_spell_breaker_silence", "items/spell_breaker.lua", LUA_MODIFIER_MOTION_NONE)

--------------------------------------------------------------------------------

item_spell_breaker_1 = class(ItemBaseClass)

function item_spell_breaker_1:GetIntrinsicModifierName()
  return "modifier_intrinsic_multiplexer"
end

function item_spell_breaker_1:GetIntrinsicModifierNames()
  return {
    "modifier_item_mage_slayer",
    "modifier_item_spell_breaker_passive",
  }
end

function item_spell_breaker_1:OnSpellStart()
  local caster = self:GetCaster()
  local target = self:GetCursorTarget()

  -- Don't do anything if target has Linken's effect or it's spell-immune
  if target:TriggerSpellAbsorb(self) or target:IsMagicImmune() then
    return
  end

  -- Basic Dispel for enemies
  local RemovePositiveBuffs = true
  local RemoveDebuffs = false
  local BuffsCreatedThisFrameOnly = false
  local RemoveStuns = false
  local RemoveExceptions = false
  target:Purge(RemovePositiveBuffs, RemoveDebuffs, BuffsCreatedThisFrameOnly, RemoveStuns, RemoveExceptions)

  -- Sound
  target:EmitSound("n_creep_SatyrSoulstealer.ManaBurn")

  local silence_duration = self:GetSpecialValueFor("silence_duration")
  local debuff_duration = target:GetValueChangedByStatusResistance(self:GetSpecialValueFor("debuff_duration"))

  -- Apply mini-silence
  target:AddNewModifier(caster, self, "modifier_item_spell_breaker_silence", {duration = silence_duration})

  -- Apply Spell Breaker debuff
  target:AddNewModifier(caster, self, "modifier_item_spell_breaker_active", {duration = debuff_duration})

  -- Apply Mage Slayer debuff
  target:AddNewModifier(caster, self, "modifier_item_mage_slayer_debuff", {duration = debuff_duration})
end

item_spell_breaker_2 = item_spell_breaker_1
item_spell_breaker_3 = item_spell_breaker_1
item_spell_breaker_4 = item_spell_breaker_1
item_spell_breaker_5 = item_spell_breaker_1

---------------------------------------------------------------------------------------------------

modifier_item_spell_breaker_passive = class(ModifierBaseClass)

function modifier_item_spell_breaker_passive:IsHidden()
  return true
end

function modifier_item_spell_breaker_passive:IsDebuff()
  return false
end

function modifier_item_spell_breaker_passive:IsPurgable()
  return false
end

function modifier_item_spell_breaker_passive:GetAttributes()
  return MODIFIER_ATTRIBUTE_MULTIPLE
end

function modifier_item_spell_breaker_passive:OnCreated()
  self:OnRefresh()
end

function modifier_item_spell_breaker_passive:OnRefresh()
  local ability = self:GetAbility()
  if ability and not ability:IsNull() then
    self.damage = ability:GetSpecialValueFor("bonus_attack_damage")
  end
end

function modifier_item_spell_breaker_passive:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
  }
end

function modifier_item_spell_breaker_passive:GetModifierPreAttack_BonusDamage()
  return self.damage or self:GetAbility():GetSpecialValueFor("bonus_attack_damage")
end

---------------------------------------------------------------------------------------------------

modifier_item_spell_breaker_silence = class(ModifierBaseClass)

function modifier_item_spell_breaker_silence:IsHidden()
  return false
end

function modifier_item_spell_breaker_silence:IsDebuff()
  return true
end

function modifier_item_spell_breaker_silence:IsPurgable()
  return true
end

function modifier_item_spell_breaker_silence:CheckState()
  return {
    [MODIFIER_STATE_SILENCED] = true,
  }
end

---------------------------------------------------------------------------------------------------

modifier_item_spell_breaker_active = class(ModifierBaseClass)

function modifier_item_spell_breaker_active:IsHidden()
  return false
end

function modifier_item_spell_breaker_active:IsDebuff()
  return true
end

function modifier_item_spell_breaker_active:IsPurgable()
  return true
end

function modifier_item_spell_breaker_active:OnCreated()
  self:OnRefresh()
end

function modifier_item_spell_breaker_active:OnRefresh()
  local ability = self:GetAbility()
  if ability and not ability:IsNull() then
    self.aoe_multiplier = (100 - ability:GetSpecialValueFor("aoe_decrease_percent"))/100
    self.spell_lifesteal_reduction = ability:GetSpecialValueFor("spell_lifesteal_reduction")
  end
end

function modifier_item_spell_breaker_active:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_SPELL_LIFESTEAL_AMPLIFY_PERCENTAGE,
    MODIFIER_PROPERTY_OVERRIDE_ABILITY_SPECIAL,
    MODIFIER_PROPERTY_OVERRIDE_ABILITY_SPECIAL_VALUE,
  }
end

function modifier_item_spell_breaker_active:GetModifierSpellLifestealRegenAmplify_Percentage()
  return 0 - math.abs(self.spell_lifesteal_reduction)
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
  --monkey_king_wukongs_command_oaa = true,
  phantom_assassin_blur = true,
  spectre_desolate = true,
}

local forbidden_kvs = {
  ancient_apparition_ice_blast = {radius_grow = true,},
  --dawnbreaker_celestial_hammer = {hammer_aoe_radius = true,},
  grimstroke_soul_chain = {leash_radius_buffer = true,},
  --legion_commander_overwhelming_odds = {duel_radius_bonus = true,}, -- uncomment if flat change
  --leshrac_split_earth_oaa = {shard_extra_radius_per_instance = true,}, -- uncomment if flat change
  lich_frost_nova = {aoe_damage = true,},
  --pudge_rot = {scepter_rot_radius_bonus = true,}, -- uncomment if flat change
  sandking_epicenter = {epicenter_radius_increment = true,},
  sandking_sand_storm = {scepter_explosion_radius_pct = true,},
}

function modifier_item_spell_breaker_active:GetModifierOverrideAbilitySpecial(keys)
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

function modifier_item_spell_breaker_active:GetModifierOverrideAbilitySpecialValue(keys)
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

function modifier_item_spell_breaker_active:GetTexture()
  return "custom/spell_breaker_1"
end
