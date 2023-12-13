spider_boss_poison_spit = class(AbilityBaseClass)

function spider_boss_poison_spit:Precache( context )
  PrecacheResource( "particle", "particles/units/heroes/hero_venomancer/venomancer_venomous_gale.vpcf", context )
  PrecacheResource( "particle", "particles/units/heroes/hero_venomancer/venomancer_venomous_gale_impact.vpcf", context )
  PrecacheResource( "particle", "particles/darkmoon_creep_warning.vpcf", context )
end

function spider_boss_poison_spit:OnAbilityPhaseStart()
  if IsServer() then
    local caster = self:GetCaster()
    -- Warning Particle
    self.nPreviewFX = ParticleManager:CreateParticle( "particles/darkmoon_creep_warning.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster )
    ParticleManager:SetParticleControlEnt( self.nPreviewFX, 0, caster, PATTACH_ABSORIGIN_FOLLOW, nil, caster:GetOrigin(), true )
    ParticleManager:SetParticleControl( self.nPreviewFX, 1, Vector( 150, 150, 150 ) )
    ParticleManager:SetParticleControl( self.nPreviewFX, 15, Vector( 188, 26, 26 ) )
  end

  return true
end

function spider_boss_poison_spit:OnAbilityPhaseInterrupted()
	if IsServer() then
    if self.nPreviewFX then
      ParticleManager:DestroyParticle(self.nPreviewFX, false)
      ParticleManager:ReleaseParticleIndex(self.nPreviewFX)
      self.nPreviewFX = nil
    end
  end
end

function spider_boss_poison_spit:OnSpellStart()
  local caster = self:GetCaster()
  if self.nPreviewFX then
    ParticleManager:DestroyParticle(self.nPreviewFX, true)
    ParticleManager:ReleaseParticleIndex(self.nPreviewFX)
    self.nPreviewFX = nil
  end

  local attack_speed = self:GetSpecialValueFor( "attack_speed" )
  local attack_width_initial = self:GetSpecialValueFor( "attack_width_initial" )
  local attack_width_end = self:GetSpecialValueFor( "attack_width_end" )
  local attack_distance = self:GetSpecialValueFor( "attack_distance" )

  local vPos
  if self:GetCursorTarget() then
    vPos = self:GetCursorTarget():GetOrigin()
  else
    vPos = self:GetCursorPosition()
  end

  local vDirection = vPos - caster:GetOrigin()
  vDirection.z = 0
  vDirection = vDirection:Normalized()

  attack_speed = attack_speed * ( attack_distance / ( attack_distance - attack_width_initial ) )

  local info = {
    EffectName = "particles/units/heroes/hero_venomancer/venomancer_venomous_gale.vpcf",
    Ability = self,
    vSpawnOrigin = caster:GetOrigin(),
    fStartRadius = attack_width_initial,
    fEndRadius = attack_width_end,
    vVelocity = vDirection * attack_speed,
    fDistance = attack_distance,
    Source = caster,
    iUnitTargetTeam = DOTA_UNIT_TARGET_TEAM_ENEMY,
    iUnitTargetType = DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
  }

  ProjectileManager:CreateLinearProjectile( info )

  caster:EmitSound("Spider.PoisonSpit")
end

function spider_boss_poison_spit:OnProjectileHit( hTarget, vLocation )
  local caster = self:GetCaster()
  if hTarget and not hTarget:IsMagicImmune() and not hTarget:IsDebuffImmune() and not hTarget:IsInvulnerable() then
    -- TODO: do custom poison modifier, don't use built-in
    hTarget:AddNewModifier( caster, self, "modifier_venomancer_venomous_gale", { duration = self:GetSpecialValueFor( "duration" ) } )

    local particle = ParticleManager:CreateParticle( "particles/units/heroes/hero_venomancer/venomancer_venomous_gale_impact.vpcf", PATTACH_ABSORIGIN_FOLLOW, hTarget )
    ParticleManager:ReleaseParticleIndex(particle)

    -- Reduce number of sounds
    if hTarget:IsRealHero() then
      hTarget:EmitSound("Spider.PoisonSpit.Impact")
    end
  end

  return false
end
