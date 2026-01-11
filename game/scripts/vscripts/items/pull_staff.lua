LinkLuaModifier("modifier_pull_staff_active_buff", "items/pull_staff.lua", LUA_MODIFIER_MOTION_HORIZONTAL)
LinkLuaModifier("modifier_pull_staff_echo_strike_passive", "items/pull_staff.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_pull_staff_echo_strike_cd", "items/pull_staff.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_pull_staff_echo_strike_buff", "items/pull_staff.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_pull_staff_echo_strike_slow", "items/pull_staff.lua", LUA_MODIFIER_MOTION_NONE)

item_pull_staff = class(ItemBaseClass)

function item_pull_staff:GetIntrinsicModifierName()
  return "modifier_intrinsic_multiplexer"
end

function item_pull_staff:GetIntrinsicModifierNames()
  return {
    "modifier_generic_bonus",
    "modifier_pull_staff_echo_strike_passive",
  }
end

function item_pull_staff:CastFilterResultTarget(target)
  local caster = self:GetCaster()
  local defaultFilterResult = self.BaseClass.CastFilterResultTarget(self, target)

  if target == caster then
    return UF_FAIL_CUSTOM
  end

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
  local caster = self:GetCaster()
  if target == caster then
    return "#dota_hud_error_cant_cast_on_self"
  end
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

  -- Check if target is something weird
  if target.TriggerSpellAbsorb == nil then
    return
  end

  -- Interrupt enemies only
  if target:GetTeamNumber() ~= caster:GetTeamNumber() then
    -- Don't do anything if target has Linken's effect or it's spell-immune
    if target:TriggerSpellAbsorb(self) or target:IsMagicImmune() then
      return
    end

    -- Interrupt
    --target:Stop()
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
  local caster = self:GetCaster()
  if caster and not caster:IsNull() then
    return self:GetParent():GetTeamNumber() ~= caster:GetTeamNumber()
  else
    return false
  end
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

      local ability = self:GetAbility()
      local echo_strike_slow_duration = 0.8
      if ability and not ability:IsNull() then
        echo_strike_slow_duration = ability:GetSpecialValueFor("echo_strike_slow_duration")
      end
      if not parent:IsMagicImmune() and parent:GetTeamNumber() ~= self:GetCaster():GetTeamNumber() then
        parent:AddNewModifier(self:GetCaster(), ability, "modifier_pull_staff_echo_strike_slow", {duration = echo_strike_slow_duration})
      end

      if parent.pull_staff_particle then
        ParticleManager:DestroyParticle(parent.pull_staff_particle, false)
        ParticleManager:ReleaseParticleIndex(parent.pull_staff_particle)
        parent.pull_staff_particle = nil
      end
    end
  end
end

---------------------------------------------------------------------------------------------------

-- Helper function to determine if target is valid
local function CheckIfValidTarget(target)
  -- Check if target exists
  if not target or target:IsNull() then
    return false
  end

  -- Check if target is an item, rune or something weird
  if target.GetUnitName == nil then
    return false
  end

  -- Don't affect buildings, wards, spell immune units and invulnerable units.
  if target:IsTower() or target:IsBarracks() or target:IsBuilding() or target:IsOther() or target:IsMagicImmune() or target:IsInvulnerable() then
    return false
  end

  return true
end

---------------------------------------------------------------------------------------------------

modifier_pull_staff_echo_strike_passive = class(ModifierBaseClass)

function modifier_pull_staff_echo_strike_passive:IsHidden()
  return true
end

function modifier_pull_staff_echo_strike_passive:IsPurgable()
  return false
end

function modifier_pull_staff_echo_strike_passive:GetAttributes()
  return MODIFIER_ATTRIBUTE_MULTIPLE
end

function modifier_pull_staff_echo_strike_passive:DeclareFunctions()
  return {
    MODIFIER_EVENT_ON_ATTACK_LANDED,
    MODIFIER_EVENT_ON_ATTACK_FAIL,
  }
end

