LinkLuaModifier("modifier_item_shield_staff_non_stacking_stats", "items/shield_staff.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_shield_staff_active_buff", "items/shield_staff.lua", LUA_MODIFIER_MOTION_HORIZONTAL)
LinkLuaModifier("modifier_shield_staff_barrier_buff", "items/shield_staff.lua", LUA_MODIFIER_MOTION_NONE)

item_shield_staff = class(ItemBaseClass)

function item_shield_staff:GetIntrinsicModifierName()
  return "modifier_intrinsic_multiplexer"
end

function item_shield_staff:GetIntrinsicModifierNames()
  return {
    "modifier_generic_bonus",
    "modifier_item_shield_staff_non_stacking_stats"
  }
end

local forbidden_modifiers = {
  "modifier_enigma_black_hole_pull",
  "modifier_faceless_void_chronosphere_freeze",
  "modifier_legion_commander_duel",
  "modifier_batrider_flaming_lasso",
  "modifier_disruptor_kinetic_field",
}

--function item_shield_staff:CastFilterResultTarget(target)
  --local caster = self:GetCaster()
  --local defaultFilterResult = self.BaseClass.CastFilterResultTarget(self, target)

  --if target == caster then
    --return UF_FAIL_CUSTOM
  --end

  -- for _, modifier in pairs(forbidden_modifiers) do
    -- if target:HasModifier(modifier) then
      -- return UF_FAIL_CUSTOM
    -- end
  -- end

  -- return defaultFilterResult
-- end

--function item_shield_staff:GetCustomCastErrorTarget(target)
  --local caster = self:GetCaster()
  --if target == caster then
    --return "#dota_hud_error_cant_cast_on_self"
  --end
  -- if target:HasModifier("modifier_enigma_black_hole_pull") then
    -- return "#oaa_hud_error_pull_staff_black_hole"
  -- end
  -- if target:HasModifier("modifier_faceless_void_chronosphere_freeze") then
    -- return "#oaa_hud_error_pull_staff_chronosphere"
  -- end
  -- if target:HasModifier("modifier_legion_commander_duel") then
    -- return "#oaa_hud_error_pull_staff_duel"
  -- end
  -- if target:HasModifier("modifier_batrider_flaming_lasso") then
    -- return "#oaa_hud_error_pull_staff_lasso"
  -- end
  -- if target:HasModifier("modifier_disruptor_kinetic_field") then
    -- return "#oaa_hud_error_pull_staff_kinetic_field"
  -- end
-- end

function item_shield_staff:GetCooldown(level)
  local cooldown = self.BaseClass.GetCooldown(self, level)

  if IsServer() then
    local target = self:GetCursorTarget()
    for _, modifier in pairs(forbidden_modifiers) do
      if target:HasModifier(modifier) then
        return 0.1 -- cooldown / 2
      end
    end

    -- If target is leashed, reduce cd
    if target:IsLeashedOAA() then
      return 0.1 -- cooldown / 2
    end
  end

  return cooldown
end

function item_shield_staff:OnSpellStart()
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

  -- Interrupt and damage enemies
  if target:GetTeamNumber() ~= caster:GetTeamNumber() then
    -- Don't do anything if target has Linken's effect or it's spell-immune
    if target:TriggerSpellAbsorb(self) or target:IsMagicImmune() then
      return
    end

    -- Interrupt
    target:Stop()

    -- Damage table
    local damage_table = {
      attacker = caster,
      damage_type = DAMAGE_TYPE_PURE,
      ability = self,
      damage = self:GetSpecialValueFor("damage_to_enemies"),
      victim = target,
      damage_flags = DOTA_DAMAGE_FLAG_NON_LETHAL,
    }

    ApplyDamage(damage_table)
  end

  -- If target has any of these debuffs, don't continue
  for _, modifier in pairs(forbidden_modifiers) do
    if target:HasModifier(modifier) then
      return
    end
  end

  -- If target is leashed, don't continue
  if target:IsLeashedOAA() then
    return
  end

  -- Apply buff to allies
  if target:GetTeamNumber() == caster:GetTeamNumber() then
    target:AddNewModifier(caster, self, "modifier_shield_staff_barrier_buff", {duration = self:GetSpecialValueFor("active_duration")})
  end

  -- Remove particles of the previous shield staff instance in case of refresher
  if target.shield_staff_particle then
    ParticleManager:DestroyParticle(target.shield_staff_particle, false)
    ParticleManager:ReleaseParticleIndex(target.shield_staff_particle)
    target.shield_staff_particle = nil
  end

  -- KV variables
  local speed = self:GetSpecialValueFor("push_speed")
  local distance = self:GetSpecialValueFor("push_length")

  -- Get direction
  local direction = target:GetForwardVector()

  direction.z = 0
  direction = direction:Normalized()

  -- Particle
  target.shield_staff_particle = ParticleManager:CreateParticle("particles/econ/events/ti6/force_staff_ti6.vpcf", PATTACH_ABSORIGIN_FOLLOW, target)

  -- Sound
  target:EmitSound("DOTA_Item.ForceStaff.Activate")

  -- Interrupt existing motion controllers (it should also interrupt existing instances of shield staff)
  if target:IsCurrentlyHorizontalMotionControlled() then
    target:InterruptMotionControllers(false)
  end

  -- Actual effect
  target:AddNewModifier(caster, self, "modifier_shield_staff_active_buff", {
    distance = distance,
    speed = speed,
    direction_x = direction.x,
    direction_y = direction.y,
  })

