LinkLuaModifier("modifier_boss_shielder_shield_crash_passive", "abilities/boss/shielder/boss_shielder_jump.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_boss_shielder_jump", "abilities/boss/shielder/boss_shielder_jump.lua", LUA_MODIFIER_MOTION_BOTH)
LinkLuaModifier("modifier_boss_shielder_shield_crash_debuff", "abilities/boss/shielder/boss_shielder_jump.lua", LUA_MODIFIER_MOTION_NONE)

boss_shielder_jump = class(AbilityBaseClass)

function boss_shielder_jump:Precache(context)
  PrecacheResource("particle", "particles/units/heroes/hero_pangolier/pangolier_tailthump_shield_impact.vpcf", context)
  PrecacheResource("particle", "particles/units/heroes/hero_pangolier/pangolier_tailthump.vpcf", context)
  PrecacheResource("soundfile", "soundevents/game_sounds_heroes/game_sounds_pangolier.vsndevts", context)
end

function boss_shielder_jump:GetIntrinsicModifierName()
  return "modifier_boss_shielder_shield_crash_passive"
end

function boss_shielder_jump:ShouldUseResources()
  return true
end

---------------------------------------------------------------------------------------------------

modifier_boss_shielder_shield_crash_passive = class(ModifierBaseClass)

function modifier_boss_shielder_shield_crash_passive:IsHidden()
  return true
end

function modifier_boss_shielder_shield_crash_passive:IsDebuff()
  return false
end

function modifier_boss_shielder_shield_crash_passive:IsPurgable()
  return false
end

function modifier_boss_shielder_shield_crash_passive:RemoveOnDeath()
  return true
end

function modifier_boss_shielder_shield_crash_passive:DeclareFunctions()
  return {
    MODIFIER_EVENT_ON_TAKEDAMAGE,
  }
end

if IsServer() then
  function modifier_boss_shielder_shield_crash_passive:OnTakeDamage(event)
    local parent = self:GetParent()
    local ability = self:GetAbility()
    local attacker = event.attacker
    local unit = event.unit -- damaged unit

    -- Don't continue if attacker doesn't exist or if attacker is about to be deleted
    if not attacker or attacker:IsNull() then
      return
    end

    -- Check if damaged unit exists
    if not unit or unit:IsNull() then
      return
    end

    -- Do nothing if damaged unit doesn't have this buff or if ability doesn't exist
    if unit ~= parent or not ability or ability:IsNull() then
      return
    end

    -- Don't continue if damage has HP removal flag
    if bit.band(event.damage_flags, DOTA_DAMAGE_FLAG_HPLOSS) == DOTA_DAMAGE_FLAG_HPLOSS then
      return
    end

    -- Don't continue if damage has Reflection flag
    if bit.band(event.damage_flags, DOTA_DAMAGE_FLAG_REFLECTION) == DOTA_DAMAGE_FLAG_REFLECTION then
      return
    end

    -- Don't trigger on self damage or on damage originating from allies
    if attacker == parent or attacker:GetTeamNumber() == parent:GetTeamNumber() then
      return
    end

    -- Don't trigger if attacker is dead, invulnerable, banished, a building or a ward
    if not attacker:IsAlive() or attacker:IsInvulnerable() or attacker:IsOutOfGame() or attacker:IsTower() or attacker:IsOther() then
      return
    end

    if not ability:IsCooldownReady() then
      return
    end

    local chance = ability:GetSpecialValueFor("proc_chance")/100

    -- Get number of failures
    local prngMult = self:GetStackCount() + 1

    if RandomFloat(0.0, 1.0) <= (PrdCFinder:GetCForP(chance) * prngMult) then
      -- Reset failure count
      self:SetStackCount(0)

      -- Interrupt existing motion controllers
      if parent:IsCurrentlyVerticalMotionControlled() or parent:IsCurrentlyHorizontalMotionControlled() then
        parent:InterruptMotionControllers(false)
      end

      -- Apply a jump modifier
      parent:AddNewModifier(parent, ability, "modifier_boss_shielder_jump", {duration = ability:GetSpecialValueFor("jump_duration")})

      -- Start cooldown
      ability:UseResources(false, false, false, true)
    else
      -- Increment number of failures
      self:SetStackCount(prngMult)
    end
  end
