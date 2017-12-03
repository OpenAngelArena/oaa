ogre_tank_boss_jump_smash = class( AbilityBaseClass )

LinkLuaModifier( "modifier_ogre_tank_melee_smash_thinker", "modifiers/modifier_ogre_tank_melee_smash_thinker.lua", LUA_MODIFIER_MOTION_NONE )
-----------------------------------------------------------------------------

function ogre_tank_boss_jump_smash:ProcsMagicStick()
	return false
end

-----------------------------------------------------------------------------

function ogre_tank_boss_jump_smash:GetPlaybackRateOverride()
	return self:GetSpecialValueFor("jump_speed") / 1.5 -- 0.9 for 1.8, 0.7 for 1.5
end


-----------------------------------------------------------------------------

function ogre_tank_boss_jump_smash:OnSpellStart()
	if IsServer() then
		local hThinker = CreateModifierThinker( self:GetCaster(), self, "modifier_ogre_tank_melee_smash_thinker", { duration = self:GetSpecialValueFor( "jump_speed") }, self:GetCaster():GetOrigin(), self:GetCaster():GetTeamNumber(), false )
	end
end

-----------------------------------------------------------------------------