end

item_shield_staff_2 = item_shield_staff
item_shield_staff_3 = item_shield_staff
item_shield_staff_4 = item_shield_staff
item_shield_staff_5 = item_shield_staff

---------------------------------------------------------------------------------------------------

modifier_shield_staff_active_buff = class(ModifierBaseClass)

function modifier_shield_staff_active_buff:IsHidden()
  return true
end

function modifier_shield_staff_active_buff:IsDebuff()
  return false
end

function modifier_shield_staff_active_buff:IsPurgable()
  return false
end

function modifier_shield_staff_active_buff:GetPriority()
  return DOTA_MOTION_CONTROLLER_PRIORITY_HIGHEST
end

function modifier_shield_staff_active_buff:CheckState()
  return {
    [MODIFIER_STATE_FLYING_FOR_PATHING_PURPOSES_ONLY] = true
  }
end
if IsServer() then
  function modifier_shield_staff_active_buff:OnCreated(event)
    -- Data sent with AddNewModifier (not available on the client)
    self.direction = Vector(event.direction_x, event.direction_y, 0)
    self.distance = event.distance + 1
    self.speed = event.speed

    if self:ApplyHorizontalMotionController() == false then
      self:Destroy()
      return
    end
  end

  function modifier_shield_staff_active_buff:UpdateHorizontalMotion(parent, deltaTime)
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

  function modifier_shield_staff_active_buff:OnHorizontalMotionInterrupted()
    self:Destroy()
  end

  function modifier_shield_staff_active_buff:OnDestroy()
    local parent = self:GetParent()
    if parent and not parent:IsNull() then
      parent:RemoveHorizontalMotionController(self)
      FindClearSpaceForUnit(parent, parent:GetAbsOrigin(), false)
      local parent_origin = parent:GetAbsOrigin()
      ResolveNPCPositions(parent_origin, 128)
      if parent.shield_staff_particle then
        ParticleManager:DestroyParticle(parent.shield_staff_particle, false)
        ParticleManager:ReleaseParticleIndex(parent.shield_staff_particle)
        parent.shield_staff_particle = nil
      end
    end
  end
end

---------------------------------------------------------------------------------------------------
-- Parts of Shield Staff that should NOT stack with other Shield Staves

modifier_item_shield_staff_non_stacking_stats = class(ModifierBaseClass)

function modifier_item_shield_staff_non_stacking_stats:IsHidden()
  return true
end

function modifier_item_shield_staff_non_stacking_stats:IsDebuff()
  return false
end

function modifier_item_shield_staff_non_stacking_stats:IsPurgable()
  return false
end

function modifier_item_shield_staff_non_stacking_stats:GetAttributes()
  return MODIFIER_ATTRIBUTE_MULTIPLE
end

function modifier_item_shield_staff_non_stacking_stats:OnCreated()
  if not IsServer() then
    return
  end

  -- Initialize fail counters
  self.damage_block_failures = 0
  self:SetStackCount(0)
end

function modifier_item_shield_staff_non_stacking_stats:OnRefresh()
  if not IsServer() then
    return
  end

  -- Refresh fail counters
  self.damage_block_failures = self.damage_block_failures or 0
  local spell_damage_block_failures = self:GetStackCount() or 0
  self:SetStackCount(spell_damage_block_failures)
end

function modifier_item_shield_staff_non_stacking_stats:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_PHYSICAL_CONSTANT_BLOCK,
    MODIFIER_PROPERTY_TOTAL_CONSTANT_BLOCK,
  }
end