end

---------------------------------------------------------------------------------------------------

modifier_boss_shielder_jump = class(ModifierBaseClass)

function modifier_boss_shielder_jump:IsHidden()
  return true
end

function modifier_boss_shielder_jump:IsDebuff()
  return false
end

function modifier_boss_shielder_jump:IsPurgable()
  return false
end

function modifier_boss_shielder_jump:RemoveOnDeath()
  return true
end

function modifier_boss_shielder_jump:GetPriority()
  return DOTA_MOTION_CONTROLLER_PRIORITY_HIGHEST
end

function modifier_boss_shielder_jump:OnCreated(event)
  if not IsServer() then
    return
  end

  local parent = self:GetParent()
  local ability = self:GetAbility()

  -- Get duration
  local duration = event.duration

  -- Get horizontal direction
  local direction = parent:GetForwardVector()
  direction.z = 0
  self.direction = direction:Normalized()

  -- Get horizontal distance
  local hor_distance = ability:GetSpecialValueFor("jump_horizontal_distance")

  -- Get height
  local height = ability:GetSpecialValueFor("jump_height")

  -- Get speed and travel distance
  self.speed = math.max(hor_distance, 2*height) / duration
  self.hor_distance = 0
  self.ver_distance = 0

  if hor_distance > 0 then
    self.hor_distance = hor_distance
    if not self:ApplyHorizontalMotionController() then
      self:Destroy()
    end
  end

  if height > 0 then
    self.ver_distance = 2*height
    self.up_distance = height
    self.down_distance = height
    if not self:ApplyVerticalMotionController() then
      self:Destroy()
    end
  end
end

function modifier_boss_shielder_jump:UpdateHorizontalMotion(parent, deltaTime)
  if not IsServer() then
    return
  end
  local parentOrigin = parent:GetAbsOrigin()
  local tickTraveled = deltaTime * self.speed
  tickTraveled = math.min(tickTraveled, self.hor_distance)
  if tickTraveled <= 0 then
    --self:Destroy()
    return
  end
  local tickOrigin = parentOrigin + tickTraveled * self.direction
  tickOrigin = Vector(tickOrigin.x, tickOrigin.y, GetGroundHeight(tickOrigin, parent))

  parent:SetAbsOrigin(tickOrigin)

  self.hor_distance = self.hor_distance - tickTraveled

  GridNav:DestroyTreesAroundPoint(tickOrigin, 200, false)
end

function modifier_boss_shielder_jump:UpdateVerticalMotion(parent, deltaTime)
  if not IsServer() then
    return
  end
  if self.ver_distance <= 0 then
    --self:Destroy()
    return
  end

  local parentOrigin = parent:GetAbsOrigin()
  local tickTraveled = deltaTime * self.speed

  if self.up_distance > 0 then
    tickTraveled = math.min(tickTraveled, self.up_distance)
    if tickTraveled > 0 then
      local tickOriginZ = parentOrigin.z + tickTraveled
      local tickOrigin = Vector(parentOrigin.x, parentOrigin.y, tickOriginZ)

      parent:SetAbsOrigin(tickOrigin)

      self.up_distance = self.up_distance - tickTraveled
    end
  else
    tickTraveled = math.min(tickTraveled, self.down_distance)
    if tickTraveled > 0 then
      local tickOriginZ = parentOrigin.z - tickTraveled
      local tickOrigin = Vector(parentOrigin.x, parentOrigin.y, tickOriginZ)

      if tickOriginZ < GetGroundHeight(tickOrigin, parent) then
        self:Destroy()
        return
      end

      parent:SetAbsOrigin(tickOrigin)

      self.down_distance = self.down_distance - tickTraveled
    else
      --self:Destroy()
      return
    end
  end

  self.ver_distance = self.ver_distance - tickTraveled
