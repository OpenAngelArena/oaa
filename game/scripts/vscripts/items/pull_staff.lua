
LinkLuaModifier("modifier_generic_bonus", "modifiers/modifier_generic_bonus.lua", LUA_MODIFIER_MOTION_NONE)

item_pull_staff = class(ItemBaseClass)

function item_pull_staff:GetIntrinsicModifierName()
  return "modifier_generic_bonus"
end

function item_pull_staff:OnSpellStart()
  self.hTarget = self:GetCursorTarget()
  local hCaster = self:GetCaster()

  if self.hTarget == nil or hCaster == nil then
    self:StartCooldown(0)
    return
  end

  if self.hTarget:TriggerSpellAbsorb(self) then
    return
  end

  local vCasterPos = hCaster:GetAbsOrigin()
  local vTargetPos = self.hTarget:GetAbsOrigin()
  local iSpeed = self:GetSpecialValueFor("speed")

  local vVelocity = vCasterPos - vTargetPos
  vVelocity.z = 0.0
  local flDistance = vVelocity:Length2D() - hCaster:GetPaddedCollisionRadius() - self.hTarget:GetPaddedCollisionRadius()
  vVelocity = vVelocity:Normalized() * iSpeed

  self.hTarget:Stop()

  local projectile = ProjectileManager:CreateLinearProjectile({
    Ability = self,
    vSpawnOrigin = vTargetPos,
    vVelocity = vVelocity,
    fDistance = flDistance,
    Source = self.hTarget,
  })

  self.particle = ParticleManager:CreateParticle("particles/econ/events/ti6/force_staff_ti6.vpcf", PATTACH_ABSORIGIN_FOLLOW, target)
end

function item_pull_staff:CastFilterResultTarget(hTarget)
  local hCaster = self:GetCaster()
  local defaultFilterResult = self.BaseClass.CastFilterResultTarget(self, hTarget)
  if defaultFilterResult ~= UF_SUCCESS then
    return defaultFilterResult
  elseif hTarget == hCaster then
    return UF_FAIL_CUSTOM
  end
end

function item_pull_staff:GetCustomCastErrorTarget(hTarget)
  local hCaster = self:GetCaster()
  if hTarget == hCaster then
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

item_pull_staff_2 = item_pull_staff
item_pull_staff_3 = item_pull_staff
item_pull_staff_4 = item_pull_staff
