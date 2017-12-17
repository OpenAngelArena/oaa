ogre_tank_boss_melee_smash = class( AbilityBaseClass )

LinkLuaModifier( "modifier_ogre_tank_melee_smash_thinker", "modifiers/modifier_ogre_tank_melee_smash_thinker.lua", LUA_MODIFIER_MOTION_NONE )
-----------------------------------------------------------------------------

function ogre_tank_boss_melee_smash:ProcsMagicStick()
	return false
end

-----------------------------------------------------------------------------

function ogre_tank_boss_melee_smash:GetCooldown( iLevel )
  -- the cooldown should be lower than the default value if hasted by ogre seer
	return self.BaseClass.GetCooldown( self, self:GetLevel() ) / math.max( self:GetCaster():GetHasteFactor(), 1.0 )
end

-----------------------------------------------------------------------------

function ogre_tank_boss_melee_smash:GetPlaybackRateOverride()
	return math.min( 2.0, math.max( self:GetCaster():GetHasteFactor(), 1.0 ) )
end

-----------------------------------------------------------------------------

function ogre_tank_boss_melee_smash:OnSpellStart()
	if IsServer() then
		EmitSoundOn( "OgreTank.Grunt", self:GetCaster() )
		local flSpeed = self:GetSpecialValueFor( "base_swing_speed" ) / self:GetPlaybackRateOverride()
		local vToTarget = self:GetCursorPosition() - self:GetCaster():GetOrigin()
		vToTarget = vToTarget:Normalized()
		local vTarget = self:GetCaster():GetOrigin() + vToTarget * self:GetCastRange( self:GetCaster():GetOrigin(), nil )
		local hThinker = CreateModifierThinker( self:GetCaster(), self, "modifier_ogre_tank_melee_smash_thinker", { duration = flSpeed }, vTarget, self:GetCaster():GetTeamNumber(), false )
	end
end

-----------------------------------------------------------------------------

