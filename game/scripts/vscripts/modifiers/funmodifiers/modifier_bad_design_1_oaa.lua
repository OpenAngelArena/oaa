
modifier_bad_design_1_oaa = class(ModifierBaseClass)

function modifier_bad_design_1_oaa:IsHidden()
  return false
end

function modifier_bad_design_1_oaa:IsDebuff()
  return false
end

function modifier_bad_design_1_oaa:IsPurgable()
  return false
end

function modifier_bad_design_1_oaa:RemoveOnDeath()
  return false
end

function modifier_bad_design_1_oaa:OnCreated()
  self.bonus_dmg_per_armor = 4
end

function modifier_bad_design_1_oaa:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
  }
end

function modifier_bad_design_1_oaa:GetModifierPreAttack_BonusDamage()
  local parent = self:GetParent()
  return self.bonus_dmg_per_armor * parent:GetPhysicalArmorValue(false)
end

function modifier_bad_design_1_oaa:GetTexture()
  return "item_helm_of_iron_will"
end
