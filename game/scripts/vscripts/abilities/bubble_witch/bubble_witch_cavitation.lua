LinkLuaModifier("modifier_bubble_witch_cavitation_movement", "abilities/bubble_witch/bubble_witch_cavitation.lua", LUA_MODIFIER_MOTION_HORIZONTAL)
LinkLuaModifier("modifier_bubble_witch_cavitation_debuff", "abilities/bubble_witch/bubble_witch_cavitation.lua", LUA_MODIFIER_MOTION_NONE) -- needs tooltip

bubble_witch_cavitation = bubble_witch_cavitation or class({})

function bubble_witch_cavitation:OnSpellStart()
  local caster = self:GetCaster()
  local target = self:GetCursorTarget()

  if target:TriggerSpellAbsorb(self) then
    return
  end

  local duration = self:GetSpecialValueFor("debuff_duration")

  -- Bubble Form Sound
  target:EmitSound("Bubble_Witch.Bubble_Snare.Target")

  -- Apply Debuff
  target:AddNewModifier(caster, self, "modifier_bubble_witch_cavitation_debuff", {duration = duration})

  -- Knock the enemy back slowly
  local distance = self:GetSpecialValueFor("knockback_distance")
  local speed = self:GetSpecialValueFor("knockback_speed")
  local direction = target:GetAbsOrigin() - caster:GetAbsOrigin() -- pushing direction
  -- Normalize direction
  direction.z = 0
  direction = direction:Normalized()

  -- Interrupt existing motion controllers (it should also interrupt existing instances of this spell)
  if target:IsCurrentlyHorizontalMotionControlled() then
    target:InterruptMotionControllers(false)
  end

  -- Apply modifier to attacked unit
  target:AddNewModifier(caster, self, "modifier_bubble_witch_cavitation_movement", {
    distance = distance,
    speed = speed,
    direction_x = direction.x,
    direction_y = direction.y,
    duration = duration + 0.1,
  })
end

---------------------------------------------------------------------------------------------------

-- Motion controller
modifier_bubble_witch_cavitation_movement = class({})

function modifier_bubble_witch_cavitation_movement:IsDebuff()
  return true
end

function modifier_bubble_witch_cavitation_movement:IsHidden()
  return true
end

function modifier_bubble_witch_cavitation_movement:IsPurgable()
  return true
end

function modifier_bubble_witch_cavitation_movement:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_OVERRIDE_ANIMATION,
  }
end

function modifier_bubble_witch_cavitation_movement:GetOverrideAnimation()
  return ACT_DOTA_FLAIL
end

function modifier_bubble_witch_cavitation_movement:GetPriority()
  return DOTA_MOTION_CONTROLLER_PRIORITY_HIGHEST
end

function modifier_bubble_witch_cavitation_movement:CheckState()
  return {
    [MODIFIER_STATE_NO_UNIT_COLLISION] = true,
    [MODIFIER_STATE_FLYING_FOR_PATHING_PURPOSES_ONLY] = true
  }
end

if IsServer() then
  function modifier_bubble_witch_cavitation_movement:OnCreated(event)
    -- Data sent with AddNewModifier (not available on the client)
    self.direction = Vector(event.direction_x, event.direction_y, 0)
    self.distance = event.distance
    self.speed = event.speed --event.distance / (event.duration)

    if self:ApplyHorizontalMotionController() == false then
      self:Destroy()
      return
    end
  end

  function modifier_bubble_witch_cavitation_movement:OnDestroy()
    local parent = self:GetParent()
    local caster = self:GetCaster()
    local ability = self:GetAbility()
    local parent_origin = parent:GetAbsOrigin()

    parent:RemoveHorizontalMotionController(self)

    -- Unstuck the parent
    --FindClearSpaceForUnit(parent, parent_origin, false)
    ResolveNPCPositions(parent_origin, 128)
  end

  function modifier_bubble_witch_cavitation_movement:UpdateHorizontalMotion(parent, deltaTime)
    if not parent or parent:IsNull() or not parent:IsAlive() then
      return
    end

    local parentOrigin = parent:GetAbsOrigin()

    if parent:IsMagicImmune() then
      self:Destroy()
      return
    end

    local tickTraveled = deltaTime * self.speed
    tickTraveled = math.min(tickTraveled, self.distance)
    if tickTraveled <= 0 then
      self:Destroy()
    end
    local tickOrigin = parentOrigin + tickTraveled * self.direction
    tickOrigin = Vector(tickOrigin.x, tickOrigin.y, GetGroundHeight(tickOrigin, parent))

    self.distance = self.distance - tickTraveled

    -- Unstucking (ResolveNPCPositions) is happening OnDestroy;
    parent:SetAbsOrigin(tickOrigin)
  end

  function modifier_bubble_witch_cavitation_movement:OnHorizontalMotionInterrupted()
    self:Destroy()
  end
