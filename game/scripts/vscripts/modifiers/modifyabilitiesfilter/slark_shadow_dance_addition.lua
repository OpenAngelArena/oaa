---------------------------------------------------------------------------------------------------

modifier_slark_shadow_dance_oaa = modifier_slark_shadow_dance_oaa or class({})

function modifier_slark_shadow_dance_oaa:IsHidden()
  return true --not IsInToolsMode()
end

function modifier_slark_shadow_dance_oaa:IsDebuff()
  return false
end

function modifier_slark_shadow_dance_oaa:IsPurgable()
  return false
end

function modifier_slark_shadow_dance_oaa:OnCreated()
  self:OnRefresh()
  if IsServer() then
    self:StartIntervalThink(0.1)
  end
end

function modifier_slark_shadow_dance_oaa:OnRefresh()
  self.regen = 1
  local ability = self:GetAbility()
  if ability and not ability:IsNull() then
    self.regen = ability:GetSpecialValueFor("health_regen_pct_oaa")
  end
  if IsServer() then
    self:OnIntervalThink()
  end
end

function modifier_slark_shadow_dance_oaa:OnIntervalThink()
  local parent = self:GetParent()
  local ability = self:GetAbility()
  if not ability or ability:IsNull() then
    self:StartIntervalThink(-1)
    self:Destroy()
    return
  end

  local name = ability:GetAbilityName()
  -- Remove this buff if parent is not affected by Shadow Dance or Depth Shroud;
  if (name == "slark_shadow_dance" and not parent:HasModifier("modifier_slark_shadow_dance_aura")) or (name == "slark_depth_shroud" and not parent:HasModifier("modifier_slark_depth_shroud")) then
    self:StartIntervalThink(-1)
    self:Destroy()
    return
  end
end

function modifier_slark_shadow_dance_oaa:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_HEALTH_REGEN_PERCENTAGE,
  }
end

function modifier_slark_shadow_dance_oaa:GetModifierHealthRegenPercentage()
  return self.regen
end



