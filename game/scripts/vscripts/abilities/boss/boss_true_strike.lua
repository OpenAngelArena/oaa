LinkLuaModifier("modifier_boss_true_strike_oaa", "abilities/boss/boss_true_strike.lua", LUA_MODIFIER_MOTION_NONE)

boss_true_strike = class(AbilityBaseClass)

function boss_true_strike:GetIntrinsicModifierName()
  return "modifier_boss_true_strike_oaa"
end

---------------------------------------------------------------------------------------------------

modifier_boss_true_strike_oaa = class(ModifierBaseClass)

function modifier_boss_true_strike_oaa:IsHidden()
  return false
end

function modifier_boss_true_strike_oaa:IsDebuff()
  return false
end

function modifier_boss_true_strike_oaa:IsPurgable()
  return false
end

function modifier_boss_true_strike_oaa:RemoveOnDeath()
  return true
end

function modifier_boss_true_strike_oaa:CheckState()
  return {
    [MODIFIER_STATE_CANNOT_MISS] = true,
  }
end
