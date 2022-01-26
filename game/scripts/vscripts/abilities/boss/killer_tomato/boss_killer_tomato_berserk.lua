LinkLuaModifier("modifier_boss_killer_tomato_berserk", "abilities/boss/killer_tomato/boss_killer_tomato_berserk.lua", LUA_MODIFIER_MOTION_NONE)

boss_killer_tomato_berserk = class(AbilityBaseClass)

function boss_killer_tomato_berserk:GetIntrinsicModifierName()
  return "modifier_boss_killer_tomato_berserk"
end

---------------------------------------------------------------------------------------------------

modifier_boss_killer_tomato_berserk = class(ModifierBaseClass)

function modifier_boss_killer_tomato_berserk:IsHidden()
  return true
end

function modifier_boss_killer_tomato_berserk:IsDebuff()
  return false
end

function modifier_boss_killer_tomato_berserk:IsPurgable()
  return false
end

function modifier_boss_killer_tomato_berserk:RemoveOnDeath()
  return true
end

function modifier_boss_killer_tomato_berserk:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
  }
end

function modifier_boss_killer_tomato_berserk:GetModifierAttackSpeedBonus_Constant()
  if not IsServer() then
    return
  end
  local parent = self:GetParent()
  local current_hp_pct = parent:GetHealth() / parent:GetMaxHealth()

  return (1 - current_hp_pct) * self:GetAbility():GetSpecialValueFor("maximum_attack_speed")
end
