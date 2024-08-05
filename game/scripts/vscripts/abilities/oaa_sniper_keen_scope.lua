LinkLuaModifier( "modifier_sniper_keen_scope_oaa", "abilities/oaa_sniper_keen_scope.lua", LUA_MODIFIER_MOTION_NONE )

sniper_keen_scope_oaa = class(AbilityBaseClass)

function sniper_keen_scope_oaa:GetIntrinsicModifierName()
  return "modifier_sniper_keen_scope_oaa"
end

---------------------------------------------------------------------------------------------------

modifier_sniper_keen_scope_oaa = class(ModifierBaseClass)

function modifier_sniper_keen_scope_oaa:IsHidden()
  return true
end

function modifier_sniper_keen_scope_oaa:IsDebuff()
  return false
end

function modifier_sniper_keen_scope_oaa:IsPurgable()
  return false
end

function modifier_sniper_keen_scope_oaa:RemoveOnDeath()
  return false
end

function modifier_sniper_keen_scope_oaa:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_ATTACK_RANGE_BONUS,
    MODIFIER_PROPERTY_BASE_ATTACK_TIME_CONSTANT,
  }
end

function modifier_sniper_keen_scope_oaa:GetModifierAttackRangeBonus()
  local ability = self:GetAbility()
  if self:GetParent():PassivesDisabled() then
    return 0 - math.abs(ability:GetSpecialValueFor("attack_range_reduction"))
  else
    return ability:GetSpecialValueFor("bonus_range") - math.abs(ability:GetSpecialValueFor("attack_range_reduction"))
  end
end

function modifier_sniper_keen_scope_oaa:GetModifierBaseAttackTimeConstant()
  local ability = self:GetAbility()
  if self:GetParent():PassivesDisabled() then
    return 0
  else
    return 1.7 - ability:GetSpecialValueFor("bat_reduction")
  end
end
