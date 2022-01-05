
lycan_boss_rupture_ball = class(AbilityBaseClass)

--------------------------------------------------------------------------------

function lycan_boss_rupture_ball:OnAbilityPhaseStart()
  if IsServer() then
    local caster = self:GetCaster()
		caster:EmitSound("lycan_lycan_attack_09")

		self.nPreviewFX = ParticleManager:CreateParticle( "particles/darkmoon_creep_warning.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster )
		ParticleManager:SetParticleControlEnt( self.nPreviewFX, 0, caster, PATTACH_ABSORIGIN_FOLLOW, nil, caster:GetOrigin(), true )
		ParticleManager:SetParticleControl( self.nPreviewFX, 1, Vector( 150, 150, 150 ) )
		ParticleManager:SetParticleControl( self.nPreviewFX, 15, Vector( 188, 26, 26 ) )
	end

	return true
end

--------------------------------------------------------------------------------

function lycan_boss_rupture_ball:OnAbilityPhaseInterrupted()
  if IsServer() then
    if self.nPreviewFX then
      ParticleManager:DestroyParticle(self.nPreviewFX, false)
      ParticleManager:ReleaseParticleIndex(self.nPreviewFX)
      self.nPreviewFX = nil
    end
  end
end

-----------------------------------------------------------------------------

function lycan_boss_rupture_ball:GetPlaybackRateOverride()
	return 0.3
end

--------------------------------------------------------------------------------

function lycan_boss_rupture_ball:OnSpellStart()
  local caster = self:GetCaster()
  if self.nPreviewFX then
    ParticleManager:DestroyParticle(self.nPreviewFX, true)
    ParticleManager:ReleaseParticleIndex(self.nPreviewFX)
    self.nPreviewFX = nil
  end

  self.attack_speed = self:GetSpecialValueFor( "attack_speed" )
  self.attack_width_initial = self:GetSpecialValueFor( "attack_width_initial" )
  self.attack_width_end = self:GetSpecialValueFor( "attack_width_end" )
  self.attack_distance = self:GetSpecialValueFor( "attack_distance" )

  local vPos = nil
  if self:GetCursorTarget() then
    vPos = self:GetCursorTarget():GetOrigin()
  else
    vPos = self:GetCursorPosition()
  end

  local vDirection = vPos - caster:GetOrigin()
  vDirection.z = 0.0
  vDirection = vDirection:Normalized()

  self.attack_speed = self.attack_speed * ( self.attack_distance / ( self.attack_distance - self.attack_width_initial ) )

  local info = {
    EffectName = "particles/lycanboss_ruptureball_gale.vpcf",
    Ability = self,
    vSpawnOrigin = caster:GetOrigin(),
    fStartRadius = self.attack_width_initial,
    fEndRadius = self.attack_width_end,
    vVelocity = vDirection * self.attack_speed,
    fDistance = self.attack_distance,
    Source = caster,
    iUnitTargetTeam = DOTA_UNIT_TARGET_TEAM_ENEMY,
    iUnitTargetType = DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
  }

  ProjectileManager:CreateLinearProjectile( info )
  caster:EmitSound("Lycan.RuptureBall")
end

--------------------------------------------------------------------------------

function lycan_boss_rupture_ball:OnProjectileHit( hTarget, vLocation )
  if hTarget ~= nil and ( not hTarget:IsMagicImmune() ) and ( not hTarget:IsInvulnerable() ) then
    -- Reduce number of sounds
    if hTarget:IsRealHero() then
      hTarget:EmitSound("Lycan.RuptureBall.Impact")
    end

    hTarget:AddNewModifier( self:GetCaster(), self, "modifier_bloodseeker_rupture", { duration = self:GetSpecialValueFor( "duration" ) } )
  end

  return false
end
