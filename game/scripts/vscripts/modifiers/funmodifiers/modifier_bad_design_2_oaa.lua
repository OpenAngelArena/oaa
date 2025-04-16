
modifier_bad_design_2_oaa = class(ModifierBaseClass)

function modifier_bad_design_2_oaa:IsHidden()
  return false
end

function modifier_bad_design_2_oaa:IsDebuff()
  return false
end

function modifier_bad_design_2_oaa:IsPurgable()
  return false
end

function modifier_bad_design_2_oaa:RemoveOnDeath()
  return false
end

function modifier_bad_design_2_oaa:OnCreated()
  self.bonus_hp_per_int = 10
  self.bonus_hp_regen_per_int = 0.1
end

function modifier_bad_design_2_oaa:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_HEALTH_BONUS,
    MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT,
  }
end

function modifier_bad_design_2_oaa:GetModifierHealthBonus()
  local parent = self:GetParent()
  return self.bonus_hp_per_int * parent:GetIntellect(false)
end

function modifier_bad_design_2_oaa:GetModifierConstantHealthRegen()
  local parent = self:GetParent()
  return self.bonus_hp_regen_per_int * parent:GetIntellect(false)
end

function modifier_bad_design_2_oaa:GetTexture()
  return "item_cornucopia"
end
