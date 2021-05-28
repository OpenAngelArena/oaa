lycan_boss_claw_lunge = class(AbilityBaseClass)
LinkLuaModifier( "modifier_lycan_boss_claw_lunge", "modifiers/modifier_lycan_boss_claw_lunge", LUA_MODIFIER_MOTION_HORIZONTAL )

--------------------------------------------------------------------------------

function lycan_boss_claw_lunge:OnAbilityPhaseStart()
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

function lycan_boss_claw_lunge:OnAbilityPhaseInterrupted()
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

function lycan_boss_claw_lunge:OnSpellStart()
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

  local vPos = nil
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
  }

  ProjectileManager:CreateLinearProjectile( info )

  caster:AddNewModifier( caster, self, "modifier_lycan_boss_claw_lunge", {} )
end

--------------------------------------------------------------------------------

function lycan_boss_claw_lunge:OnProjectileHit( hTarget, vLocation )
  if hTarget ~= nil then
    if not hTarget:IsInvulnerable() then
      local damageInfo =
      {
        victim = hTarget,
        attacker = self:GetCaster(),
        damage = self.lunge_damage,
        damage_type = DAMAGE_TYPE_PHYSICAL,
        ability = self,
      }
      ApplyDamage( damageInfo )
    end
  else
    local hBuff = self:GetCaster():FindModifierByName( "modifier_lycan_boss_claw_lunge" )
    if hBuff then
      hBuff:Destroy()
    end
  end

  return false
end

--------------------------------------------------------------------------------

function lycan_boss_claw_lunge:OnProjectileThink( vLocation )
  -- Important for modifier_lycan_boss_claw_lunge UpdateHorizontalMotion
  self.vProjectileLocation = vLocation
end
