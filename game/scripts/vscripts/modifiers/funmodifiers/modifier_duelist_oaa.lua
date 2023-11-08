-- Duelist

modifier_duelist_oaa = class(ModifierBaseClass)

function modifier_duelist_oaa:IsHidden()
  return false
end

function modifier_duelist_oaa:IsDebuff()
  return false
end

function modifier_duelist_oaa:IsPurgable()
  return false
end

function modifier_duelist_oaa:RemoveOnDeath()
  return false
end

function modifier_duelist_oaa:OnCreated()
  if IsServer() then
    self:StartIntervalThink(0.1)
  end
end

function modifier_duelist_oaa:OnIntervalThink()
  if Duels:IsActive() then
    self:SetStackCount(2)
  else
    self:SetStackCount(1)
  end
end

function modifier_duelist_oaa:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_TOTALDAMAGEOUTGOING_PERCENTAGE,
    MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE,
  }
end

function modifier_duelist_oaa:GetModifierTotalDamageOutgoing_Percentage()
  if self:GetStackCount() == 2 then
    return 35
  end
  return 0
end

function modifier_duelist_oaa:GetModifierIncomingDamage_Percentage()
  if self:GetStackCount() == 1 then
    return -15
  end
  return 0
end

function modifier_duelist_oaa:GetTexture()
  return "antimage_blink"
end
