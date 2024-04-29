sohei_polarizing_palm = class(AbilityBaseClass)

LinkLuaModifier("modifier_sohei_polarizing_palm_movement", "abilities/sohei/sohei_polarizing_palm.lua", LUA_MODIFIER_MOTION_HORIZONTAL)
LinkLuaModifier("modifier_sohei_polarizing_palm_stun", "abilities/sohei/sohei_polarizing_palm.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_sohei_polarizing_palm_slow", "abilities/sohei/sohei_polarizing_palm.lua", LUA_MODIFIER_MOTION_NONE)

local forbidden_modifiers = {
  "modifier_enigma_black_hole_pull",
  "modifier_faceless_void_chronosphere_freeze",
  "modifier_legion_commander_duel",
  "modifier_batrider_flaming_lasso",
  "modifier_disruptor_kinetic_field",
}

--[[
function sohei_polarizing_palm:GetCastRange(location, target)
  local caster = self:GetCaster()
  local default_range = self.BaseClass.GetCastRange(self, location, target)

  local talent = caster:FindAbilityByName("")
  if talent and talent:GetLevel() > 0 then
    return default_range + talent:GetSpecialValueFor("value")
  end

  return default_range
end
]]

function sohei_polarizing_palm:CastFilterResultTarget(target)
  local caster = self:GetCaster()
  local defaultFilterResult = self.BaseClass.CastFilterResultTarget(self, target)

  if target == caster then
    return UF_FAIL_CUSTOM
  end

  for _, modifier in pairs(forbidden_modifiers) do
    if target:HasModifier(modifier) then
      return UF_FAIL_CUSTOM
    end
  end

  return defaultFilterResult
end

function sohei_polarizing_palm:GetCustomCastErrorTarget(target)
  local caster = self:GetCaster()
  if target == caster then
    return "#dota_hud_error_cant_cast_on_self"
  elseif target:HasModifier("modifier_enigma_black_hole_pull") then
    return "#oaa_hud_error_pull_staff_black_hole"
  elseif target:HasModifier("modifier_faceless_void_chronosphere_freeze") then
    return "#oaa_hud_error_pull_staff_chronosphere"
  elseif target:HasModifier("modifier_legion_commander_duel") then
    return "#oaa_hud_error_pull_staff_duel"
  elseif target:HasModifier("modifier_batrider_flaming_lasso") then
    return "#oaa_hud_error_pull_staff_lasso"
  elseif target:HasModifier("modifier_disruptor_kinetic_field") then
    return "#oaa_hud_error_pull_staff_kinetic_field"
  end
end

