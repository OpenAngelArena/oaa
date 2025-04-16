modifier_glass_cannon_oaa = class(ModifierBaseClass)

function modifier_glass_cannon_oaa:IsHidden()
  return false
end

function modifier_glass_cannon_oaa:IsDebuff()
  return true
end

function modifier_glass_cannon_oaa:IsPurgable()
  return false
end

function modifier_glass_cannon_oaa:RemoveOnDeath()
  return false
end

function modifier_glass_cannon_oaa:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_TOTALDAMAGEOUTGOING_PERCENTAGE,
    MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE,
  }
end

function modifier_glass_cannon_oaa:GetModifierTotalDamageOutgoing_Percentage()
  return 25
end

function modifier_glass_cannon_oaa:GetModifierIncomingDamage_Percentage()
  return 25
end

function modifier_glass_cannon_oaa:GetTexture()
  return "item_nemesis_curse"
end
