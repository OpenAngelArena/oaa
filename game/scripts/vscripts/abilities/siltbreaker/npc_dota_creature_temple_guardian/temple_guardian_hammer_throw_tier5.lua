temple_guardian_hammer_throw_tier5 = class(AbilityBaseClass)
LinkLuaModifier( "modifier_temple_guardian_hammer_throw", "modifiers/modifier_temple_guardian_hammer_throw", LUA_MODIFIER_MOTION_NONE )

--------------------------------------------------------------------------------

function temple_guardian_hammer_throw_tier5:OnAbilityPhaseStart()
  if IsServer() then
    local caster = self:GetCaster()
		self.nPreviewFX = ParticleManager:CreateParticle( "particles/test_particle/generic_attack_charge.vpcf", PATTACH_CUSTOMORIGIN, caster )
		ParticleManager:SetParticleControlEnt( self.nPreviewFX, 0, caster, PATTACH_POINT_FOLLOW, "attach_attack2", caster:GetOrigin(), true )
		ParticleManager:SetParticleControl( self.nPreviewFX, 15, Vector( 135, 192, 235 ) )
		ParticleManager:SetParticleControl( self.nPreviewFX, 16, Vector( 1, 0, 0 ) )
		ParticleManager:ReleaseParticleIndex( self.nPreviewFX )

		caster:EmitSound("TempleGuardian.PreAttack")
	end

	return true
end

--------------------------------------------------------------------------------

function temple_guardian_hammer_throw_tier5:OnAbilityPhaseInterrupted()
	if IsServer() then
		ParticleManager:DestroyParticle( self.nPreviewFX, true )
	end
end

--------------------------------------------------------------------------------

function temple_guardian_hammer_throw_tier5:GetPlaybackRateOverride()
	return 0.5
end

--------------------------------------------------------------------------

function temple_guardian_hammer_throw_tier5:OnSpellStart()
	if IsServer() then
		ParticleManager:DestroyParticle( self.nPreviewFX, false )

		local vLocation = self:GetCursorPosition()

		local kv =
		{
			x = vLocation.x,
			y = vLocation.y,
		}
		self:GetCaster():AddNewModifier( self:GetCaster(), self, "modifier_temple_guardian_hammer_throw", kv )
	end
end
