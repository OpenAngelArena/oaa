-- This module is for modifying vanilla abilities and modifiers through filters without reworking them completely
if ModifyAbilitiesFilter == nil then
  ModifyAbilitiesFilter = class({})
end

function ModifyAbilitiesFilter:Init()
  self.moduleName = "ModifyAbilitiesFilter"

  FilterManager:AddFilter(FilterManager.ModifierGained, self, Dynamic_Wrap(ModifyAbilitiesFilter, "ModifierFilter"))
  --FilterManager:AddFilter(FilterManager.TrackingProjectile, self, Dynamic_Wrap(ModifyAbilitiesFilter, "ProjectileFilter"))
  --FilterManager:AddFilter(FilterManager.AbilityTuningValue, self, Dynamic_Wrap(ModifyAbilitiesFilter, "TuningValuesFilter"))
end

function ModifyAbilitiesFilter:ModifierFilter(keys)
  -- Remove fountain invulnerability
  if keys.name_const == "modifier_fountain_invulnerability" then
    return false
  end

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
      victim:AddNewModifier(caster, ability, "modifier_oaa_requiem_allowed", {duration = math.min(max_duration, 6.5), immune_time = 2})
    end
  elseif ability_name == "faceless_void_time_dilation" and modifier_name == "modifier_faceless_void_time_dilation_slow" then
    victim:AddNewModifier(caster, ability, "modifier_faceless_void_time_dilation_degen_oaa", {duration = modifier_duration})
  elseif (ability_name == "elder_titan_natural_order" or ability_name == "elder_titan_natural_order_spirit") and modifier_name == "modifier_elder_titan_natural_order_magic_resistance" then
    if not victim:HasModifier("modifier_elder_titan_natural_order_correction_oaa") and ability:GetLevel() > 4 and not victim:IsOAABoss() then
      victim:AddNewModifier(caster, ability, "modifier_elder_titan_natural_order_correction_oaa", {})
    end
  elseif ability_name == "tidehunter_anchor_smash" and modifier_name == "modifier_tidehunter_anchor_smash" and victim:IsOAABoss() then
    victim:AddNewModifier(caster, ability, "modifier_tidehunter_anchor_smash_oaa_boss", {duration = modifier_duration})
    return false
  elseif modifier_name == "modifier_windrunner_windrun_invis" then
    victim:AddNewModifier(caster, ability, "modifier_windranger_scepter_oaa", {duration = modifier_duration})
    return false
  elseif modifier_name == "modifier_muerta_pierce_the_veil_buff" then
    victim:AddNewModifier(caster, ability, "modifier_muerta_pierce_the_veil_penalty_oaa", {duration = modifier_duration})
  elseif modifier_name == "modifier_skeleton_king_reincarnation_scepter_active" then
    victim:AddNewModifier(caster, ability, "modifier_wraith_form_penalty_oaa", {duration = modifier_duration})
  elseif modifier_name == "modifier_legion_commander_duel" and caster:HasScepter() then
    if victim ~= caster then
      victim:AddNewModifier(caster, ability, "modifier_legion_duel_debuff_oaa", {duration = modifier_duration})
    -- else
      -- victim:AddNewModifier(caster, ability, "modifier_legion_duel_buff_oaa", {duration = modifier_duration})
    end
  elseif ability_name == "viper_viper_strike" and modifier_name ~= "modifier_viper_viper_strike_silence" then
    local talent = caster:FindAbilityByName("special_bonus_unique_viper_3_oaa")
    if talent and talent:GetLevel() > 0 then
      -- Basic Dispel (for enemies)
      local RemovePositiveBuffs = true
      local RemoveDebuffs = false
      local BuffsCreatedThisFrameOnly = false
      local RemoveStuns = false
      local RemoveExceptions = false
      victim:Purge(RemovePositiveBuffs, RemoveDebuffs, BuffsCreatedThisFrameOnly, RemoveStuns, RemoveExceptions)
      -- Viper Strike Silences
      victim:AddNewModifier(caster, ability, "modifier_viper_viper_strike_silence", {duration = modifier_duration})
    end
  elseif modifier_name == "modifier_mars_arena_of_blood_leash" and victim ~= caster then
    local facet = caster:GetHeroFacetID()
    if tostring(facet) == "2" then
      victim:AddNewModifier(caster, ability, "modifier_mars_arena_of_blood_leash_oaa", {})
    end
  elseif modifier_name == "modifier_wisp_relocate_return" then
    victim:AddNewModifier(caster, ability, "modifier_wisp_relocate_shield_oaa", {})
  elseif modifier_name == "modifier_bristleback_warpath_active" then
    victim:AddNewModifier(caster, ability, "modifier_bristleback_seeing_red_oaa", {duration = modifier_duration})
  elseif modifier_name == "modifier_slark_shadow_dance_aura" then
    victim:AddNewModifier(caster, ability, "modifier_slark_shadow_dance_oaa", {duration = modifier_duration})
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
