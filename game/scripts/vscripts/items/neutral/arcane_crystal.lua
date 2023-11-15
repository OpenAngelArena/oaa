LinkLuaModifier("modifier_item_arcane_crystal_passive", "items/neutral/arcane_crystal.lua", LUA_MODIFIER_MOTION_NONE)

item_arcane_crystal = class(ItemBaseClass)

function item_arcane_crystal:GetIntrinsicModifierName()
  return "modifier_item_arcane_crystal_passive"
end

---------------------------------------------------------------------------------------------------

modifier_item_arcane_crystal_passive = class(ModifierBaseClass)

function modifier_item_arcane_crystal_passive:IsHidden()
  return true
end

function modifier_item_arcane_crystal_passive:IsDebuff()
  return false
end

function modifier_item_arcane_crystal_passive:IsPurgable()
  return false
end

function modifier_item_arcane_crystal_passive:OnCreated()
  local ability = self:GetAbility()
  if ability and not ability:IsNull() then
    self.stats = ability:GetSpecialValueFor("bonus_all_stats")
    self.spell_amp = ability:GetSpecialValueFor("bonus_spell_amp")
    self.cdr = ability:GetSpecialValueFor("cooldown_reduction")
    self.heal_amp = ability:GetSpecialValueFor("bonus_heal_amp")
    self.cast_time_reduction = ability:GetSpecialValueFor("cast_pct_improvement")
    self.debuff_amp = ability:GetSpecialValueFor("debuff_amp")
  end
end

modifier_item_arcane_crystal_passive.OnRefresh = modifier_item_arcane_crystal_passive.OnCreated

function modifier_item_arcane_crystal_passive:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
    MODIFIER_PROPERTY_STATS_AGILITY_BONUS,
    MODIFIER_PROPERTY_STATS_INTELLECT_BONUS,
    MODIFIER_PROPERTY_SPELL_AMPLIFY_PERCENTAGE,
    MODIFIER_PROPERTY_COOLDOWN_PERCENTAGE,
    MODIFIER_PROPERTY_HEAL_AMPLIFY_PERCENTAGE_SOURCE,
    MODIFIER_PROPERTY_HEAL_AMPLIFY_PERCENTAGE_TARGET,
    MODIFIER_PROPERTY_CASTTIME_PERCENTAGE,
    MODIFIER_PROPERTY_STATUS_RESISTANCE_CASTER,
  }
end

function modifier_item_arcane_crystal_passive:GetModifierBonusStats_Strength()
  return self.stats or self:GetAbility():GetSpecialValueFor("bonus_all_stats")
end

function modifier_item_arcane_crystal_passive:GetModifierBonusStats_Agility()
  return self.stats or self:GetAbility():GetSpecialValueFor("bonus_all_stats")
end

function modifier_item_arcane_crystal_passive:GetModifierBonusStats_Intellect()
  return self.stats or self:GetAbility():GetSpecialValueFor("bonus_all_stats")
end

function modifier_item_arcane_crystal_passive:GetModifierSpellAmplify_Percentage()
  return self.spell_amp or self:GetAbility():GetSpecialValueFor("bonus_spell_amp")
end

function modifier_item_arcane_crystal_passive:GetModifierPercentageCooldown()
  return self.cdr or self:GetAbility():GetSpecialValueFor("cooldown_reduction")
end

function modifier_item_arcane_crystal_passive:GetModifierHealAmplify_PercentageSource()
  return self.heal_amp or self:GetAbility():GetSpecialValueFor("bonus_heal_amp")
end

function modifier_item_arcane_crystal_passive:GetModifierHealAmplify_PercentageTarget()
  return self.heal_amp or self:GetAbility():GetSpecialValueFor("bonus_heal_amp")
end

function modifier_item_arcane_crystal_passive:GetModifierPercentageCasttime()
  local parent = self:GetParent()
  -- If parent has better cast time improvements return 0
  if parent:HasModifier("modifier_no_cast_points_oaa") or parent:HasModifier("modifier_speedster_oaa") or parent:HasModifier("modifier_sonic_fly") then
    return 0
  end
  return self.cast_time_reduction or self:GetAbility():GetSpecialValueFor("cast_pct_improvement")
end

if IsServer() then
  function modifier_item_arcane_crystal_passive:GetModifierStatusResistanceCaster()
    return self.debuff_amp or self:GetAbility():GetSpecialValueFor("debuff_amp")
  end
end
