require('abilities/swiper/boss_swiper_swipe')

boss_swiper_frontswipe = class(boss_swiper_backswipe_base)
boss_swiper_frontswipe.particleName = "particles/bosses/swiper/swiper_backswipe_base.vpcf"

--------------------------------------------------------------------------------

function boss_swiper_frontswipe:GetPlaybackRateOverride()
	return 0.5
end