function sohei_polarizing_palm:OnSpellStart()
  local caster = self:GetCaster()
  local target = self:GetCursorTarget()

  -- Do nothing for self-cast
  -- (This should never happen because of cast filter)
  if target == caster then
    return
  end

  -- Do nothing if target has a forbidden modifier
  -- (this will happen rarely (lotus orb maybe) because the cast filter already checks this)
  for _, modifier in pairs(forbidden_modifiers) do
    if target:HasModifier(modifier) then
      return
    end
  end

  local target_loc = target:GetAbsOrigin()
  local caster_loc = caster:GetAbsOrigin()
  local isTargetAnEnemy = target:GetTeamNumber() ~= caster:GetTeamNumber()

  local speed = self:GetSpecialValueFor("push_pull_speed")
  local reposition_range = self:GetSpecialValueFor("push_pull_length")

  local direction = target_loc - caster_loc -- default is pushing
  local distance = reposition_range

  local pulling = false
  local flurry = caster:HasModifier("modifier_sohei_flurry_self")
  if pulling then
    -- Pulling towards the caster
    direction = caster_loc - target_loc
    -- Pulling towards Flurry of Blows center during Flurry of Blows
    if flurry then
      local flurry_mod = caster:FindModifierByName("modifier_sohei_flurry_self")
      if flurry_mod.center then
        direction = flurry_mod.center - target_loc
      end
    end
  end

  if isTargetAnEnemy then
    -- Don't do anything if target has Linken's effect or it's spell-immune
    if target:TriggerSpellAbsorb(self) or target:IsMagicImmune() then
      return
    end

    -- For pulling when not in Flurry of Blows
    if pulling and not flurry then
      distance = direction:Length2D() - caster:GetPaddedCollisionRadius() - target:GetPaddedCollisionRadius()
      if distance > reposition_range then
        distance = reposition_range
      end
      if distance <= 0 then
        distance = 1
      end
    end
  end

  -- Normalize direction
  direction.z = 0
  direction = direction:Normalized()

  -- Interrupt existing motion controllers (it should also interrupt existing instances of Polarizing Palm)
  if target:IsCurrentlyHorizontalMotionControlled() then
    target:InterruptMotionControllers(false)
  end

  -- Sounds
  if not isTargetAnEnemy then
    target:EmitSound("Sohei.Dash")
  else
    target:EmitSound("Sohei.Momentum")
  end

  -- Apply motion controller
  target:AddNewModifier(caster, self, "modifier_sohei_polarizing_palm_movement", {
    distance = distance,
    speed = speed,
    direction_x = direction.x,
    direction_y = direction.y,
  })

  if isTargetAnEnemy then
    -- Particle on enemies
    local particleName1 = "particles/hero/sohei/momentum.vpcf"
    if caster:HasModifier("modifier_arcana_dbz") then
      particleName1 = "particles/hero/sohei/arcana/dbz/sohei_momentum_dbz.vpcf"
    elseif caster:HasModifier("modifier_arcana_pepsi") then
      particleName1 = "particles/hero/sohei/arcana/pepsi/sohei_momentum_pepsi.vpcf"
    end

    local particle_enemy = ParticleManager:CreateParticle(particleName1, PATTACH_ABSORIGIN_FOLLOW, caster)
    ParticleManager:SetParticleControl(particle_enemy, 0, target_loc)
    ParticleManager:ReleaseParticleIndex(particle_enemy)
  else
    -- Particle on allies
    local particleName2 = "particles/hero/sohei/sohei_trail.vpcf"
    if caster:HasModifier("modifier_arcana_dbz") then
      particleName2 = "particles/hero/sohei/arcana/dbz/sohei_trail_dbz.vpcf"
    elseif caster:HasModifier("modifier_arcana_pepsi") then
      particleName2 = "particles/hero/sohei/arcana/pepsi/sohei_trail_pepsi.vpcf"
    end

    local end_pos = target_loc + direction * distance

    local particle_ally = ParticleManager:CreateParticle(particleName2, PATTACH_CUSTOMORIGIN, caster)
    ParticleManager:SetParticleControl(particle_ally, 0, target_loc)
    ParticleManager:SetParticleControl(particle_ally, 1, end_pos)
    ParticleManager:ReleaseParticleIndex(particle_ally)
  end
end

---------------------------------------------------------------------------------------------------
-- Repulsive Palm motion controller
modifier_sohei_polarizing_palm_movement = class(ModifierBaseClass)

function modifier_sohei_polarizing_palm_movement:IsDebuff()
  local parent = self:GetParent()
  local caster = self:GetCaster()

  if parent:GetTeamNumber() == caster:GetTeamNumber() then
    return false
  end

  return true
end

function modifier_sohei_polarizing_palm_movement:IsHidden()
  return true
end

function modifier_sohei_polarizing_palm_movement:IsPurgable()
  return true
end

function modifier_sohei_polarizing_palm_movement:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_OVERRIDE_ANIMATION,
  }
end

function modifier_sohei_polarizing_palm_movement:GetOverrideAnimation()
  return ACT_DOTA_FLAIL
end

function modifier_sohei_polarizing_palm_movement:GetPriority()
  return DOTA_MOTION_CONTROLLER_PRIORITY_HIGHEST
end

function modifier_sohei_polarizing_palm_movement:GetEffectName()
  if self:GetCaster():HasModifier("modifier_arcana_dbz") then
    return "particles/hero/sohei/arcana/dbz/sohei_knockback_dbz.vpcf"
  end
  return "particles/hero/sohei/knockback.vpcf"
end

function modifier_sohei_polarizing_palm_movement:GetEffectAttachType()
  return PATTACH_ABSORIGIN_FOLLOW
end

function modifier_sohei_polarizing_palm_movement:CheckState()
  return {
    [MODIFIER_STATE_NO_UNIT_COLLISION] = true,
    --[MODIFIER_STATE_FLYING_FOR_PATHING_PURPOSES_ONLY] = true
  }
end

