spider_egg_sack_tier5 = class( AbilityBaseClass )
LinkLuaModifier( "modifier_spider_egg_sack", "modifiers/modifier_spider_egg_sack", LUA_MODIFIER_MOTION_NONE )

-------------------------------------------------------------------------

function spider_egg_sack_tier5:GetIntrinsicModifierName()
	return "modifier_spider_egg_sack"
end
