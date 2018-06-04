
temple_guardian_hammer_smash_tier5 = class(AbilityBaseClass)

LinkLuaModifier( "modifier_ogre_tank_melee_smash_thinker", "modifiers/modifier_ogre_tank_melee_smash_thinker.lua", LUA_MODIFIER_MOTION_NONE )
--------------------------------------------------------------------------------

function temple_guardian_hammer_smash_tier5:OnAbilityPhaseStart()
	if IsServer() then
		self:GetCaster():EmitSound("TempleGuardian.PreAttack")
	end
	return true
end

--------------------------------------------------------------------------------

function temple_guardian_hammer_smash_tier5:GetPlaybackRateOverride()
	return 0.4450 -- was 0.4013 -- Playbackrate ratio should be kept inversely proportional to HammerSmash base_swing_speed
end

-----------------------------------------------------------------------------

function temple_guardian_hammer_smash_tier5:OnSpellStart()
	if IsServer() then
		local flSpeed = self:GetSpecialValueFor( "base_swing_speed" )
		local vToTarget = self:GetCursorPosition() - self:GetCaster():GetOrigin()
		vToTarget = vToTarget:Normalized()
		local vTarget = self:GetCaster():GetOrigin() + vToTarget * self:GetCastRange( self:GetCaster():GetOrigin(), nil )
		local hThinker = CreateModifierThinker( self:GetCaster(), self, "modifier_ogre_tank_melee_smash_thinker", { duration = flSpeed }, vTarget, self:GetCaster():GetTeamNumber(), false )
	end
end

-----------------------------------------------------------------------------