if IsServer() then
  function modifier_sohei_polarizing_palm_movement:OnCreated(event)
    -- Data sent with AddNewModifier (not available on the client)
    self.direction = Vector(event.direction_x, event.direction_y, 0)
    self.distance = event.distance + 1
    self.speed = event.speed

    if self:ApplyHorizontalMotionController() == false then
      self:Destroy()
      return
    end
  end

  function modifier_sohei_polarizing_palm_movement:OnDestroy()
    local parent = self:GetParent()
    local caster = self:GetCaster()
    local ability = self:GetAbility()
    local parent_origin = parent:GetAbsOrigin()

    parent:RemoveHorizontalMotionController(self)

    -- Unstuck the parent
    --FindClearSpaceForUnit(parent, parent_origin, false)
    ResolveNPCPositions(parent_origin, 128)

    self:ApplySlow(parent, caster, ability)
    self:PolarizingPalmDamage(parent, caster, ability)
  end

  function modifier_sohei_polarizing_palm_movement:UpdateHorizontalMotion(parent, deltaTime)
    if not parent or parent:IsNull() or not parent:IsAlive() then
      return
    end

    local parentOrigin = parent:GetAbsOrigin()
    local parentTeam = parent:GetTeamNumber()
    local caster = self:GetCaster()
    local casterTeam = caster:GetTeamNumber()

    -- Check if an ally and if affected by nullifier
    local isParentNullified = parentTeam == casterTeam and parent:HasModifier("modifier_item_nullifier_mute")
    -- Check if enemy and if spell-immune or under dispel orb effect
    local isParentDispelled = parentTeam ~= casterTeam and (parent:HasModifier("modifier_item_dispel_orb_active") or parent:IsMagicImmune())

    if isParentNullified or isParentDispelled then
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

    if parentTeam ~= casterTeam then
      local ability = self:GetAbility()

      -- Check for phantom (thinkers) blockers (Fissure, Ice Shards etc.)
      local thinkers = Entities:FindAllByClassnameWithin("npc_dota_thinker", tickOrigin, 70)
      for _, thinker in pairs(thinkers) do
        if thinker and thinker:IsPhantomBlocker() then
          self:ApplyStun(parent, caster, ability)
          self:Destroy()
          return
        end
      end

      -- Check for high ground
      local previous_loc = GetGroundPosition(parentOrigin, parent)
      local new_loc = GetGroundPosition(tickOrigin, parent)
      if new_loc.z-previous_loc.z > 10 and not GridNav:IsTraversable(tickOrigin) then
        self:ApplyStun(parent, caster, ability)
        self:Destroy()
        return
      end

      -- Check for trees; GridNav:IsBlocked( tickOrigin ) doesn't give good results; Trees are destroyed on impact;
      if GridNav:IsNearbyTree(tickOrigin, 120, false) then
        self:ApplyStun(parent, caster, ability)
        GridNav:DestroyTreesAroundPoint(tickOrigin, 120, false)
        self:Destroy()
        return
      end

      -- Check for buildings (requires buildings lua library, otherwise it will return an error)
      if #FindAllBuildingsInRadius(tickOrigin, 30) > 0 or #FindCustomBuildingsInRadius(tickOrigin, 30) > 0 then
        self:ApplyStun(parent, caster, ability)
        self:Destroy()
        return
      end

      -- Check if another enemy hero is on a hero's knockback path, if yes apply debuffs and damage to both heroes
      if parent:IsRealHero() then
        local heroes = FindUnitsInRadius(
          casterTeam,
          tickOrigin,
          nil,
          parent:GetPaddedCollisionRadius(),
          DOTA_UNIT_TARGET_TEAM_ENEMY,
          DOTA_UNIT_TARGET_HERO,
          DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES,
          FIND_CLOSEST,
          false
        )
        local hero_to_impact = heroes[1]
        if hero_to_impact == parent then
          hero_to_impact = heroes[2]
        end
        if hero_to_impact then
          self:ApplyStun(parent, caster, ability)
          self:ApplyStun(hero_to_impact, caster, ability)
          self:PolarizingPalmDamage(hero_to_impact, caster, ability)
          self:Destroy()
          return
        end
      end
    end

    -- Move the unit to the new location if nothing above was detected;
    -- Unstucking (ResolveNPCPositions) is happening OnDestroy;
    parent:SetAbsOrigin(tickOrigin)
  end

  function modifier_sohei_polarizing_palm_movement:OnHorizontalMotionInterrupted()
    self:Destroy()
  end

  function modifier_sohei_polarizing_palm_movement:ApplyStun(unit, caster, ability)
    if not unit or unit:IsMagicImmune() then
      return
    end

    local stun_duration = ability:GetSpecialValueFor("stun_duration")

    -- Talent that increases stun duration
    local talent = caster:FindAbilityByName("special_bonus_sohei_stun")
    if talent and talent:GetLevel() > 0 then
      stun_duration = stun_duration + talent:GetSpecialValueFor("value")
    end

    -- Duration is reduced with Status Resistance
    stun_duration = unit:GetValueChangedByStatusResistance(stun_duration)

    -- Apply stun debuff
    unit:AddNewModifier(caster, ability, "modifier_sohei_polarizing_palm_stun", {duration = stun_duration})

    -- Collision Impact Sound
    unit:EmitSound("Sohei.Momentum.Collision")
  end

  function modifier_sohei_polarizing_palm_movement:ApplySlow(unit, caster, ability)
    if not unit or unit:IsMagicImmune() or unit:GetTeamNumber() == caster:GetTeamNumber() then
      return
    end

    local slow_duration = ability:GetSpecialValueFor("slow_duration")

    -- Apply slow debuff
    unit:AddNewModifier(caster, ability, "modifier_sohei_polarizing_palm_slow", {duration = slow_duration})
  end

  function modifier_sohei_polarizing_palm_movement:PolarizingPalmDamage(unit, caster, ability)
    -- Damage only enemies without spell immunity
    if not unit or unit:IsMagicImmune() or unit:GetTeamNumber() == caster:GetTeamNumber() then
      return
    end

    local base_damage = ability:GetSpecialValueFor("damage")
    local str_multiplier = ability:GetSpecialValueFor("strength_damage")

    -- Talent that increases strength multiplier
    local talent = caster:FindAbilityByName("special_bonus_unique_sohei_9")
    if talent and talent:GetLevel() > 0 then
      str_multiplier = str_multiplier + talent:GetSpecialValueFor("value")
    end

    local bonus_damage = str_multiplier * caster:GetStrength() * 0.01

    local damage_table = {
      attacker = caster,
      victim = unit,
      damage = base_damage + bonus_damage,
      damage_type = ability:GetAbilityDamageType(),
      ability = ability,
    }

    ApplyDamage(damage_table)
  end
