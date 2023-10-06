LinkLuaModifier("modifier_temple_guardian_passive", "abilities/boss/temple_guardian/modifier_temple_guardian_passive", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_temple_guardian_statue", "abilities/boss/temple_guardian/modifier_temple_guardian_statue", LUA_MODIFIER_MOTION_NONE)

temple_guardian_passive = class(AbilityBaseClass)

function temple_guardian_passive:GetIntrinsicModifierName()
	return "modifier_temple_guardian_passive"
end
