
boss_swiper_thrust = class(AbilityBaseClass)

--------------------------------------------------------------------------------

function boss_swiper_thrust:Precache(context)
  PrecacheResource("particle", "particles/units/heroes/hero_nyx_assassin/nyx_assassin_impale.vpcf", context)
  PrecacheResource("particle", "particles/econ/items/bloodseeker/bloodseeker_eztzhok_weapon/bloodseeker_bloodbath_eztzhok_burst.vpcf", context)
  PrecacheResource("particle", "particles/warning/warning_particle_cone.vpcf", context)
  PrecacheResource("soundfile", "soundevents/game_sounds_heroes/game_sounds_ursa.vsndevts", context)
end

function boss_swiper_thrust:OnAbilityPhaseStart()
  if IsServer() then
    local caster = self:GetCaster()
    local width = self:GetSpecialValueFor("width")
    local target = GetGroundPosition(self:GetCursorPosition(), caster)
    local distance = (target - caster:GetAbsOrigin()):Length2D()
    --local castTime = self:GetCastPoint()
    local direction = (target - caster:GetAbsOrigin()):Normalized()

    -- Warning particle
    local FX = ParticleManager:CreateParticle("particles/warning/warning_particle_cone.vpcf", PATTACH_WORLDORIGIN, nil)
    ParticleManager:SetParticleControl(FX, 1, caster:GetAbsOrigin())
    ParticleManager:SetParticleControl(FX, 2, caster:GetAbsOrigin() + direction*(distance+width))
    ParticleManager:SetParticleControl(FX, 3, Vector(width, width, width))
    ParticleManager:SetParticleControl(FX, 4, Vector(255, 0, 0))
    ParticleManager:ReleaseParticleIndex(FX)

    --DebugDrawBoxDirection(caster:GetAbsOrigin(), Vector(0,-width / 2,0), Vector(distance,width / 2,50), direction, Vector(255,0,0), 1, castTime)
  end
  return true
end

--------------------------------------------------------------------------------

function boss_swiper_thrust:GetPlaybackRateOverride()
	return 0.275
end

--------------------------------------------------------------------------------

function boss_swiper_thrust:OnSpellStart()
  local caster = self:GetCaster()
  local width = self:GetSpecialValueFor("width")
  local target = GetGroundPosition(self:GetCursorPosition(), caster)
  local distance = (target - caster:GetAbsOrigin()):Length()
  local direction = ((target - caster:GetAbsOrigin()) * Vector(1, 1, 0)):Normalized()
  local velocity = direction * 2000

  local info = {
    EffectName = "particles/units/heroes/hero_nyx_assassin/nyx_assassin_impale.vpcf",
    Ability = self,
    vSpawnOrigin = caster:GetAbsOrigin(),
    fStartRadius = width,
    fEndRadius = width,
    vVelocity = velocity,
    fDistance = distance,
    Source = self:GetCaster(),
    iUnitTargetTeam = DOTA_UNIT_TARGET_TEAM_ENEMY,
    iUnitTargetType = DOTA_UNIT_TARGET_ALL,
    iUnitTargetFlags = DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES,
  }

  ProjectileManager:CreateLinearProjectile( info )
end

function boss_swiper_thrust:OnProjectileHit( target, location )
  if target and not target:IsNull() and not target:IsInvulnerable() then
    --DebugDrawSphere(target:GetAbsOrigin(), Vector(255,0,255), 255, 64, true, 0.3)

    target:EmitSound("hero_ursa.attack")

    local impact = ParticleManager:CreateParticle("particles/econ/items/bloodseeker/bloodseeker_eztzhok_weapon/bloodseeker_bloodbath_eztzhok_burst.vpcf", PATTACH_POINT_FOLLOW, target)
    ParticleManager:ReleaseParticleIndex(impact)

    if not target:IsMagicImmune() and not target:IsDebuffImmune() then
      local damageTable = {
        victim = target,
        attacker = self:GetCaster(),
        damage = self:GetSpecialValueFor("damage"),
        damage_type = self:GetAbilityDamageType(),
        damage_flags = DOTA_DAMAGE_FLAG_BYPASSES_BLOCK,
        ability = self
      }
      ApplyDamage(damageTable)
    end
  end

  return false
end
