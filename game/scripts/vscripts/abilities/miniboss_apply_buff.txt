miniboss_apply_buff = class(AbilityBaseClass)
LinkLuaModifier( "modifier_miniboss_base", "modifiers/modifier_miniboss_base.lua", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_miniboss_blue", "modifiers/modifier_miniboss_blue.lua", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_miniboss_red", "modifiers/modifier_miniboss_red.lua", LUA_MODIFIER_MOTION_NONE )
	
function miniboss_apply_buff:GetIntrinsicModifierName()
	return "modifier_miniboss_base"
end
