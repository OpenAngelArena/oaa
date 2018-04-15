LinkLuaModifier("modifier_boss_carapace_headbutt_slow", "abilities/carapace/boss_carapace_headbutt.lua", LUA_MODIFIER_MOTION_NONE)

boss_carapace_headbutt = class(AbilityBaseClass)

function boss_carapace_headbutt:OnSpellStart()
	local caster = self:GetCaster()
	
	local distance = self:GetSpecialValueFor("distance")
	local radius = self:GetSpecialValueFor("radius")
	Timers:CreateTimer(function()
		return 0
	end)
end