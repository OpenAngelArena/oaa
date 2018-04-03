require('abilities/swiper/boss_swiper_swipe')

boss_swiper_frontswipe = class(boss_swiper_backswipe_base)

--------------------------------------------------------------------------------

function boss_swiper_frontswipe:OnAbilityPhaseStart()
	if IsServer() then
		local caster = self:GetCaster()
		local range = self:GetCastRange(caster:GetAbsOrigin(), caster)

		DebugRange(caster, range, self)
	end
	return true
end

--------------------------------------------------------------------------------

function boss_swiper_frontswipe:GetPlaybackRateOverride()
	return 0.3
end