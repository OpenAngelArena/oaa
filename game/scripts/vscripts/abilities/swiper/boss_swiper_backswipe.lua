require('abilities/swiper/boss_swiper_swipe')

boss_swiper_backswipe = class(boss_swiper_backswipe_base)
boss_swiper_backswipe.particleName = "particles/bosses/swiper/swiper_frontswipe_base.vpcf"

--------------------------------------------------------------------------------

function boss_swiper_backswipe:GetPlaybackRateOverride()
	return 0.5
end