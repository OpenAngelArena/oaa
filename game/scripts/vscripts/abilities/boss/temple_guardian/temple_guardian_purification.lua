
temple_guardian_purification = class(AbilityBaseClass)

--------------------------------------------------------------------------------

function temple_guardian_purification:OnAbilityPhaseStart()
  if IsServer() then
    local caster = self:GetCaster()
    self.nPreviewFX = ParticleManager:CreateParticle( "particles/test_particle/generic_attack_charge.vpcf", PATTACH_CUSTOMORIGIN, caster )
    ParticleManager:SetParticleControlEnt( self.nPreviewFX, 0, caster, PATTACH_POINT_FOLLOW, "attach_attack2", caster:GetOrigin(), true )
    ParticleManager:SetParticleControl( self.nPreviewFX, 15, Vector( 255, 215, 0 ) )
    ParticleManager:SetParticleControl( self.nPreviewFX, 16, Vector( 1, 0, 0 ) )

    local delay = self:GetCastPoint()

    caster:AddNewModifier(caster, self, "modifier_anti_stun_oaa", {duration = delay + 0.03})
  end

	return true
end

--------------------------------------------------------------------------------

function temple_guardian_purification:OnAbilityPhaseInterrupted()
	if IsServer() then
    if self.nPreviewFX then
      ParticleManager:DestroyParticle(self.nPreviewFX, true)
      ParticleManager:ReleaseParticleIndex(self.nPreviewFX)
      self.nPreviewFX = nil
    end
  end
end

--------------------------------------------------------------------------------

function temple_guardian_purification:GetPlaybackRateOverride()
	return 0.4
end

--------------------------------------------------------------------------------

function temple_guardian_purification:OnSpellStart()
  if self.nPreviewFX then
    ParticleManager:DestroyParticle(self.nPreviewFX, true)
    ParticleManager:ReleaseParticleIndex(self.nPreviewFX)
    self.nPreviewFX = nil
  end

  local hTarget = self:GetCursorTarget()
  if not hTarget or hTarget:IsNull() or hTarget:IsInvulnerable() or hTarget:IsMagicImmune() then
    return
  end

  local radius = self:GetSpecialValueFor( "radius" )
  local heal = self:GetSpecialValueFor( "heal" )

  hTarget:Heal( heal, self )

  local nFXIndex1 = ParticleManager:CreateParticle( "particles/units/heroes/hero_omniknight/omniknight_purification.vpcf", PATTACH_CUSTOMORIGIN, self:GetCaster() )
  ParticleManager:SetParticleControlEnt( nFXIndex1, 0, hTarget, PATTACH_ABSORIGIN_FOLLOW, nil, hTarget:GetOrigin(), true  );
  ParticleManager:SetParticleControl( nFXIndex1, 1, Vector( radius, radius, radius ) );
  ParticleManager:ReleaseParticleIndex( nFXIndex1 );

  local nFXIndex2 = ParticleManager:CreateParticle( "particles/units/heroes/hero_omniknight/omniknight_purification_cast.vpcf", PATTACH_CUSTOMORIGIN, self:GetCaster() )
  ParticleManager:SetParticleControlEnt( nFXIndex2, 0, self:GetCaster(), PATTACH_POINT_FOLLOW, "attach_attack2", self:GetCaster():GetOrigin(), true );
  ParticleManager:SetParticleControlEnt( nFXIndex2, 1, hTarget, PATTACH_ABSORIGIN_FOLLOW, nil, hTarget:GetOrigin(), true );
  ParticleManager:ReleaseParticleIndex( nFXIndex2 );

  hTarget:EmitSound("TempleGuardian.Purification")

  local enemies = FindUnitsInRadius(
    self:GetCaster():GetTeamNumber(),
    hTarget:GetOrigin(),
    nil,
    radius,
    DOTA_UNIT_TARGET_TEAM_ENEMY,
    bit.bor(DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_BASIC),
    DOTA_UNIT_TARGET_FLAG_NONE,
    FIND_ANY_ORDER,
    false
  )

  local damage_table = {
    attacker = self:GetCaster(),
    damage = heal,
    damage_type = DAMAGE_TYPE_PURE,
    ability = self,
  }

  for _, enemy in pairs( enemies ) do
    if enemy and not enemy:IsNull() and not enemy:IsMagicImmune() and not enemy:IsDebuffImmune() then
      -- Particle
      local nFXIndex3 = ParticleManager:CreateParticle( "particles/units/heroes/hero_omniknight/omniknight_purification_hit.vpcf", PATTACH_ABSORIGIN_FOLLOW, enemy )
      ParticleManager:SetParticleControlEnt( nFXIndex3, 1, enemy, PATTACH_POINT_FOLLOW, "attach_hitloc", enemy:GetOrigin(), true )
      ParticleManager:ReleaseParticleIndex( nFXIndex3 )

      damage_table.victim = enemy
      ApplyDamage(damage_table)
    end
  end
end
