LinkLuaModifier("modifier_sohei_innate_oaa", "abilities/sohei/sohei_innate.lua", LUA_MODIFIER_MOTION_NONE)

sohei_innate_oaa = class(AbilityBaseClass)

function sohei_innate_oaa:GetIntrinsicModifierName()
  return "modifier_sohei_innate_oaa"
end

---------------------------------------------------------------------------------------------------
modifier_sohei_innate_oaa = class(ModifierBaseClass)

function modifier_sohei_innate_oaa:IsHidden()
  return false
end

function modifier_sohei_innate_oaa:IsDebuff()
  return false
end

function modifier_sohei_innate_oaa:IsPurgable()
  return false
end

function modifier_sohei_innate_oaa:RemoveOnDeath()
  return false
end

function modifier_sohei_innate_oaa:OnCreated()
  local ability = self:GetAbility()
  if ability and not ability:IsNull() then
    self.dmg_per_ms = ability:GetSpecialValueFor("base_attack_dmg_per_ms")
  else
    self.dmg_per_ms = 0.08
  end
end

modifier_sohei_innate_oaa.OnRefresh = modifier_sohei_innate_oaa.OnCreated

function modifier_sohei_innate_oaa:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_BASEATTACK_BONUSDAMAGE,
    MODIFIER_PROPERTY_TOOLTIP,
  }
end

function modifier_sohei_innate_oaa:GetModifierBaseAttack_BonusDamage()
  local parent = self:GetParent()
  if parent:PassivesDisabled() then
    return 0
  end
  local speed = parent:GetIdealSpeed()
  return self.dmg_per_ms * speed
end

function modifier_sohei_innate_oaa:OnTooltip()
  local parent = self:GetCaster()
  if parent:PassivesDisabled() then
    return 0
  end
  local speed = parent:GetIdealSpeed()
  return self.dmg_per_ms * speed
end
