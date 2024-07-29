--------------------------------------------------------------------------------

-- Modifier Phoenix Arcana gryphon phoenix
modifier_arcana_gryphon = class(ModifierBaseClass)

function modifier_arcana_gryphon:IsHidden()
	return true
end

function modifier_arcana_gryphon:IsPurgable()
	return false
end

function modifier_arcana_gryphon:IsDebuff()
	return false
end

function modifier_arcana_gryphon:RemoveOnDeath()
	return false
end

function modifier_arcana_gryphon:GetAttributes()
	return MODIFIER_ATTRIBUTE_PERMANENT
end

function modifier_arcana_gryphon:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_MODEL_CHANGE,
  }
end

function modifier_arcana_gryphon:GetModifierModelChange()
  return "models/heroes/phoenix/gryphon/phoenix_griffin.vmdl"
end
