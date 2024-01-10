magma_boss_projectile = class(AbilityBaseClass)

function magma_boss_projectile:Precache(context)
  PrecacheResource("particle", "particles/magma_boss/fireball_linear.vpcf", context)
  PrecacheResource("particle", "particles/warning/warning_particle_cone.vpcf", context)
  PrecacheResource("soundfile", "soundevents/bosses/magma_boss.vsndevts", context)
end

function magma_boss_projectile:OnAbilityPhaseStart()
  if IsServer() then
    local caster = self:GetCaster()
    local width = math.max(self:GetSpecialValueFor("attack_width_end"), self:GetSpecialValueFor("attack_width_initial"))
    local distance = self:GetSpecialValueFor("attack_distance")

    local target
    if self:GetCursorTarget() then
      target = self:GetCursorTarget():GetOrigin()
    else
      target = self:GetCursorPosition()
    end

    local direction
    if not target then
      direction = caster:GetForwardVector()
    else
      direction = target - caster:GetAbsOrigin()
      direction.z = 0.0
      direction = direction:Normalized()
    end

    -- Warning Particle
    self.nPreviewFX = ParticleManager:CreateParticle("particles/warning/warning_particle_cone.vpcf", PATTACH_WORLDORIGIN, caster)
    ParticleManager:SetParticleControl(self.nPreviewFX, 1, caster:GetAbsOrigin())
    ParticleManager:SetParticleControl(self.nPreviewFX, 2, caster:GetAbsOrigin() + direction*(distance+width) + Vector(0, 0, 50))
    ParticleManager:SetParticleControl(self.nPreviewFX, 3, Vector(width, width, width))
    ParticleManager:SetParticleControl(self.nPreviewFX, 4, Vector(255, 0, 0))
  end

  return true
end

function magma_boss_projectile:OnAbilityPhaseInterrupted()
	if IsServer() then
    if self.nPreviewFX then
      ParticleManager:DestroyParticle(self.nPreviewFX, false)
      ParticleManager:ReleaseParticleIndex(self.nPreviewFX)
      self.nPreviewFX = nil
    end
  end
end

function magma_boss_projectile:GetPlaybackRateOverride()
  return 0.5
end

function magma_boss_projectile:OnSpellStart()
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
  vDirection.z = 0.0
  vDirection = vDirection:Normalized()

  attack_speed = attack_speed * ( attack_distance / ( attack_distance - attack_width_initial ) )

  local info = {
    EffectName = "particles/magma_boss/fireball_linear.vpcf",
    Ability = self,
    vSpawnOrigin = caster:GetOrigin(),
    fStartRadius = attack_width_initial,
    fEndRadius = attack_width_end,
    vVelocity = vDirection * attack_speed,
    fDistance = attack_distance,
    Source = caster,
    iUnitTargetTeam = DOTA_UNIT_TARGET_TEAM_ENEMY,
    iUnitTargetType = bit.bor(DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_BASIC),
  }

  ProjectileManager:CreateLinearProjectile( info )

  -- Sound
  caster:EmitSound("Magma_Boss.AbilityProjectile.Cast1")
end

function magma_boss_projectile:OnProjectileHit( hTarget, vLocation )
  if hTarget and not hTarget:IsMagicImmune() and not hTarget:IsDebuffImmune() and not hTarget:IsInvulnerable() then
    -- Reduce number of sounds
    if hTarget:IsRealHero() then
      hTarget:EmitSound("Magma_Boss.AbilityProjectile.Impact")
    end

    local damageTable = {
      victim = hTarget,
      attacker = self:GetCaster(),
      damage = self:GetSpecialValueFor( "damage_impact" ),
      damage_type = self:GetAbilityDamageType(),
      ability = self
    }

    ApplyDamage( damageTable )
  end

  return false
end
