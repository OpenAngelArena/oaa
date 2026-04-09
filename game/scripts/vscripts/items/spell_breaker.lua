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

  -- Basic Dispel (for enemies)
  local RemovePositiveBuffs = true
  local RemoveDebuffs = false
  local BuffsCreatedThisFrameOnly = false
  local RemoveStuns = false
  local RemoveExceptions = false
  target:Purge(RemovePositiveBuffs, RemoveDebuffs, BuffsCreatedThisFrameOnly, RemoveStuns, RemoveExceptions)

  -- Sound
  target:EmitSound("n_creep_SatyrSoulstealer.ManaBurn")

  local silence_duration = target:GetValueChangedByStatusResistance(self:GetSpecialValueFor("silence_duration"), caster, self)
  local debuff_duration = target:GetValueChangedByStatusResistance(self:GetSpecialValueFor("debuff_duration"), caster, self)

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
  end
end

function modifier_item_spell_breaker_active:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_OVERRIDE_ABILITY_SPECIAL,
    MODIFIER_PROPERTY_OVERRIDE_ABILITY_SPECIAL_VALUE,
  }
end

--[[
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
]]

local ignored_abilities = {
  arc_warden_flux = true,
  --monkey_king_wukongs_command_oaa = true,
  phantom_assassin_blur = true,
  spectre_desolate = true,
}

local forbidden_kvs = {
  ancient_apparition_ice_blast = {radius_grow = true,},
  dawnbreaker_celestial_hammer = {hammer_aoe_radius = true,},
  grimstroke_soul_chain = {leash_radius_buffer = true,},
  leshrac_split_earth_oaa = {shard_extra_radius_per_instance = true,},
  lich_frost_nova = {aoe_damage = true,},
  sandking_epicenter = {epicenter_radius_increment = true, scepter_explosion_radius_pct = true,},
}

function modifier_item_spell_breaker_active:GetModifierOverrideAbilitySpecial(keys)
  local ability = keys.ability
  local parent = self:GetParent()
  if not ability or not keys.ability_special_value then
    return 0
  end

  local name = ability:GetAbilityName()
  if not parent:FindAbilityByName(name) then
    return 0
  end

  if (ignored_abilities and ignored_abilities[name]) or ability:IsItem() then
    return 0
  end

  if forbidden_kvs and forbidden_kvs[name] then
    local t = forbidden_kvs[name]
    if t[keys.ability_special_value] then
      return 0
    end
  end

  --[[ -- uncomment this and disable GetAbilityKeyValuesByName if it lags too much
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
  ]]

  local ability_kvs = GetAbilityKeyValuesByName(name)
  if ability_kvs and ability_kvs.AbilityValues and ability_kvs.AbilityValues[keys.ability_special_value] then
    -- print("Keyvalue for ability: "..name)
    -- print("Key: "..tostring(keys.ability_special_value))
    -- print("Value: "..tostring(ability_kvs.AbilityValues[keys.ability_special_value]))
    if type(ability_kvs.AbilityValues[keys.ability_special_value]) == "table" then
      local affected_kv = ability_kvs.AbilityValues[keys.ability_special_value].affected_by_aoe_increase
      -- print("value of affected_by_aoe_increase: ")
      -- print(affected_kv)
      if affected_kv then
        if tonumber(affected_kv) == 1 then
          --print("Affected Key: "..tostring(keys.ability_special_value))
          --print("it is affected")
          return 1
        end
      end
    end
  end

  return 0
end

function modifier_item_spell_breaker_active:GetModifierOverrideAbilitySpecialValue(keys)
  local parent = self:GetParent()
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
  if not parent:FindAbilityByName(name) then
    return value
  end

  if (ignored_abilities and ignored_abilities[name]) or ability:IsItem() then
    return value
  end

  if forbidden_kvs and forbidden_kvs[name] then
    local t = forbidden_kvs[name]
    if t[keys.ability_special_value] then
      return value
    end
  end

  --[[ -- uncomment this and disable GetAbilityKeyValuesByName if it lags too much
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
  ]]

  local ability_kvs = GetAbilityKeyValuesByName(name)
  if ability_kvs and ability_kvs.AbilityValues and ability_kvs.AbilityValues[keys.ability_special_value] then
    if type(ability_kvs.AbilityValues[keys.ability_special_value]) == "table" then
      local affected_kv = ability_kvs.AbilityValues[keys.ability_special_value].affected_by_aoe_increase
      if affected_kv then
        if tonumber(affected_kv) == 1 then
          return value * self.aoe_multiplier
        end
      end
    end
  end

  return value
end

function modifier_item_spell_breaker_active:GetTexture()
  return "custom/spell_breaker_1"
end
