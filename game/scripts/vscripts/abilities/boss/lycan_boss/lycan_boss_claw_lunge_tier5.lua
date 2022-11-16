LinkLuaModifier( "modifier_lycan_boss_claw_lunge", "abilities/boss/lycan_boss/modifier_lycan_boss_claw_lunge", LUA_MODIFIER_MOTION_HORIZONTAL )

lycan_boss_claw_lunge_tier5 = class(AbilityBaseClass)

function lycan_boss_claw_lunge_tier5:OnAbilityPhaseStart()
  if IsServer() then
    local caster = self:GetCaster()
		caster:StartGesture( ACT_DOTA_CAST_ABILITY_2 )
		caster:EmitSound("LycanBoss.Howl")

		self.nPreviewFX = ParticleManager:CreateParticle( "particles/darkmoon_creep_warning.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster )
		ParticleManager:SetParticleControlEnt( self.nPreviewFX, 0, caster, PATTACH_ABSORIGIN_FOLLOW, nil, caster:GetOrigin(), true )
		ParticleManager:SetParticleControl( self.nPreviewFX, 1, Vector( 150, 150, 150 ) )
		ParticleManager:SetParticleControl( self.nPreviewFX, 15, Vector( 188, 26, 26 ) )
	end

	return true
end

--------------------------------------------------------------------------------

function lycan_boss_claw_lunge_tier5:OnAbilityPhaseInterrupted()
  if IsServer() then
    self:GetCaster():RemoveGesture( ACT_DOTA_CAST_ABILITY_2 )
    if self.nPreviewFX then
      ParticleManager:DestroyParticle(self.nPreviewFX, false)
      ParticleManager:ReleaseParticleIndex(self.nPreviewFX)
      self.nPreviewFX = nil
    end
  end
end

--------------------------------------------------------------------------------

function lycan_boss_claw_lunge_tier5:OnSpellStart()
  local caster = self:GetCaster()
  if self.nPreviewFX then
    ParticleManager:DestroyParticle(self.nPreviewFX, true)
    ParticleManager:ReleaseParticleIndex(self.nPreviewFX)
    self.nPreviewFX = nil
  end
  caster:RemoveGesture( ACT_DOTA_CAST_ABILITY_2 )

  self.lunge_speed = self:GetSpecialValueFor( "lunge_speed" )
  self.lunge_width = self:GetSpecialValueFor( "lunge_width" )
  self.lunge_distance = self:GetSpecialValueFor( "lunge_distance" )
  self.lunge_damage = self:GetSpecialValueFor( "lunge_damage" )

  local vPos
  if self:GetCursorTarget() then
    vPos = self:GetCursorTarget():GetOrigin()
  else
    vPos = self:GetCursorPosition()
  end

  local vDirection = vPos - caster:GetOrigin()
  vDirection.z = 0.0
  vDirection = vDirection:Normalized()

  self.vProjectileLocation = caster:GetOrigin() -- + ( vDirection * 100 )

  local info = {
    EffectName = "particles/units/heroes/hero_ember_spirit/ember_spirit_fire_remnant_trail.vpcf",
    Ability = self,
    vSpawnOrigin = self.vProjectileLocation,
    fStartRadius = self.lunge_width,
    fEndRadius = self.lunge_width,
    vVelocity = vDirection * self.lunge_speed,
    fDistance = self.lunge_distance,
    Source = caster,
    iUnitTargetTeam = DOTA_UNIT_TARGET_TEAM_ENEMY,
    iUnitTargetType = bit.bor(DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_BUILDING),
    iUnitTargetFlags = DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES,
  }

  self.projectile_id = ProjectileManager:CreateLinearProjectile( info )

  caster:AddNewModifier( caster, self, "modifier_lycan_boss_claw_lunge", {} )
end

--------------------------------------------------------------------------------

function lycan_boss_claw_lunge_tier5:OnProjectileHit( hTarget, vLocation )
  local caster = self:GetCaster()
  local hBuff = caster:FindModifierByName("modifier_lycan_boss_claw_lunge")

  if not hTarget or hTarget:IsNull() then
    -- Remove the buff if target doesn't exist
    if hBuff then
      hBuff:Destroy()
    end
    return true -- destroy the projectile if target doesn't exist
  end

  if not hBuff then
    return true -- destroy the projectile if caster doesn't have the buff
  end

  if not hTarget:IsInvulnerable() then
    local damageInfo =
    {
      victim = hTarget,
      attacker = caster,
      damage = self.lunge_damage,
      damage_type = DAMAGE_TYPE_PHYSICAL,
      ability = self,
    }

    ApplyDamage( damageInfo )
  end

  return false -- projectile keeps going
end

--------------------------------------------------------------------------------

function lycan_boss_claw_lunge_tier5:OnProjectileThink( vLocation )
  local caster = self:GetCaster()
  local hBuff = caster:FindModifierByName("modifier_lycan_boss_claw_lunge")

  if not hBuff then
    if self.projectile_id and ProjectileManager:IsValidProjectile(self.projectile_id) then
      ProjectileManager:DestroyLinearProjectile(self.projectile_id)
    end
  end

  if not vLocation then
    return
  end

  -- Important for modifier_lycan_boss_claw_lunge UpdateHorizontalMotion
  self.vProjectileLocation = vLocation
end