end

---------------------------------------------------------------------------------------------------

-- Repulsive Palm Stun debuff
modifier_sohei_polarizing_palm_stun = class(ModifierBaseClass)

function modifier_sohei_polarizing_palm_stun:IsHidden()
  return false
end

function modifier_sohei_polarizing_palm_stun:IsDebuff()
  return true
end

function modifier_sohei_polarizing_palm_stun:IsStunDebuff()
  return true
end

function modifier_sohei_polarizing_palm_stun:IsPurgable()
  return true
end

function modifier_sohei_polarizing_palm_stun:GetEffectName()
  return "particles/generic_gameplay/generic_stunned.vpcf"
end

function modifier_sohei_polarizing_palm_stun:GetEffectAttachType()
  return PATTACH_OVERHEAD_FOLLOW
end

function modifier_sohei_polarizing_palm_stun:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_OVERRIDE_ANIMATION,
  }
end

function modifier_sohei_polarizing_palm_stun:GetOverrideAnimation()
  return ACT_DOTA_DISABLED
end

function modifier_sohei_polarizing_palm_stun:CheckState()
  return {
    [MODIFIER_STATE_STUNNED] = true,
  }
end

---------------------------------------------------------------------------------------------------
-- Repulsive Palm Slow debuff
modifier_sohei_polarizing_palm_slow = class(ModifierBaseClass)

function modifier_sohei_polarizing_palm_slow:IsHidden()
  return self:GetParent():HasModifier("modifier_sohei_polarizing_palm_stun")
end

function modifier_sohei_polarizing_palm_slow:IsDebuff()
  return true
end

function modifier_sohei_polarizing_palm_slow:IsPurgable()
  return true
end

function modifier_sohei_polarizing_palm_slow:OnCreated()
  local ability = self:GetAbility()
  local move_speed_slow = ability:GetSpecialValueFor("move_speed_slow_pct")
  local attack_speed_slow = ability:GetSpecialValueFor("attack_speed_slow")

  -- Move Speed Slow is reduced with Slow Resistance
  self.move_speed_slow = move_speed_slow --parent:GetValueChangedBySlowResistance(move_speed_slow)
  self.attack_speed_slow = attack_speed_slow
end

function modifier_sohei_polarizing_palm_slow:OnRefresh()
  self:OnCreated()
end

function modifier_sohei_polarizing_palm_slow:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
    MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
  }
end

function modifier_sohei_polarizing_palm_slow:GetModifierMoveSpeedBonus_Percentage()
  return 0 - math.abs(self.move_speed_slow)
end

function modifier_sohei_polarizing_palm_slow:GetModifierAttackSpeedBonus_Constant()
  return 0 - math.abs(self.attack_speed_slow)
end
