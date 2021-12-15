modifier_debuff_duration_oaa = class(ModifierBaseClass)

function modifier_debuff_duration_oaa:IsHidden()
  return true
end

function modifier_debuff_duration_oaa:IsPurgable()
  return false
end

function modifier_debuff_duration_oaa:RemoveOnDeath()
  return false
end

function modifier_debuff_duration_oaa:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_STATUS_RESISTANCE_CASTER
  }
end

--function modifier_debuff_duration_oaa:GetTexture()
  --return ""
--end

function modifier_debuff_duration_oaa:GetModifierStatusResistanceCaster()
  return -25
end