if IsServer() then
  function modifier_pull_staff_echo_strike_passive:TriggerEchoStrike(target, slow)
    local parent = self:GetParent()
    local ability = self:GetAbility()
    local echo_strike_cd = 5
    local echo_strike_slow_duration = 1
    if ability and not ability:IsNull() then
      echo_strike_cd = ability:GetSpecialValueFor("echo_strike_cooldown")
      echo_strike_slow_duration = ability:GetSpecialValueFor("echo_strike_slow_duration")
    end

    local real_cd = echo_strike_cd * parent:GetCooldownReduction()

    parent:AddNewModifier(parent, ability, "modifier_pull_staff_echo_strike_cd", {duration = real_cd})
    parent:AddNewModifier(parent, ability, "modifier_pull_staff_echo_strike_buff", {})

    -- Trigger cd on all Echo Sabres
    for i = DOTA_ITEM_SLOT_1, DOTA_ITEM_SLOT_9 do
      local item = parent:GetItemInSlot(i)
      if item and item:GetName() == "item_echo_sabre" then
        item:StartCooldown(echo_strike_cd*parent:GetCooldownReduction())
      end
    end

    if slow and CheckIfValidTarget(target) then
      target:AddNewModifier(parent, ability, "modifier_pull_staff_echo_strike_slow", {duration = echo_strike_slow_duration})
    end
  end

  function modifier_pull_staff_echo_strike_passive:OnAttackFail(event)
    local parent = self:GetParent()
    local attacker = event.attacker
    local target = event.target

    -- Check if attacker exists
    if not attacker or attacker:IsNull() then
      return
    end

    -- Check if attacker has this modifier
    if attacker ~= parent then
      return
    end

    if parent:IsIllusion() or parent:IsRangedAttacker() then
      return
    end

    if not self:IsFirstItemInInventory() then
      return
    end

    if parent:HasModifier("modifier_pull_staff_echo_strike_cd") or parent:HasModifier("modifier_item_harpoon") then
      return
    end

    -- Trigger Echo Strike without the slow
    self:TriggerEchoStrike(target, false)
  end


  function modifier_pull_staff_echo_strike_passive:OnAttackLanded(event)
    local parent = self:GetParent()
    local attacker = event.attacker
    local target = event.target

    -- Check if attacker exists
    if not attacker or attacker:IsNull() then
      return
    end

    -- Check if attacker has this modifier
    if attacker ~= parent then
      return
    end

    if parent:IsIllusion() or parent:IsRangedAttacker() then
      return
    end

    if not self:IsFirstItemInInventory() then
      return
    end

    if parent:HasModifier("modifier_pull_staff_echo_strike_cd") or parent:HasModifier("modifier_item_harpoon") then
      return
    end

    -- Trigger Echo Strike with the slow
    self:TriggerEchoStrike(target, true)
  end
end

---------------------------------------------------------------------------------------------------

modifier_pull_staff_echo_strike_cd = class({})

function modifier_pull_staff_echo_strike_cd:IsHidden()
  return true
end

function modifier_pull_staff_echo_strike_cd:IsPurgable()
  return false
end

function modifier_pull_staff_echo_strike_cd:RemoveOnDeath()
  return false
end

function modifier_pull_staff_echo_strike_cd:IsDebuff()
  return false
end

---------------------------------------------------------------------------------------------------

modifier_pull_staff_echo_strike_buff = class({})

function modifier_pull_staff_echo_strike_buff:IsHidden()
  return true
end

function modifier_pull_staff_echo_strike_buff:IsPurgable()
  return false
end

function modifier_pull_staff_echo_strike_buff:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
    MODIFIER_EVENT_ON_ATTACK_LANDED,
    MODIFIER_EVENT_ON_ATTACK_FAIL,
  }
end

function modifier_pull_staff_echo_strike_buff:GetModifierAttackSpeedBonus_Constant()
  return 500
end

function modifier_pull_staff_echo_strike_buff:OnCreated()
  if not IsServer() then
    return
  end
  self:StartIntervalThink(0.2)
end

if IsServer() then
  function modifier_pull_staff_echo_strike_buff:OnIntervalThink()
    if self:GetParent():IsRangedAttacker() or not self:GetAbility() then
      self:Destroy()
    end
  end

  function modifier_pull_staff_echo_strike_buff:OnAttackLanded(event)
    local parent = self:GetParent()
    local attacker = event.attacker
    local target = event.target

    -- Check if attacker exists
    if not attacker or attacker:IsNull() then
      return
    end

    -- Check if attacker has this modifier
    if attacker ~= parent then
      return
    end

    if parent:IsIllusion() or parent:IsRangedAttacker() then
      return
    end

    local ability = self:GetAbility()
    local echo_strike_slow_duration = 0.8
    if ability and not ability:IsNull() then
      echo_strike_slow_duration = ability:GetSpecialValueFor("echo_strike_slow_duration")
    end

    if CheckIfValidTarget(target) then
      target:AddNewModifier(parent, ability, "modifier_pull_staff_echo_strike_slow", {duration = echo_strike_slow_duration})
    end

    self:Destroy()
  end

  function modifier_pull_staff_echo_strike_buff:OnAttackFail(event)
    local parent = self:GetParent()
    local attacker = event.attacker

    -- Check if attacker exists
    if not attacker or attacker:IsNull() then
      return
    end

    -- Check if attacker has this modifier
    if attacker ~= parent then
      return
    end

    if parent:IsIllusion() or parent:IsRangedAttacker() then
      return
    end

    self:Destroy()
  end
end

---------------------------------------------------------------------------------------------------

modifier_pull_staff_echo_strike_slow = class({})

function modifier_pull_staff_echo_strike_slow:IsHidden()
  return false
end

function modifier_pull_staff_echo_strike_slow:IsPurgable()
  return true
end

function modifier_pull_staff_echo_strike_slow:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
    --MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
  }
end

function modifier_pull_staff_echo_strike_slow:GetModifierMoveSpeedBonus_Percentage()
  return -100
end

--function modifier_pull_staff_echo_strike_slow:GetModifierAttackSpeedBonus_Constant()
  --return -100
--end

function modifier_pull_staff_echo_strike_slow:GetTexture()
  return "item_echo_sabre"
end
