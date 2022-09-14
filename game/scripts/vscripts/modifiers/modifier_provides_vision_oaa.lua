modifier_provides_vision_oaa = class(ModifierBaseClass)

function modifier_provides_vision_oaa:IsHidden()
	return true
end

function modifier_provides_vision_oaa:IsPurgable()
	return false
end

function modifier_provides_vision_oaa:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_PROVIDES_FOW_POSITION,
	}
end

function modifier_provides_vision_oaa:GetModifierProvidesFOWVision()
  return 1
end

function modifier_provides_vision_oaa:CheckState()
  return {
    [MODIFIER_STATE_PROVIDES_VISION] = true
  }
end
