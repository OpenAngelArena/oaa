-- This module is for modifying vanilla abilities and modifiers through filters without reworking them completely
if ModifyAbilitiesFilter == nil then
  ModifyAbilitiesFilter = class({})
end

function ModifyAbilitiesFilter:Init()
  self.moduleName = "ModifyAbilitiesFilter"

  -- Requiem Fear duration manipulation and Requiem Fear immunity:
  LinkLuaModifier("modifier_oaa_requiem_allowed", "modifiers/modifyabilitiesfilter/requiem_fear_manager.lua", LUA_MODIFIER_MOTION_NONE)
  LinkLuaModifier("modifier_oaa_requiem_not_allowed", "modifiers/modifyabilitiesfilter/requiem_fear_manager.lua", LUA_MODIFIER_MOTION_NONE)
  -- Time Dilation additional effect:
  LinkLuaModifier("modifier_faceless_void_time_dilation_degen_oaa", "modifiers/modifyabilitiesfilter/time_dilation_degen.lua", LUA_MODIFIER_MOTION_NONE)
  -- Natural Order magic resistance reduction correction:
  LinkLuaModifier("modifier_elder_titan_natural_order_correction_oaa", "modifiers/modifyabilitiesfilter/natural_order_correction.lua", LUA_MODIFIER_MOTION_NONE)

  FilterManager:AddFilter(FilterManager.ModifierGained, self, Dynamic_Wrap(ModifyAbilitiesFilter, "ModifierFilter"))
  --FilterManager:AddFilter(FilterManager.TrackingProjectile, self, Dynamic_Wrap(ModifyAbilitiesFilter, "ProjectileFilter"))
  --FilterManager:AddFilter(FilterManager.AbilityTuningValue, self, Dynamic_Wrap(ModifyAbilitiesFilter, "TuningValuesFilter"))
end

function ModifyAbilitiesFilter:ModifierFilter(keys)
  if not keys.entindex_parent_const or not keys.entindex_caster_const or not keys.entindex_ability_const then
    return true
  end

  local caster = EntIndexToHScript(keys.entindex_caster_const)
  local victim = EntIndexToHScript(keys.entindex_parent_const)
  local ability = EntIndexToHScript(keys.entindex_ability_const)
  local modifier_name = keys.name_const
  local modifier_duration = keys.duration

  local ability_name = ability:GetName()

  if ability_name == "nevermore_requiem" and (modifier_name == "modifier_nevermore_requiem_slow" or modifier_name == "modifier_nevermore_requiem_fear") then
    if victim:HasModifier("modifier_oaa_requiem_not_allowed") then
      return false
    end
    if caster:HasScepter() and not victim:HasModifier("modifier_oaa_requiem_allowed") then
      local max_duration = ability:GetSpecialValueFor("requiem_slow_duration_max") + 1.5 * (ability:GetSpecialValueFor("requiem_radius") / ability:GetSpecialValueFor("requiem_line_speed"))
      local talent = caster:FindAbilityByName("special_bonus_unique_nevermore_6")
      if talent and talent:GetLevel() > 0 then
        max_duration = max_duration + talent:GetSpecialValueFor("value2")
      end
      victim:AddNewModifier(caster, ability, "modifier_oaa_requiem_allowed", {duration = math.min(max_duration, 6.5), immune_time = 3})
    end
  elseif ability_name == "faceless_void_time_dilation" and modifier_name == "modifier_faceless_void_time_dilation_slow" then
    victim:AddNewModifier(caster, ability, "modifier_faceless_void_time_dilation_degen_oaa", {duration = modifier_duration})
  elseif (ability_name == "elder_titan_natural_order" or ability_name == "elder_titan_natural_order_spirit") and modifier_name == "modifier_elder_titan_natural_order_magic_resistance" then
    if not victim:HasModifier("modifier_elder_titan_natural_order_correction_oaa") and ability:GetLevel() > 4 and not victim:IsOAABoss() then
      victim:AddNewModifier(caster, ability, "modifier_elder_titan_natural_order_correction_oaa", {})
    end
  elseif ability_name == "mirana_leap" and modifier_name == "modifier_mirana_leap_buff" then
    local duration = ability:GetSpecialValueFor("leap_bonus_duration")
    local talent = caster:FindAbilityByName("special_bonus_unique_mirana_3_oaa")
    if talent and talent:GetLevel() > 0 then
      keys.duration = duration + talent:GetSpecialValueFor("value")
    end
  end

  return true
end

function ModifyAbilitiesFilter:ProjectileFilter(keys)
  local source_index = keys.entindex_source_const
  local is_an_attack_projectile = keys.is_attack    -- values: 1 for yes or 0 for no

  local attacker
  if source_index then
    attacker = EntIndexToHScript(source_index)
  end

  if attacker and not attacker:IsNull() then
    if attacker:IsRealHero() and attacker:HasLearnedAbility("special_bonus_unique_wisp_4") and is_an_attack_projectile == 1 then
      if attacker:IsDisarmed() or attacker:IsStunned() or attacker:IsOutOfGame() or attacker:IsHexed() then
        return false
      end
    end
  end

  return true
end
