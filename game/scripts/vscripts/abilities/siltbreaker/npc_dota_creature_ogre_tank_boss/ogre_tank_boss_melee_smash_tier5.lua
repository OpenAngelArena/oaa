ogre_tank_boss_melee_smash_tier5 = class( AbilityBaseClass )

LinkLuaModifier( "modifier_ogre_tank_melee_smash_thinker", "modifiers/modifier_ogre_tank_melee_smash_thinker.lua", LUA_MODIFIER_MOTION_NONE )
-----------------------------------------------------------------------------

function ogre_tank_boss_melee_smash_tier5:ProcsMagicStick()
	return false
end

-----------------------------------------------------------------------------

function ogre_tank_boss_melee_smash_tier5:GetCooldown( iLevel )
  -- the cooldown should be lower than the default value if hasted by ogre seer
	return self.BaseClass.GetCooldown( self, self:GetLevel() ) / math.max( self:GetCaster():GetHasteFactor(), 1.0 )
end

-----------------------------------------------------------------------------

function ogre_tank_boss_melee_smash_tier5:GetPlaybackRateOverride()
	return math.min( 2.0, math.max( self:GetCaster():GetHasteFactor(), 1.0 ) )
end

-----------------------------------------------------------------------------

function ogre_tank_boss_melee_smash_tier5:OnSpellStart()
  if IsServer() then
    local caster = self:GetCaster()
		caster:EmitSound("OgreTank.Grunt")
		local flSpeed = self:GetSpecialValueFor( "base_swing_speed" ) / self:GetPlaybackRateOverride()
		local vToTarget = self:GetCursorPosition() - caster:GetOrigin()
		vToTarget = vToTarget:Normalized()
		local vTarget = caster:GetOrigin() + vToTarget * self:GetCastRange( caster:GetOrigin(), nil )
		local hThinker = CreateModifierThinker( caster, self, "modifier_ogre_tank_melee_smash_thinker", { duration = flSpeed }, vTarget, caster:GetTeamNumber(), false )
	end
end

-----------------------------------------------------------------------------

