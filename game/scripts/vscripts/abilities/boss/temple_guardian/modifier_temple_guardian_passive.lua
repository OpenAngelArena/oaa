modifier_temple_guardian_passive = class(ModifierBaseClass)

-----------------------------------------------------------------------------------------

function modifier_temple_guardian_passive:IsHidden()
	return true
end

-----------------------------------------------------------------------------------------

function modifier_temple_guardian_passive:IsPurgable()
	return false
end

-----------------------------------------------------------------------------------------

function modifier_temple_guardian_passive:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_MOVESPEED_ABSOLUTE,
	}
end

-----------------------------------------------------------------------------------------

function modifier_temple_guardian_passive:GetModifierMoveSpeed_Absolute()
	return self:GetAbility():GetSpecialValueFor( "movement_speed" )
end
