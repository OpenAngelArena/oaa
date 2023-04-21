
modifier_axe_armor_oaa_ardm = modifier_axe_armor_oaa_ardm or class({})

function modifier_axe_armor_oaa_ardm:IsHidden()
  return false -- needs tooltip
end

function modifier_axe_armor_oaa_ardm:IsDebuff()
  return false
end

function modifier_axe_armor_oaa_ardm:IsPurgable()
  return false
end

function modifier_axe_armor_oaa_ardm:RemoveOnDeath()
  return false
end

function modifier_axe_armor_oaa_ardm:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
  }
end

function modifier_axe_armor_oaa_ardm:GetModifierPhysicalArmorBonus()
  return 1.5*self:GetStackCount()
end

function modifier_axe_armor_oaa_ardm:GetTexture()
  return "axe_culling_blade"
end
