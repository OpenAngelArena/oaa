LinkLuaModifier("modifier_meepo_earthbind_oaa", "abilities/oaa_meepo_earthbind.lua", LUA_MODIFIER_MOTION_NONE)

meepo_earthbind_oaa = class(AbilityBaseClass)

function meepo_earthbind_oaa:GetCooldown(level)
  --local caster = self:GetCaster()
  local cooldown = self.BaseClass.GetCooldown(self, level)
  -- Clientside code for the talent

  return cooldown
end

function meepo_earthbind_oaa:OnAbilityPhaseStart()
  local caster = self:GetCaster()
  caster:EmitSound("Hero_Meepo.Earthbind.Cast")
  return true
end

function meepo_earthbind_oaa:OnAbilityPhaseInterrupted()
  self:GetCaster():StopSound("Hero_Meepo.Earthbind.Cast")
end

function meepo_earthbind_oaa:OnSpellStart()
  local caster = self:GetCaster()
  local point = self:GetCursorPosition()

  local projectileSpeed = self:GetSpecialValueFor("speed")
  local radius = self:GetSpecialValueFor("radius")

  -- Calculate direction and distance
  local direction = point - caster:GetAbsOrigin()
  local distance = direction:Length2D()
  direction = direction:Normalized()
  direction.z = 0

  -- Calculate velocity
  local velocity = direction * projectileSpeed

  -- Remove previous instance of particle
  if self.particle then
    ParticleManager:DestroyParticle(self.particle, false)
    ParticleManager:ReleaseParticleIndex(self.particle)
  end

  -- Particle
  local particle = ParticleManager:CreateParticle("particles/units/heroes/hero_meepo/meepo_earthbind_projectile_fx.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
  ParticleManager:SetParticleControl(particle, 0, caster:GetAbsOrigin())
  ParticleManager:SetParticleControl(particle, 1, point)
  ParticleManager:SetParticleControl(particle, 2, Vector(projectileSpeed, 0, 0))
  ParticleManager:SetParticleControl(particle, 3, point)
  self.particle = particle

  -- Linear projectile
  local projectileTable = {
    ["Ability"] = self,
    ["EffectName"] = "",
    ["vSpawnOrigin"] = caster:GetAbsOrigin(),
    ["fDistance"] = distance,
    ["fStartRadius"] = radius,
    ["fEndRadius"] = radius,
    ["Source"] = caster,
    ["bHasFrontalCone"] = false,
    ["bReplaceExisting"] = false,
    ["iUnitTargetTeam"] = DOTA_UNIT_TARGET_TEAM_NONE,
    ["iUnitTargetFlags"] = DOTA_UNIT_TARGET_FLAG_NONE,
    ["iUnitTargetType"] = DOTA_UNIT_TARGET_NONE,
    ["fExpireTime"] = (GameRules:GetGameTime() + 0.25) + distance/projectileSpeed,
    ["bDeleteOnHit"] = false,
    ["vVelocity"] = velocity,
    ["bProvidesVision"] = true,
    ["iVisionRadius"] = radius,
    ["iVisionTeamNumber"] = caster:GetTeamNumber()
  }

  ProjectileManager:CreateLinearProjectile(projectileTable)
end

function meepo_earthbind_oaa:OnProjectileHit(target, location)
  local caster = self:GetCaster()

  local duration = self:GetSpecialValueFor("duration")
  local radius = self:GetSpecialValueFor("radius")

  local units = FindUnitsInRadius(
    caster:GetTeamNumber(),
    location,
    nil,
    radius,
    DOTA_UNIT_TARGET_TEAM_ENEMY,
    bit.bor(DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_HERO),
    DOTA_UNIT_TARGET_FLAG_NONE,
    FIND_ANY_ORDER,
    false
  )
  for _, unit in pairs(units) do
    if unit and not unit:IsNull() then
      unit:AddNewModifier(caster, self, "modifier_meepo_earthbind_oaa", {["duration"] = duration})
      unit:EmitSound("Hero_Meepo.Earthbind.Target")
    end
  end

  -- Destroy Particle ?
  ParticleManager:DestroyParticle(self.particle, false)
  ParticleManager:ReleaseParticleIndex(self.particle)

  return true
end

---------------------------------------------------------------------------------------------------

modifier_meepo_earthbind_oaa = class(ModifierBaseClass)

function modifier_meepo_earthbind_oaa:IsHidden()
  return false
end

function modifier_meepo_earthbind_oaa:IsDebuff()
  return true
end

function modifier_meepo_earthbind_oaa:IsPurgable()
  return true
end

function modifier_meepo_earthbind_oaa:RemoveOnDeath()
  return true
end

function modifier_meepo_earthbind_oaa:GetPriority()
  return MODIFIER_PRIORITY_HIGH
end

function modifier_meepo_earthbind_oaa:CheckState()
  return {
    [MODIFIER_STATE_INVISIBLE] = false,
    [MODIFIER_STATE_ROOTED] = true,
  }
end

function modifier_meepo_earthbind_oaa:GetEffectName()
  return "particles/units/heroes/hero_meepo/meepo_earthbind.vpcf"
end
