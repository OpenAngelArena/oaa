
LinkLuaModifier("modifier_generic_bonus", "modifiers/modifier_generic_bonus.lua", LUA_MODIFIER_MOTION_NONE)

item_pull_staff = class({})

function item_pull_staff:GetIntrinsicModifierName()
  return "modifier_generic_bonus"
end

function item_pull_staff:OnSpellStart()
  local target = self:GetCursorTarget()
  self.target = target
  local caster = self:GetCaster()

  if target:TriggerSpellAbsorb(self) then
    return
  end

  if target == nil or caster == nil then
    self:StartCooldown(0)
    return
  end

  local speed = self:GetSpecialValueFor("speed")

  local casterposition = caster:GetAbsOrigin()
  local targetposition = target:GetAbsOrigin()

  local vVelocity = casterposition - targetposition
  vVelocity.z = 0.0

  local flDistance = vVelocity:Length2D() - caster:GetPaddedCollisionRadius() - target:GetPaddedCollisionRadius()
  vVelocity = vVelocity:Normalized() * speed


  target:Stop()

  local info = {
    Ability = self,
    --EffectName = "particles/econ/events/ti6/force_staff_ti6.vpcf",
    --EffectName = "particles/econ/items/mirana/mirana_crescent_arrow/mirana_spell_crescent_arrow.vpcf",
    vSpawnOrigin = targetposition,
    vVelocity = vVelocity,
    fDistance = flDistance,
    Source = target,
  }
  local projectile = ProjectileManager:CreateLinearProjectile(info)

  self.particle = ParticleManager:CreateParticle("particles/econ/events/ti6/force_staff_ti6.vpcf", PATTACH_ABSORIGIN_FOLLOW, target)

  --DebugDrawLine(targetposition, targetposition + vVelocity, 255, 0, 0, true, 10)
  --DebugDrawLine(targetposition + Vector(0, 0, 128), casterposition + Vector(0, 0, 128), 0, 255, 0, true, 10)
  --DebugDrawLine(targetposition + Vector(0, 0, 64), targetposition + ProjectileManager:GetLinearProjectileVelocity(projectile) + Vector(0, 0, 64), 0, 0, 255, true, 10)
end

function item_pull_staff:CastFilterResultTarget(target)
  local caster = self:GetCaster()
  local defaultFilterResult = self.BaseClass.CastFilterResultTarget(self, target)
  if defaultFilterResult ~= UF_SUCCESS then
    return defaultFilterResult
  elseif target == caster then
    return UF_FAIL_CUSTOM
  end
end

function item_pull_staff:GetCustomCastErrorTarget(target)
  local caster = self:GetCaster()
  if target == caster then
    return "#dota_hud_error_cant_cast_on_self"
  end
end

function item_pull_staff:OnProjectileThink(vLocation)
  vLocation.z = GetGroundHeight(vLocation, self.target)
  self.target:SetAbsOrigin(vLocation)
end

function item_pull_staff:OnProjectileHit(hTarget, vLocation)
  vLocation.z = GetGroundHeight(vLocation, self.target)
  ParticleManager:DestroyParticle(self.particle, false)
  FindClearSpaceForUnit(self.target, vLocation, true)
  return true
end
