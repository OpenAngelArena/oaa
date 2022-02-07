modifier_debuff_duration_oaa = class(ModifierBaseClass)

function modifier_debuff_duration_oaa:IsHidden()
  return false
end

function modifier_debuff_duration_oaa:IsPurgable()
  return false
end

function modifier_debuff_duration_oaa:RemoveOnDeath()
  return false
end

function modifier_debuff_duration_oaa:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_STATUS_RESISTANCE_CASTER,
    MODIFIER_PROPERTY_SPELL_AMPLIFY_PERCENTAGE,    -- GetModifierSpellAmplify_Percentage
  }
end

function modifier_debuff_duration_oaa:GetModifierStatusResistanceCaster()
  return -25
end

function modifier_debuff_duration_oaa:GetModifierSpellAmplify_Percentage()
  return 25
end

function modifier_debuff_duration_oaa:GetTexture()
  return "item_timeless_relic"
end
