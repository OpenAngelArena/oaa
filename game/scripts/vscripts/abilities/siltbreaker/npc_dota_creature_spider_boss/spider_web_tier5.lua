spider_web_tier5 = class( AbilityBaseClass )
LinkLuaModifier( "modifier_spider_web", "modifiers/modifier_spider_web", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_spider_web_effect", "modifiers/modifier_spider_web_effect", LUA_MODIFIER_MOTION_NONE )

-------------------------------------------------------------------------

function spider_web_tier5:GetIntrinsicModifierName()
	return "modifier_spider_web"
end

-------------------------------------------------------------------------
