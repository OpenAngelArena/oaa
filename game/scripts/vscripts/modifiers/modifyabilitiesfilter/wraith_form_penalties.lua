---------------------------------------------------------------------------------------------------

modifier_wraith_form_penalty_oaa = modifier_wraith_form_penalty_oaa or class({})

function modifier_wraith_form_penalty_oaa:IsHidden()
  return true
end

function modifier_wraith_form_penalty_oaa:IsDebuff()
  return false
end

function modifier_wraith_form_penalty_oaa:IsPurgable()
  return false
end

function modifier_wraith_form_penalty_oaa:OnCreated()
  self.dmg_penalty = -25

  local ability = self:GetAbility()
  if ability and not ability:IsNull() then
    self.dmg_penalty = 0 - math.abs(ability:GetSpecialValueFor("scepter_damage_penalty"))
  end
end

modifier_wraith_form_penalty_oaa.OnRefresh = modifier_wraith_form_penalty_oaa.OnCreated

function modifier_wraith_form_penalty_oaa:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_TOTALDAMAGEOUTGOING_PERCENTAGE,
  }
end

function modifier_wraith_form_penalty_oaa:GetModifierTotalDamageOutgoing_Percentage(event)
  return self.dmg_penalty
end
