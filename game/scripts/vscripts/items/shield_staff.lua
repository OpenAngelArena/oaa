LinkLuaModifier("modifier_intrinsic_multiplexer", "modifiers/modifier_intrinsic_multiplexer.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_generic_bonus", "modifiers/modifier_generic_bonus.lua", LUA_MODIFIER_MOTION_NONE)
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

--function item_shield_staff:CastFilterResultTarget(target)
  --local caster = self:GetCaster()
  --local defaultFilterResult = self.BaseClass.CastFilterResultTarget(self, target)

  --if target == caster then
    --return UF_FAIL_CUSTOM
  --end

  -- local forbidden_modifiers = {
    -- "modifier_enigma_black_hole_pull",
    -- "modifier_faceless_void_chronosphere_freeze",
    -- "modifier_legion_commander_duel",
    -- "modifier_batrider_flaming_lasso",
    -- "modifier_disruptor_kinetic_field",
  -- }
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

function item_shield_staff:OnSpellStart()
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
    if not target:IsMagicImmune() then
      target:Stop()
      -- Damage table
      local damage_table = {}
      damage_table.attacker = caster
      damage_table.damage_type = DAMAGE_TYPE_MAGICAL
      damage_table.ability = self
      damage_table.damage = self:GetSpecialValueFor("damage_to_enemies")
      damage_table.victim = target
      ApplyDamage(damage_table)
    end
  else
    -- Apply barrier buff to the target
    target:AddNewModifier(caster, self, "modifier_shield_staff_barrier_buff", {
      duration = self:GetSpecialValueFor("barrier_duration"),
      barrierHP = self:GetSpecialValueFor("barrier_block"),
    })
  end

  local forbidden_modifiers = {
    "modifier_enigma_black_hole_pull",
    "modifier_faceless_void_chronosphere_freeze",
    "modifier_legion_commander_duel",
    "modifier_batrider_flaming_lasso",
    "modifier_disruptor_kinetic_field",
  }

  -- If target has any of these debuffs, don't continue
  for _, modifier in pairs(forbidden_modifiers) do
    if target:HasModifier(modifier) then
      return
    end
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

  -- Positions
  local targetposition = target:GetAbsOrigin()

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

function modifier_item_shield_staff_non_stacking_stats:OnCreated()

end

function modifier_item_shield_staff_non_stacking_stats:OnRefresh()

end

function modifier_item_shield_staff_non_stacking_stats:DeclareFunctions()
  local funcs = {
    MODIFIER_PROPERTY_PHYSICAL_CONSTANT_BLOCK,
    MODIFIER_PROPERTY_TOTAL_CONSTANT_BLOCK,
  }

  return funcs
end

function modifier_item_shield_staff_non_stacking_stats:GetModifierPhysical_ConstantBlock()
  if not IsServer() then
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

  local chance = ability:GetSpecialValueFor("passive_attack_damage_block_chance")

  if RollPseudoRandomPercentage(chance, DOTA_PSEUDO_RANDOM_CUSTOM_GAME_1, parent) == true then
    if parent:IsRangedAttacker() then
      return ability:GetSpecialValueFor("passive_attack_damage_block_ranged")
    else
      return ability:GetSpecialValueFor("passive_attack_damage_block_melee")
    end
  end

  return 0
end

function modifier_item_shield_staff_non_stacking_stats:GetModifierTotal_ConstantBlock(event)
  if not IsServer() then
    return
  end

  local parent = self:GetParent()
  local ability = self:GetAbility()

  if not ability or ability:IsNull() then
    return 0
  end

  if event.damage_category == DOTA_DAMAGE_CATEGORY_ATTACK then
    return 0
  end

  if parent:HasModifier("modifier_shield_staff_barrier_buff") then
    return 0
  end

  local chance = ability:GetSpecialValueFor("passive_spell_damage_block_chance")

  if RollPseudoRandomPercentage(chance, DOTA_PSEUDO_RANDOM_CUSTOM_GAME_1, parent) == true then

    local block_amount = ability:GetSpecialValueFor("passive_spell_damage_block")

    SendOverheadEventMessage(nil, OVERHEAD_ALERT_MAGICAL_BLOCK, parent, block_amount, nil)

    return block_amount
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

  if IsServer() then
    if event.barrierHP then
      self:SetStackCount(event.barrierHP)
    end
  end
  -- Particle
  --self.particle = ParticleManager:CreateParticle("", PATTACH_ABSORIGIN_FOLLOW, parent)
  --ParticleManager:SetParticleControlEnt(self.particle, 1, parent, PATTACH_ABSORIGIN_FOLLOW, nil, parent:GetAbsOrigin(), true)

  -- Sound
  parent:EmitSound("Hero_Abaddon.AphoticShield.Cast")
end

function modifier_shield_staff_barrier_buff:OnRefresh(event)
  if self.particle then
    ParticleManager:DestroyParticle(self.particle, false)
    ParticleManager:ReleaseParticleIndex(self.particle)
  end

  self:OnCreated(event)
end

function modifier_shield_staff_barrier_buff:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_TOTAL_CONSTANT_BLOCK,
  }
end

function modifier_shield_staff_barrier_buff:GetModifierTotal_ConstantBlock(event)
  if not IsServer() then
    return
  end

  local parent = self:GetParent()
  local block_amount = event.damage
  local barrier_hp = self:GetStackCount()
  
  -- Don't react on self damage
  if event.attacker == parent then
    return 0
  end

  -- Don't block more than remaining hp
  block_amount = math.min(block_amount, barrier_hp)

  -- Reduce barrier hp
  self:SetStackCount(barrier_hp - block_amount)

  -- Visual effect
  SendOverheadEventMessage(nil, OVERHEAD_ALERT_BLOCK, parent, block_amount, nil)

  -- Remove the barrier if hp is reduced to nothing
  if self:GetStackCount() <= 0 then
    self:Destroy()
  end

  return block_amount
end



function modifier_shield_staff_barrier_buff:OnDestroy()
  if self.particle then
    ParticleManager:DestroyParticle(self.particle, false)
    ParticleManager:ReleaseParticleIndex(self.particle)
  end
end

function modifier_shield_staff_barrier_buff:GetEffectName()
  return "particles/units/heroes/hero_medusa/medusa_mana_shield_oldbase.vpcf"
end

function modifier_shield_staff_barrier_buff:GetEffectAttachType()
  return PATTACH_ABSORIGIN_FOLLOW
end

function modifier_shield_staff_barrier_buff:GetTexture()
  return "custom/force_staff_1"
end