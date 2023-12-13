---------------------------------------------------------------------------------------------------

modifier_faceless_void_time_dilation_degen_oaa = modifier_faceless_void_time_dilation_degen_oaa or class({})

function modifier_faceless_void_time_dilation_degen_oaa:IsHidden()
  return true
end

function modifier_faceless_void_time_dilation_degen_oaa:IsDebuff()
  return true
end

function modifier_faceless_void_time_dilation_degen_oaa:IsPurgable()
  return true
end

function modifier_faceless_void_time_dilation_degen_oaa:OnCreated()
  local ability = self:GetAbility()
  if ability and not ability:IsNull() then
    self.heal_prevent_percent = ability:GetSpecialValueFor("heal_prevent_percent")
  else
    self.heal_prevent_percent = -10
  end
end

function modifier_faceless_void_time_dilation_degen_oaa:OnRefresh()
  self:OnCreated()
end

function modifier_faceless_void_time_dilation_degen_oaa:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_HEAL_AMPLIFY_PERCENTAGE_TARGET,
    MODIFIER_PROPERTY_HP_REGEN_AMPLIFY_PERCENTAGE,
    MODIFIER_PROPERTY_LIFESTEAL_AMPLIFY_PERCENTAGE,
    MODIFIER_PROPERTY_SPELL_LIFESTEAL_AMPLIFY_PERCENTAGE,
  }
end

function modifier_faceless_void_time_dilation_degen_oaa:GetModifierHealAmplify_PercentageTarget()
  return self.heal_prevent_percent
end

function modifier_faceless_void_time_dilation_degen_oaa:GetModifierHPRegenAmplify_Percentage()
  return self.heal_prevent_percent
end

function modifier_faceless_void_time_dilation_degen_oaa:GetModifierLifestealRegenAmplify_Percentage()
  return self.heal_prevent_percent
end

function modifier_faceless_void_time_dilation_degen_oaa:GetModifierSpellLifestealRegenAmplify_Percentage()
  return self.heal_prevent_percent
end
