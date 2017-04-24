
modifier_rune_hill_tripledamage = class({})

function modifier_rune_hill_tripledamage:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_BASEDAMAGEOUTGOING_PERCENTAGE
  }
end

function modifier_rune_hill_tripledamage:GetModifierBaseDamageOutgoing_Percentage()
  return 100
end

function modifier_rune_hill_tripledamage:GetTexture()
  return "rune_doubledamage"
end
