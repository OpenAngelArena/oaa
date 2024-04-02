--------------------------------------------------------------------------------

-- Modifier Chatterjee Arcana rockstar electrician
modifier_arcana_rockelec = class(ModifierBaseClass)

function modifier_arcana_rockelec:IsHidden()
	return true
end

function modifier_arcana_rockelec:IsPurgable()
	return false
end

function modifier_arcana_rockelec:IsDebuff()
	return false
end

function modifier_arcana_rockelec:RemoveOnDeath()
	return false
end

function modifier_arcana_rockelec:GetAttributes()
	return MODIFIER_ATTRIBUTE_PERMANENT
end

function modifier_arcana_rockelec:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_MODEL_CHANGE,
  }
end

function modifier_arcana_rockelec:GetModifierModelChange()
  return "models/heroes/electrician/electrician_arcana/electrician_arcana_base.vmdl"
end
