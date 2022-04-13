LinkLuaModifier("modifier_roshan_custom_passive", "abilities/boss/roshan/roshan_custom_passive.lua", LUA_MODIFIER_MOTION_NONE)

roshan_custom_passive = class(AbilityBaseClass)

function roshan_custom_passive:GetIntrinsicModifierName()
  return "modifier_roshan_custom_passive"
end

---------------------------------------------------------------------------------------------------

modifier_roshan_custom_passive = class(ModifierBaseClass)

function modifier_roshan_custom_passive:IsHidden()
  return true
end

function modifier_roshan_custom_passive:IsDebuff()
  return false
end

function modifier_roshan_custom_passive:IsPurgable()
  return false
end

function modifier_roshan_custom_passive:RemoveOnDeath()
  return true
end

function modifier_roshan_custom_passive:OnCreated()
  local ability = self:GetAbility()
  if ability and not ability:IsNull() then
    self.damage = ability:GetSpecialValueFor("bonus_damage")
  end
end

function modifier_roshan_custom_passive:OnRefresh()
  local ability = self:GetAbility()
  if ability and not ability:IsNull() then
    self.damage = ability:GetSpecialValueFor("bonus_damage")
  end
end

function modifier_roshan_custom_passive:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
  }
end

function modifier_roshan_custom_passive:GetModifierPreAttack_BonusDamage()
  if self.damage or self:GetAbility() then
    return self.damage or self:GetAbility():GetSpecialValueFor("bonus_damage")
  end

  return 450
end
