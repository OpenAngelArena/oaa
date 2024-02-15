---------------------------------------------------------------------------------------------------

modifier_item_revenants_brooch_active_oaa = modifier_item_revenants_brooch_active_oaa or class({})

function modifier_item_revenants_brooch_active_oaa:IsHidden()
  return true
end

function modifier_item_revenants_brooch_active_oaa:IsDebuff()
  return false
end

function modifier_item_revenants_brooch_active_oaa:IsPurgable()
  return false
end

function modifier_item_revenants_brooch_active_oaa:RemoveOnDeath()
  return false
end

function modifier_item_revenants_brooch_active_oaa:OnCreated()
  if IsServer() then
    self:StartIntervalThink(0)
  end
end

function modifier_item_revenants_brooch_active_oaa:OnIntervalThink()
  local parent = self:GetParent()
  -- Remove this debuff if parent is not affected by Revenant Brooch Modifier any more
  if not parent:HasModifier("modifier_item_revenants_brooch_active") then
    self:StartIntervalThink(-1)
    self:Destroy()
    return
  end

  local ability = self:GetAbility()
  if not ability or ability:IsNull() then
    return
  end

  self.negative_spell_amp = ability:GetSpecialValueFor("negative_spell_amp_while_active")
  self:SetStackCount(self.negative_spell_amp)
end

function modifier_item_revenants_brooch_active_oaa:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_SPELL_AMPLIFY_PERCENTAGE,
  }
end

function modifier_item_revenants_brooch_active_oaa:GetModifierSpellAmplify_Percentage()
  return 0 - math.abs(self:GetStackCount())
end