function modifier_item_shield_staff_non_stacking_stats:GetModifierPhysical_ConstantBlock()
  if not IsServer() then
    return
  end

  if not self:IsFirstItemInInventory() then
    return
  end

  local parent = self:GetParent()
  local ability = self:GetAbility()

  if not ability or ability:IsNull() then
    return 0
  end

  if parent:HasModifier("modifier_shield_staff_barrier_buff") then
    return 0
  end

  local chance = ability:GetSpecialValueFor("passive_attack_damage_block_chance") / 100

  if not self.damage_block_failures then
    self.damage_block_failures = 0
  end

  -- Get number of failures
  local prngMult = self.damage_block_failures + 1

  if RandomFloat(0.0, 1.0) <= (PrdCFinder:GetCForP(chance) * prngMult) then
    -- Reset failure count
    self.damage_block_failures = 0

    if parent:IsRangedAttacker() then
      return ability:GetSpecialValueFor("passive_attack_damage_block_ranged")
    else
      return ability:GetSpecialValueFor("passive_attack_damage_block_melee")
    end
  else
    -- Increment number of failures
    self.damage_block_failures = prngMult
  end

  return 0
end

function modifier_item_shield_staff_non_stacking_stats:GetModifierTotal_ConstantBlock(event)
  if not IsServer() then
    return
  end

  if not self:IsFirstItemInInventory() then
    return
  end

  local parent = self:GetParent()
  local ability = self:GetAbility()

  if not ability or ability:IsNull() then
    return 0
  end

  -- Don't react on attacks
  if event.damage_category == DOTA_DAMAGE_CATEGORY_ATTACK then
    return 0
  end

  -- Don't react to damage with HP removal flag
  if bit.band(event.damage_flags, DOTA_DAMAGE_FLAG_HPLOSS) == DOTA_DAMAGE_FLAG_HPLOSS then
    return 0
  end

  -- Don't react on self damage
  if event.attacker == parent then
    return 0
  end

  if parent:HasModifier("modifier_shield_staff_barrier_buff") then
    return 0
  end

  local chance = ability:GetSpecialValueFor("passive_spell_damage_block_chance") / 100

  -- Get number of failures
  local prngMult = self:GetStackCount() + 1

  if RandomFloat(0.0, 1.0) <= (PrdCFinder:GetCForP(chance) * prngMult) then
    -- Reset failure count
    self:SetStackCount(0)

    -- Don't block more than the actual damage
    local block_amount = math.min(ability:GetSpecialValueFor("passive_spell_damage_block"), event.damage)

    if block_amount > 0 then
      -- Visual effect
      SendOverheadEventMessage(nil, OVERHEAD_ALERT_MAGICAL_BLOCK, parent, block_amount, nil)
    end

    return block_amount
  else
    -- Increment number of failures
    self:SetStackCount(prngMult)
  end

  return 0
end

---------------------------------------------------------------------------------------------------

modifier_shield_staff_barrier_buff = class(ModifierBaseClass)

function modifier_shield_staff_barrier_buff:IsDebuff()
  return false
end

function modifier_shield_staff_barrier_buff:IsHidden()
  return false
end

function modifier_shield_staff_barrier_buff:IsPurgable()
  return true
end

function modifier_shield_staff_barrier_buff:OnCreated(event)
  local parent = self:GetParent()
  local ability = self:GetAbility()
  if ability and not ability:IsNull() then
    self.min_dmg = ability:GetSpecialValueFor("active_min_dmg")
  end

  if IsServer() then
    -- Sound
    parent:EmitSound("Hero_Abaddon.AphoticShield.Cast")
  end
end

modifier_shield_staff_barrier_buff.OnRefresh = modifier_shield_staff_barrier_buff.OnCreated

function modifier_shield_staff_barrier_buff:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_INCOMING_DAMAGE_CONSTANT,
  }
end

function modifier_shield_staff_barrier_buff:GetModifierIncomingDamageConstant(event)
  if IsClient() then
    return self.min_dmg
  else
    local parent = self:GetParent()
    local damage = event.damage

    -- Don't react to damage with HP removal flag
    if bit.band(event.damage_flags, DOTA_DAMAGE_FLAG_HPLOSS) == DOTA_DAMAGE_FLAG_HPLOSS then
      return 0
    end

    -- Don't react on self damage
    if event.attacker == parent then
      return 0
    end

    if damage >= self.min_dmg then
      self:Destroy()
      -- Sound
      parent:EmitSound("DOTA_Item.InfusedRaindrop")
      return -damage
    end

    return 0
  end
end

function modifier_shield_staff_barrier_buff:GetEffectName()
  return "particles/units/heroes/hero_medusa/medusa_mana_shield_oldbase.vpcf"
end

function modifier_shield_staff_barrier_buff:GetEffectAttachType()
  return PATTACH_ABSORIGIN_FOLLOW
end

function modifier_shield_staff_barrier_buff:GetTexture()
  return "item_force_staff"
end
