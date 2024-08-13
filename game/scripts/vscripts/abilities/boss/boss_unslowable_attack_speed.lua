LinkLuaModifier("modifier_boss_unslowable_attack_speed", "abilities/boss/boss_unslowable_attack_speed.lua", LUA_MODIFIER_MOTION_NONE)

boss_unslowable_attack_speed = class(AbilityBaseClass)

function boss_unslowable_attack_speed:GetIntrinsicModifierName()
  return "modifier_boss_unslowable_attack_speed"
end

---------------------------------------------------------------------------------------------------

modifier_boss_unslowable_attack_speed = class(ModifierBaseClass)

function modifier_boss_unslowable_attack_speed:IsHidden()
  return true
end

function modifier_boss_unslowable_attack_speed:IsDebuff()
  return false
end

function modifier_boss_unslowable_attack_speed:IsPurgable()
  return false
end

function modifier_boss_unslowable_attack_speed:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_ATTACKSPEED_REDUCTION_PERCENTAGE, -- GetModifierAttackSpeedReductionPercentage,
  }
end

function modifier_boss_unslowable_attack_speed:GetModifierAttackSpeedReductionPercentage()
  return 0
end
