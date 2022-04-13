LinkLuaModifier( "modifier_spider_egg_sack", "abilities/boss/spider_boss/modifier_spider_egg_sack", LUA_MODIFIER_MOTION_NONE )

spider_egg_sack = class( AbilityBaseClass )

-------------------------------------------------------------------------

function spider_egg_sack:GetIntrinsicModifierName()
	return "modifier_spider_egg_sack"
end
