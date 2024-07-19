--------------------------------------------------------------------------------

-- Modifier Chatterjee Arcana rockstar electrician
modifier_arcana_maid = class(ModifierBaseClass)

function modifier_arcana_maid:IsHidden()
	return true
end

function modifier_arcana_maid:IsPurgable()
	return false
end

function modifier_arcana_maid:IsDebuff()
	return false
end

function modifier_arcana_maid:RemoveOnDeath()
	return false
end

function modifier_arcana_maid:GetAttributes()
	return MODIFIER_ATTRIBUTE_PERMANENT
end

function modifier_arcana_maid:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_MODEL_CHANGE,
  }
end

function modifier_arcana_maid:GetModifierModelChange()
  return "models/heroes/marci/maid/maid_marci.vmdl"
end
