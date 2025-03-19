LinkLuaModifier("modifier_neutral_evasion_oaa", "abilities/neutrals/oaa_neutral_evasion.lua", LUA_MODIFIER_MOTION_NONE)

neutral_evasion_oaa = class(AbilityBaseClass)

function neutral_evasion_oaa:GetIntrinsicModifierName()
  return "modifier_neutral_evasion_oaa"
end

--------------------------------------------------------------------------------

modifier_neutral_evasion_oaa = class({})

function modifier_neutral_evasion_oaa:IsHidden()
  return true
end

function modifier_neutral_evasion_oaa:IsDebuff()
  return false
end

function modifier_neutral_evasion_oaa:IsPurgable()
  return false
end

function modifier_neutral_evasion_oaa:OnCreated()
  local ability = self:GetAbility()
  if ability and not ability:IsNull() then
    self.evasion = ability:GetSpecialValueFor("chance")
  end
end

modifier_neutral_evasion_oaa.OnRefresh = modifier_neutral_evasion_oaa.OnCreated

function modifier_neutral_evasion_oaa:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_EVASION_CONSTANT,
  }
end

function modifier_neutral_evasion_oaa:GetModifierEvasion_Constant()
  local parent = self:GetParent()
  if parent:PassivesDisabled() then
    return 0
  end
  return self.evasion or self:GetAbility():GetSpecialValueFor("chance")
end
