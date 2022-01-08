temple_guardian_passive_tier5 = class(AbilityBaseClass)
LinkLuaModifier( "modifier_temple_guardian_passive", "modifiers/modifier_temple_guardian_passive", LUA_MODIFIER_MOTION_NONE )

-----------------------------------------------------------------------------------------

function temple_guardian_passive_tier5:GetIntrinsicModifierName()
	return "modifier_temple_guardian_passive"
end

-----------------------------------------------------------------------------------------
