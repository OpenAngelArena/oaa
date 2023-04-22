modifier_superposition_illusion = class({})

function modifier_superposition_illusion:CheckState()
	local states = {
		[MODIFIER_STATE_UNSELECTABLE] = true,
		[MODIFIER_STATE_INVULNERABLE] = true,
		[MODIFIER_STATE_DISARMED] = true,
		[MODIFIER_STATE_INVISIBLE] = true,
		[MODIFIER_STATE_TRUESIGHT_IMMUNE] = true,
		[MODIFIER_STATE_OUT_OF_GAME] = true,
		[MODIFIER_STATE_NOT_ON_MINIMAP] = true,
		[MODIFIER_STATE_NO_UNIT_COLLISION] = true
	}
	return states
end


function modifier_superposition_illusion:DeclareFunctions()
	local funcs = {
		MODIFIER_PROPERTY_TOTALDAMAGEOUTGOING_PERCENTAGE,
		-- MODIFIER_PROPERTY_VISUAL_Z_DELTA,
		MODIFIER_PROPERTY_IS_ILLUSION,
		MODIFIER_PROPERTY_ILLUSION_LABEL,
		MODIFIER_PROPERTY_SUPER_ILLUSION,
		MODIFIER_PROPERTY_CAST_RANGE_BONUS_STACKING,
	}
	return funcs
end

function modifier_superposition_illusion:GetIsIllusion()
	return 1
end

function modifier_superposition_illusion:GetModifierIllusionLabel()
	return 1
end

function modifier_superposition_illusion:GetModifierCastRangeBonusStacking()
	return 1000
end

function modifier_superposition_illusion:GetModifierTotalDamageOutgoing_Percentage()
	return -100
end

function modifier_superposition_illusion:GetVisualZDelta()
	return 0
end

function modifier_superposition_illusion:GetModifierSuperIllusion()
	return 1
end