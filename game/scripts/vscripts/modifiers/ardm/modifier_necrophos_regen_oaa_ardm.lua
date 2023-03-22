
modifier_necrophos_regen_oaa_ardm = modifier_necrophos_regen_oaa_ardm or class({})

function modifier_necrophos_regen_oaa_ardm:IsHidden()
  return false -- needs tooltip
end

function modifier_necrophos_regen_oaa_ardm:IsDebuff()
  return false
end

function modifier_necrophos_regen_oaa_ardm:IsPurgable()
  return false
end

function modifier_necrophos_regen_oaa_ardm:RemoveOnDeath()
  return false
end

function modifier_necrophos_regen_oaa_ardm:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT,
    MODIFIER_PROPERTY_MANA_REGEN_CONSTANT,
  }
end

function modifier_necrophos_regen_oaa_ardm:GetModifierConstantHealthRegen()
  return 6*self:GetStackCount()
end

function modifier_necrophos_regen_oaa_ardm:GetModifierConstantManaRegen()
  return 3*self:GetStackCount()
end

function modifier_necrophos_regen_oaa_ardm:GetTexture()
  return "necrolyte_reapers_scythe"
end
