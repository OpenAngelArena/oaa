
LinkLuaModifier("modifier_generic_bonus", "modifiers/modifier_generic_bonus.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_pull_staff_active_buff", "items/pull_staff.lua", LUA_MODIFIER_MOTION_HORIZONTAL)

item_pull_staff = class(ItemBaseClass)

function item_pull_staff:GetIntrinsicModifierName()
  return "modifier_generic_bonus"
end

function item_pull_staff:CastFilterResultTarget(target)
  --local caster = self:GetCaster()
  local defaultFilterResult = self.BaseClass.CastFilterResultTarget(self, target)

  --if target == caster then
    --return UF_FAIL_CUSTOM
  --end

  local forbidden_modifiers = {
    "modifier_enigma_black_hole_pull",
    "modifier_faceless_void_chronosphere_freeze",
    "modifier_legion_commander_duel",
    "modifier_batrider_flaming_lasso",
    "modifier_disruptor_kinetic_field",
  }
  for _, modifier in pairs(forbidden_modifiers) do
    if target:HasModifier(modifier) then
      return UF_FAIL_CUSTOM
    end
  end

  return defaultFilterResult
end

function item_pull_staff:GetCustomCastErrorTarget(target)
  --local caster = self:GetCaster()
  --if target == caster then
    --return "#dota_hud_error_cant_cast_on_self"
  --end
  if target:HasModifier("modifier_enigma_black_hole_pull") then
    return "#oaa_hud_error_pull_staff_black_hole"
  end
  if target:HasModifier("modifier_faceless_void_chronosphere_freeze") then
    return "#oaa_hud_error_pull_staff_chronosphere"
  end
  if target:HasModifier("modifier_legion_commander_duel") then
    return "#oaa_hud_error_pull_staff_duel"
  end
  if target:HasModifier("modifier_batrider_flaming_lasso") then
    return "#oaa_hud_error_pull_staff_lasso"
  end
  if target:HasModifier("modifier_disruptor_kinetic_field") then
    return "#oaa_hud_error_pull_staff_kinetic_field"
  end
end

function item_pull_staff:OnSpellStart()
  local target = self:GetCursorTarget()
  local caster = self:GetCaster()

  -- Check if target and caster entities exist
  if not target or not caster then
    return
  end

  -- Check if target has spell block
  if target:TriggerSpellAbsorb(self) then
    return
  end

  -- Interrupt enemies only
  if target:GetTeamNumber() ~= caster:GetTeamNumber() then
    target:Stop()
  end

  -- Remove particles of the previous pull staff instance in case of refresher
  if target.pull_staff_particle then
    ParticleManager:DestroyParticle(target.pull_staff_particle, false)
    ParticleManager:ReleaseParticleIndex(target.pull_staff_particle)
    target.pull_staff_particle = nil
  end

  -- KV variables
  local speed = self:GetSpecialValueFor("speed")
  local maxDistance = self:GetSpecialValueFor("distance")

  -- Positions
  local casterposition = caster:GetAbsOrigin()
  local targetposition = target:GetAbsOrigin()

  -- Calculate direction and distance
  local direction
  local distance = 0
  if target ~= caster then
    direction = casterposition - targetposition
    distance = direction:Length2D() - caster:GetPaddedCollisionRadius() - target:GetPaddedCollisionRadius()
    if distance > maxDistance then
      distance = maxDistance
    end
    if distance < 0 then
      distance = 0
    end
  else
    direction = -caster:GetForwardVector()
    distance = maxDistance
  end

  direction.z = 0
  direction = direction:Normalized()

  -- Particle
  target.pull_staff_particle = ParticleManager:CreateParticle("particles/econ/events/ti6/force_staff_ti6.vpcf", PATTACH_ABSORIGIN_FOLLOW, target)

  -- Sound
  target:EmitSound("DOTA_Item.ForceStaff.Activate")

  -- Interrupt existing motion controllers (it should also interrupt existing instances of pull staff)
  if target:IsCurrentlyHorizontalMotionControlled() then
    target:InterruptMotionControllers(false)
  end

  -- Actual effect
  target:AddNewModifier(caster, self, "modifier_pull_staff_active_buff", {
    distance = distance,
    speed = speed,
    direction_x = direction.x,
    direction_y = direction.y,
  })

end

item_pull_staff_2 = item_pull_staff
item_pull_staff_3 = item_pull_staff
item_pull_staff_4 = item_pull_staff
item_pull_staff_5 = item_pull_staff

---------------------------------------------------------------------------------------------------
modifier_pull_staff_active_buff = class(ModifierBaseClass)

function modifier_pull_staff_active_buff:IsHidden()
  return true
end

function modifier_pull_staff_active_buff:IsDebuff()
  return false
end

function modifier_pull_staff_active_buff:IsPurgable()
  return false
end

function modifier_pull_staff_active_buff:GetPriority()
  return DOTA_MOTION_CONTROLLER_PRIORITY_HIGHEST
end

function modifier_pull_staff_active_buff:CheckState()
  return {
    [MODIFIER_STATE_FLYING_FOR_PATHING_PURPOSES_ONLY] = true
  }
end
if IsServer() then
  function modifier_pull_staff_active_buff:OnCreated(event)
    local parent = self:GetParent()

    -- Data sent with AddNewModifier (not available on the client)
    self.direction = Vector(event.direction_x, event.direction_y, 0)
    self.distance = event.distance + 1
    self.speed = event.speed

    if self:ApplyHorizontalMotionController() == false then
      self:Destroy()
      return
    end
  end

  function modifier_pull_staff_active_buff:UpdateHorizontalMotion(parent, deltaTime)
    local parentOrigin = parent:GetAbsOrigin()

    local tickTraveled = deltaTime * self.speed
    tickTraveled = math.min(tickTraveled, self.distance)
    if tickTraveled <= 0 then
      self:Destroy()
    end
    local tickOrigin = parentOrigin + tickTraveled * self.direction
    tickOrigin = Vector(tickOrigin.x, tickOrigin.y, GetGroundHeight(tickOrigin, parent))

    parent:SetAbsOrigin(tickOrigin)

    self.distance = self.distance - tickTraveled

    GridNav:DestroyTreesAroundPoint(tickOrigin, 200, false)
  end

  function modifier_pull_staff_active_buff:OnHorizontalMotionInterrupted()
    self:Destroy()
  end

  function modifier_pull_staff_active_buff:OnDestroy()
    local parent = self:GetParent()
    if parent and not parent:IsNull() then
      parent:RemoveHorizontalMotionController(self)
      FindClearSpaceForUnit(parent, parent:GetAbsOrigin(), false)
      local parent_origin = parent:GetAbsOrigin()
      ResolveNPCPositions(parent_origin, 128)
      if parent.pull_staff_particle then
        ParticleManager:DestroyParticle(parent.pull_staff_particle, false)
        ParticleManager:ReleaseParticleIndex(parent.pull_staff_particle)
        parent.pull_staff_particle = nil
      end
    end
  end
end
