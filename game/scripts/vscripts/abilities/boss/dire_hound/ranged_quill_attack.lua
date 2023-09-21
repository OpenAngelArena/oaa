ranged_quill_attack = class(AbilityBaseClass)

function ranged_quill_attack:OnSpellStart()
  local caster = self:GetCaster()
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
    EffectName = "particles/test_particle/test_model_cluster_linear_projectile.vpcf",
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

  caster:EmitSound("Hound.QuillAttack.Cast")
end

function ranged_quill_attack:OnProjectileHit( hTarget, vLocation )
  if hTarget and not hTarget:IsMagicImmune() and not hTarget:IsDebuffImmune() and not hTarget:IsInvulnerable() then
    local origin = hTarget:GetOrigin()

    local nFXIndex = ParticleManager:CreateParticle( "particles/units/heroes/hero_bristleback/bristleback_quill_spray_impact.vpcf", PATTACH_CUSTOMORIGIN, hTarget )
    ParticleManager:SetParticleControlEnt( nFXIndex, 0, hTarget, PATTACH_ABSORIGIN_FOLLOW, nil, origin, true )
    ParticleManager:SetParticleControlEnt( nFXIndex, 1, hTarget, PATTACH_POINT_FOLLOW, "attach_hitloc", origin, true )
    ParticleManager:SetParticleControlEnt( nFXIndex, 2, self:GetCaster(), PATTACH_ABSORIGIN_FOLLOW, nil, origin, true )
    ParticleManager:ReleaseParticleIndex( nFXIndex )

    local damage_table = {
      victim = hTarget,
      attacker = self:GetCaster(),
      damage = self:GetSpecialValueFor( "attack_damage" ),
      damage_type = DAMAGE_TYPE_PHYSICAL,
      damage_flags = DOTA_DAMAGE_FLAG_BYPASSES_BLOCK,
      ability = self
    }

    ApplyDamage(damage_table)

    hTarget:EmitSound("Hound.QuillAttack.Target")
  end

  return true
end
