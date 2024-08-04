LinkLuaModifier( "modifier_sniper_keen_scope_oaa_bat_reduction", "abilities/oaa_sniper_keen_scope.lua", LUA_MODIFIER_MOTION_NONE )

--------------------------------------------------------------------------------
sniper_keen_scope_oaa = class(AbilityBaseClass)
--------------------------------------------------------------------------------

function sniper_keen_scope_oaa:GetIntrinsicModifierName()
  return "modifier_intrinsic_multiplexer"
end

function sniper_keen_scope_oaa:GetIntrinsicModifierNames()
  return {
    "modifier_sniper_keen_scope",
    "modifier_sniper_keen_scope_oaa_bat_reduction"
  }
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
modifier_sniper_keen_scope_oaa_bat_reduction = class(ModifierBaseClass)
--------------------------------------------------------------------------------

function modifier_sniper_keen_scope_oaa_bat_reduction:IsDebuff()
  return false
end

function modifier_sniper_keen_scope_oaa_bat_reduction:IsHidden()
  return true
end

function modifier_sniper_keen_scope_oaa_bat_reduction:IsPurgable()
  return false
end

function modifier_sniper_keen_scope_oaa_bat_reduction:RemoveOnDeath()
  return false
end

function modifier_sniper_keen_scope_oaa_bat_reduction:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_BASE_ATTACK_TIME_CONSTANT
  }
end

function modifier_sniper_keen_scope_oaa_bat_reduction:GetModifierBaseAttackTimeConstant()
  local ability = self:GetAbility()
  return 1.7 - ability:GetSpecialValueFor("bat_reduction")
end

--------------------------------------------------------------------------------
