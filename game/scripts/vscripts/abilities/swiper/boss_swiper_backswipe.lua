require('abilities/swiper/boss_swiper_swipe')

boss_swiper_backswipe = class(boss_swiper_backswipe_base)

--------------------------------------------------------------------------------

function boss_swiper_backswipe:OnAbilityPhaseStart()
	if IsServer() then
		local caster = self:GetCaster()
		local range = self:GetCastRange(caster:GetAbsOrigin(), caster)

		self:DebugRange(caster, range)
	end
	return true
end

--------------------------------------------------------------------------------

function boss_swiper_backswipe:GetPlaybackRateOverride()
	return 1.3
end