LinkLuaModifier("modifier_anti_stun_oaa", "modifiers/modifier_anti_stun_oaa.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier( "modifier_temple_guardian_hammer_throw", "abilities/boss/temple_guardian/modifier_temple_guardian_hammer_throw", LUA_MODIFIER_MOTION_NONE )

temple_guardian_hammer_throw_tier5 = class(AbilityBaseClass)

--------------------------------------------------------------------------------

function temple_guardian_hammer_throw_tier5:OnAbilityPhaseStart()
  if IsServer() then
    local caster = self:GetCaster()
    self.nPreviewFX = ParticleManager:CreateParticle( "particles/test_particle/generic_attack_charge.vpcf", PATTACH_CUSTOMORIGIN, caster )
    ParticleManager:SetParticleControlEnt( self.nPreviewFX, 0, caster, PATTACH_POINT_FOLLOW, "attach_attack2", caster:GetOrigin(), true )
    ParticleManager:SetParticleControl( self.nPreviewFX, 15, Vector( 135, 192, 235 ) )
    ParticleManager:SetParticleControl( self.nPreviewFX, 16, Vector( 1, 0, 0 ) )

    local delay = self:GetCastPoint()

    caster:AddNewModifier(caster, self, "modifier_anti_stun_oaa", {duration = delay})

    caster:EmitSound("TempleGuardian.PreAttack")
  end

  return true
end

--------------------------------------------------------------------------------

function temple_guardian_hammer_throw_tier5:OnAbilityPhaseInterrupted()
  if IsServer() then
    if self.nPreviewFX then
      ParticleManager:DestroyParticle(self.nPreviewFX, true)
      ParticleManager:ReleaseParticleIndex(self.nPreviewFX)
      self.nPreviewFX = nil
    end
  end
end

--------------------------------------------------------------------------------

function temple_guardian_hammer_throw_tier5:GetPlaybackRateOverride()
	return 0.5
end

--------------------------------------------------------------------------

function temple_guardian_hammer_throw_tier5:OnSpellStart()
  if self.nPreviewFX then
    ParticleManager:DestroyParticle(self.nPreviewFX, true)
    ParticleManager:ReleaseParticleIndex(self.nPreviewFX)
    self.nPreviewFX = nil
  end

  local vLocation = self:GetCursorPosition()

  local kv = {
    x = vLocation.x,
    y = vLocation.y,
  }
  self:GetCaster():AddNewModifier( self:GetCaster(), self, "modifier_temple_guardian_hammer_throw", kv )
end
