---------------------------------------------------------------------------------------------------

modifier_windranger_scepter_oaa = modifier_windranger_scepter_oaa or class({})

function modifier_windranger_scepter_oaa:IsHidden()
  return true
end

function modifier_windranger_scepter_oaa:IsDebuff()
  return false
end

function modifier_windranger_scepter_oaa:IsPurgable()
  return false
end

function modifier_windranger_scepter_oaa:OnCreated()
  local ability = self:GetAbility()
  if ability and not ability:IsNull() then
    self.spell_amp = ability:GetSpecialValueFor("scepter_spell_amp")
  else
    self.spell_amp = 35
  end
end

function modifier_windranger_scepter_oaa:OnRefresh()
  self:OnCreated()
end

function modifier_windranger_scepter_oaa:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_SPELL_AMPLIFY_PERCENTAGE,
  }
end

function modifier_windranger_scepter_oaa:GetModifierSpellAmplify_Percentage()
  return self.spell_amp
end

function modifier_windranger_scepter_oaa:CheckState()
  return {
    [MODIFIER_STATE_NO_UNIT_COLLISION] = true,
  }
end
