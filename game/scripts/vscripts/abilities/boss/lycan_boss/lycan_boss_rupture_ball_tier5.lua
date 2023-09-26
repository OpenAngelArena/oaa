
lycan_boss_rupture_ball_tier5 = class(AbilityBaseClass)

function lycan_boss_rupture_ball_tier5:Precache(context)
  PrecacheResource("particle", "particles/darkmoon_creep_warning.vpcf", context)
  PrecacheResource("particle", "particles/lycanboss_ruptureball_gale.vpcf", context)
  PrecacheResource("soundfile", "soundevents/voscripts/game_sounds_vo_lycan.vsndevts", context)
  --PrecacheResource("soundfile", "soundevents/bosses/game_sounds_dungeon_enemies.vsndevts", context)
end

function lycan_boss_rupture_ball_tier5:OnAbilityPhaseStart()
  if IsServer() then
    local caster = self:GetCaster()
    local delay = self:GetCastPoint()

    -- Cast Sound
    caster:EmitSound("lycan_lycan_attack_09")

    -- Make the caster uninterruptible while casting this ability
    caster:AddNewModifier(caster, self, "modifier_anti_stun_oaa", {duration = delay + 0.1})

    -- Warning particle
    self.nPreviewFX = ParticleManager:CreateParticle( "particles/darkmoon_creep_warning.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster )
    ParticleManager:SetParticleControlEnt( self.nPreviewFX, 0, caster, PATTACH_ABSORIGIN_FOLLOW, nil, caster:GetOrigin(), true )
    ParticleManager:SetParticleControl( self.nPreviewFX, 1, Vector( 150, 150, 150 ) )
    ParticleManager:SetParticleControl( self.nPreviewFX, 15, Vector( 188, 26, 26 ) )
  end

  return true
end

--------------------------------------------------------------------------------

function lycan_boss_rupture_ball_tier5:OnAbilityPhaseInterrupted()
  if IsServer() then
    if self.nPreviewFX then
      ParticleManager:DestroyParticle(self.nPreviewFX, false)
      ParticleManager:ReleaseParticleIndex(self.nPreviewFX)
      self.nPreviewFX = nil
    end
  end
end

-----------------------------------------------------------------------------

function lycan_boss_rupture_ball_tier5:GetPlaybackRateOverride()
	return 0.3
end

--------------------------------------------------------------------------------

function lycan_boss_rupture_ball_tier5:OnSpellStart()
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
    EffectName = "particles/lycanboss_ruptureball_gale.vpcf",
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
  caster:EmitSound("Lycan.RuptureBall")
end

--------------------------------------------------------------------------------

function lycan_boss_rupture_ball_tier5:OnProjectileHit( hTarget, vLocation )
  if hTarget and not hTarget:IsMagicImmune() and not hTarget:IsDebuffImmune() and not hTarget:IsInvulnerable() then
    -- Reduce number of sounds
    if hTarget:IsRealHero() then
      hTarget:EmitSound("Lycan.RuptureBall.Impact")
    end

    -- TODO: do custom rupture modifier, don't use built-in
    hTarget:AddNewModifier( self:GetCaster(), self, "modifier_bloodseeker_rupture", { duration = self:GetSpecialValueFor( "duration" ) } )
  end

  return false
end
