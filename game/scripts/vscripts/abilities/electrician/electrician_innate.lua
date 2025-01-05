LinkLuaModifier("modifier_electrician_innate_oaa", "abilities/electrician/electrician_innate.lua", LUA_MODIFIER_MOTION_NONE)

electrician_innate_oaa = class(AbilityBaseClass)

function electrician_innate_oaa:GetIntrinsicModifierName()
  return "modifier_electrician_innate_oaa"
end

---------------------------------------------------------------------------------------------------

modifier_electrician_innate_oaa = class(ModifierBaseClass)

function modifier_electrician_innate_oaa:IsHidden()
  return true
end

function modifier_electrician_innate_oaa:IsDebuff()
  return false
end

function modifier_electrician_innate_oaa:IsPurgable()
  return false
end

function modifier_electrician_innate_oaa:RemoveOnDeath()
  return false
end

function modifier_electrician_innate_oaa:OnCreated()
  local ability = self:GetAbility()
  if ability and not ability:IsNull() then
    self.mana_per_str = ability:GetSpecialValueFor("mana_per_str")
    self.penalty_per_int = ability:GetSpecialValueFor("mana_penalty_per_int")
  else
    self.mana_per_str = 8
    self.penalty_per_int = 4
  end
end

modifier_electrician_innate_oaa.OnRefresh = modifier_electrician_innate_oaa.OnCreated

function modifier_electrician_innate_oaa:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_MANA_BONUS,
  }
end

function modifier_electrician_innate_oaa:GetModifierManaBonus()
  local parent = self:GetParent()
  if parent:PassivesDisabled() then
    return 0
  end
  local strength = parent:GetStrength()
  local intelligence = parent:GetIntellect(false)
  return self.mana_per_str * strength - self.penalty_per_int * intelligence
end
