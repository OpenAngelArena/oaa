-- Timeless Relic

modifier_debuff_duration_oaa = class(ModifierBaseClass)

function modifier_debuff_duration_oaa:IsHidden()
  return false
end

function modifier_debuff_duration_oaa:IsDebuff()
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

if IsServer() then
  function modifier_debuff_duration_oaa:GetModifierStatusResistanceCaster()
    return -30
  end
end

function modifier_debuff_duration_oaa:GetModifierSpellAmplify_Percentage()
  return 30
end

function modifier_debuff_duration_oaa:GetTexture()
  return "item_timeless_relic"
end
