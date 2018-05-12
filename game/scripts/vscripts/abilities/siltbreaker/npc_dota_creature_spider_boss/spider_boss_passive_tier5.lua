
spider_boss_passive_tier5 = class( AbilityBaseClass )
LinkLuaModifier( "modifier_spider_boss_passive", "modifiers/modifier_spider_boss_passive", LUA_MODIFIER_MOTION_NONE )

-----------------------------------------------------------------------------------------

function spider_boss_passive_tier5:GetIntrinsicModifierName()
	return "modifier_spider_boss_passive"
end

-----------------------------------------------------------------------------------------
