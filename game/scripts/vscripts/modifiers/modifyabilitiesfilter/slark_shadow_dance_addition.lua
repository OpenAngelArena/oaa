---------------------------------------------------------------------------------------------------

modifier_slark_shadow_dance_oaa = modifier_slark_shadow_dance_oaa or class({})

function modifier_slark_shadow_dance_oaa:IsHidden()
  return true
end

function modifier_slark_shadow_dance_oaa:IsDebuff()
  return false
end

function modifier_slark_shadow_dance_oaa:IsPurgable()
  return false
end

function modifier_slark_shadow_dance_oaa:OnCreated()
  self.regen = 1
  local ability = self:GetAbility()
  if ability and not ability:IsNull() then
    self.regen = ability:GetSpecialValueFor("health_regen_pct_oaa")
  end
end

modifier_slark_shadow_dance_oaa.OnRefresh = modifier_slark_shadow_dance_oaa.OnCreated

function modifier_slark_shadow_dance_oaa:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_HEALTH_REGEN_PERCENTAGE,
  }
end

function modifier_slark_shadow_dance_oaa:GetModifierHealthRegenPercentage()
  return self.regen
end