end

---------------------------------------------------------------------------------------------------

-- Sleep debuff
modifier_bubble_witch_cavitation_debuff = modifier_bubble_witch_cavitation_debuff or class({})

function modifier_bubble_witch_cavitation_debuff:IsHidden()
  return false
end

function modifier_bubble_witch_cavitation_debuff:IsDebuff()
  return true
end

-- Uncomment if dispellable with strong dispel only
-- function modifier_bubble_witch_cavitation_debuff:IsStunDebuff()
  -- return true
-- end

function modifier_bubble_witch_cavitation_debuff:IsPurgable()
  return true
end

--function modifier_bubble_witch_cavitation_debuff:OnCreated()
    --if not IsServer() then return end
    --local particle = ParticleManager:CreateParticle("particles/econ/taunts/snapfire/snapfire_taunt_bubble.vpcf", PATTACH_ABSORIGIN_FOLLOW, self:GetParent())
    --ParticleManager:SetParticleControlEnt( particle, 0, self:GetParent(), PATTACH_POINT_FOLLOW, "attach_hitloc", self:GetParent():GetOrigin(), true )
    --self:AddParticle(particle, false, false, -1, false, false)
    --self:GetParent():AddNewModifier(self:GetCaster(), nil, "modifier_ice_slide", {})
--end

function modifier_bubble_witch_cavitation_debuff:GetEffectName()
  return "particles/econ/taunts/snapfire/snapfire_taunt_bubble.vpcf" -- "particles/units/heroes/hero_siren/naga_siren_song_debuff.vpcf"
end

function modifier_bubble_witch_cavitation_debuff:GetEffectAttachType()
  return PATTACH_ROOTBONE_FOLLOW
end

function modifier_bubble_witch_cavitation_debuff:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_OVERRIDE_ANIMATION,
  }
end

function modifier_bubble_witch_cavitation_debuff:GetOverrideAnimation()
  return ACT_DOTA_FLAIL -- ACT_DOTA_DISABLED
end

function modifier_bubble_witch_cavitation_debuff:CheckState()
  return {
    [MODIFIER_STATE_DISARMED] = true,
    [MODIFIER_STATE_FLYING_FOR_PATHING_PURPOSES_ONLY] = true,
    [MODIFIER_STATE_SILENCED] = true,
    [MODIFIER_STATE_NO_UNIT_COLLISION] = true,
    [MODIFIER_STATE_ROOTED] = true, -- to prevent moving
    [MODIFIER_STATE_TETHERED] = true, -- to prevent Force Staff
    --[MODIFIER_STATE_IGNORING_MOVE_ORDERS] = true,
  }
end

if IsServer() then
  function modifier_bubble_witch_cavitation_debuff:OnDestroy()
    local parent = self:GetParent()
    local caster = self:GetCaster()
    local ability = self:GetAbility()
    local parent_origin = parent:GetAbsOrigin()

    -- Bubble pop damage
    local ability = self:GetAbility()
    if ability and not ability:IsNull() and parent and not parent:IsNull() and parent:IsAlive() then
      local damage_table = {
        attacker = caster,
        victim = parent,
        damage = ability:GetSpecialValueFor("damage"),
        damage_type = ability:GetAbilityDamageType(),
        ability = ability,
      }
      ApplyDamage(damage_table)
    end

    -- Bubble pop particle
    local pfx = ParticleManager:CreateParticle("particles/neutral_fx/frogmen_water_bubble_explosion.vpcf", PATTACH_WORLDORIGIN, parent)
    ParticleManager:SetParticleControl(pfx, 0, parent_origin)
    ParticleManager:ReleaseParticleIndex(pfx)

    -- Bubble pop sound
    if parent and not parent:IsNull() and parent:IsAlive() then
      parent:EmitSound("Bubble_Witch.Bubble.Pop")
    else
      EmitSoundOnLocationWithCaster(parent_origin, "Bubble_Witch.Bubble.Pop", caster)
    end
  end
end