end

function modifier_boss_shielder_jump:OnHorizontalMotionInterrupted()
  self:Destroy()
end

function modifier_boss_shielder_jump:OnVerticalMotionInterrupted()
  self:Destroy()
end

function modifier_boss_shielder_jump:OnDestroy()
  if not IsServer() then
    return
  end
  local parent = self:GetParent()
  if parent and not parent:IsNull() then
    if self.hor_distance > 0 then
      parent:RemoveHorizontalMotionController(self)
    end
    if self.ver_distance > 0 then
      parent:RemoveVerticalMotionController(self)
    end
    FindClearSpaceForUnit(parent, parent:GetAbsOrigin(), false)
    local parent_origin = parent:GetAbsOrigin()
    ResolveNPCPositions(parent_origin, 128)

    local ability = self:GetAbility()
    if not ability or ability:IsNull() then
      return
    end
    local radius = ability:GetSpecialValueFor("radius")
    local damage = ability:GetSpecialValueFor("damage")
    local debuff_duration = ability:GetSpecialValueFor("debuff_duration")
    local target_team = ability:GetAbilityTargetTeam()
    local target_type = ability:GetAbilityTargetType()
    local enemies = FindUnitsInRadius(parent:GetTeamNumber(), parent_origin, nil, radius, target_team, target_type, DOTA_UNIT_TARGET_FLAG_NONE, FIND_ANY_ORDER, false)
    local damage_type = ability:GetAbilityDamageType()
    local damage_table = {
      attacker = parent,
      damage = damage,
      damage_type = damage_type,
      damage_flags = DOTA_DAMAGE_FLAG_BYPASSES_BLOCK,
      ability = ability,
    }

    for _, enemy in pairs(enemies) do
      if enemy and not enemy:IsNull() and not enemy:IsMagicImmune() and not enemy:IsDebuffImmune() then
        -- Apply debuff
        enemy:AddNewModifier(parent, ability, "modifier_boss_shielder_shield_crash_debuff", {duration = debuff_duration})

        -- Particle (on hit enemies)
        local particle = ParticleManager:CreateParticle("particles/units/heroes/hero_pangolier/pangolier_tailthump_shield_impact.vpcf", PATTACH_ABSORIGIN, enemy)
        ParticleManager:ReleaseParticleIndex(particle)

        -- Apply damage
        damage_table.victim = enemy
        ApplyDamage(damage_table)
      end
    end

    -- Particle (on parent, always)
    local particle_always = ParticleManager:CreateParticle("particles/units/heroes/hero_pangolier/pangolier_tailthump.vpcf", PATTACH_WORLDORIGIN, parent)
    ParticleManager:SetParticleControl(particle_always, 0, parent_origin)
    ParticleManager:ReleaseParticleIndex(particle_always)

    -- Sound (from parent, always)
    parent:EmitSound("Hero_Pangolier.TailThump")

    if #enemies > 0 then
      -- Sound (from parent, when something is hit)
      parent:EmitSound("Hero_Pangolier.TailThump.Shield")
    end
  end
end

---------------------------------------------------------------------------------------------------

modifier_boss_shielder_shield_crash_debuff = class(ModifierBaseClass)

function modifier_boss_shielder_shield_crash_debuff:IsHidden()
  return false
end

function modifier_boss_shielder_shield_crash_debuff:IsDebuff()
  return true
end

function modifier_boss_shielder_shield_crash_debuff:IsPurgable()
  return true
end

function modifier_boss_shielder_shield_crash_debuff:RemoveOnDeath()
  return true
end

function modifier_boss_shielder_shield_crash_debuff:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_DAMAGEOUTGOING_PERCENTAGE,
  }
end

function modifier_boss_shielder_shield_crash_debuff:GetModifierDamageOutgoing_Percentage()
  local ability = self:GetAbility()
  if ability and not ability:IsNull() then
    return 0 - math.abs(ability:GetSpecialValueFor("attack_damage_reduction"))
  end

  return -40
end
