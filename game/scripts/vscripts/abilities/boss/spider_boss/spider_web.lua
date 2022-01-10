LinkLuaModifier( "modifier_spider_web", "abilities/boss/spider_boss/modifier_spider_web", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_spider_web_effect", "abilities/boss/spider_boss/modifier_spider_web_effect", LUA_MODIFIER_MOTION_NONE )

spider_web = class( AbilityBaseClass )

-------------------------------------------------------------------------

function spider_web:GetIntrinsicModifierName()
	return "modifier_spider_web"
end
