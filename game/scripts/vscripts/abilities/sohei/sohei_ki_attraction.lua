sohei_ki_attraction = class( AbilityBaseClass )

LinkLuaModifier("modifier_sohei_ki_attraction_movement", "abilities/sohei/sohei_ki_attraction.lua", LUA_MODIFIER_MOTION_HORIZONTAL)
LinkLuaModifier("modifier_sohei_ki_attraction_buff", "abilities/sohei/sohei_ki_attraction.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_sohei_ki_attraction_debuff", "abilities/sohei/sohei_ki_attraction.lua", LUA_MODIFIER_MOTION_NONE)

local forbidden_modifiers = {
  "modifier_enigma_black_hole_pull",
  "modifier_faceless_void_chronosphere_freeze",
  "modifier_legion_commander_duel",
  "modifier_batrider_flaming_lasso",
  "modifier_disruptor_kinetic_field",
}

function sohei_ki_attraction:CastFilterResultTarget(target)
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

function sohei_ki_attraction:GetCustomCastErrorTarget(target)
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

function sohei_ki_attraction:OnHeroCalculateStatBonus()
  local caster = self:GetCaster()

  if caster:HasShardOAA() or self:IsStolen() then
    self:SetHidden(false)
    if self:GetLevel() <= 0 then
      self:SetLevel(1)
    end
  else
    self:SetHidden(true)
  end
end

function sohei_ki_attraction:OnSpellStart()
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

  local speed = self:GetSpecialValueFor("pull_speed")
  local reposition_range = self:GetSpecialValueFor("pull_length")
  local modifier_duration = self:GetSpecialValueFor("duration")

  -- Pulling towards the caster
  local direction = caster_loc - target_loc
  local distance = reposition_range -- this is pull distance for allies, for enemies is defined later
  local flurry = caster:HasModifier("modifier_sohei_flurry_self")

  -- Pulling towards Flurry of Blows center during Flurry of Blows
  if flurry then
    local flurry_mod = caster:FindModifierByName("modifier_sohei_flurry_self")
    if flurry_mod.center then
      direction = flurry_mod.center - target_loc
    end
  end

  if isTargetAnEnemy then
    -- Don't do anything if target has Linken's effect or it's spell-immune
    if target:TriggerSpellAbsorb(self) or target:IsMagicImmune() then
      return
    end

    -- Different distance during Flurry of Blows
    if not flurry then
      distance = direction:Length2D() - caster:GetPaddedCollisionRadius() - target:GetPaddedCollisionRadius()
    else
      distance = direction:Length2D()
    end
    -- Capping distance for enemies
    if distance > reposition_range then -- to prevent pulling enemies more than reposition_range
      distance = reposition_range
    end
    if distance <= 0 then -- to prevent pulling enemies behind you or out of Flurry radius
      distance = 1
    end
  end

  -- Normalize direction
  direction.z = 0
  direction = direction:Normalized()

  -- Interrupt existing motion controllers
  if target:IsCurrentlyHorizontalMotionControlled() then
    target:InterruptMotionControllers(false)
  end

  -- Sounds and modifiers
  if not isTargetAnEnemy then
    target:EmitSound("Sohei.Dash")
    target:AddNewModifier(caster, self, "modifier_sohei_ki_attraction_buff", {duration = modifier_duration})
  else
    target:EmitSound("Sohei.Momentum")
    target:AddNewModifier(caster, self, "modifier_sohei_ki_attraction_debuff", {duration = modifier_duration})
  end

  -- Apply motion controller
  target:AddNewModifier(caster, self, "modifier_sohei_ki_attraction_movement", {
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

modifier_sohei_ki_attraction_movement = class(ModifierBaseClass)

function modifier_sohei_ki_attraction_movement:IsDebuff()
  local parent = self:GetParent()
  local caster = self:GetCaster()

  if parent:GetTeamNumber() == caster:GetTeamNumber() then
    return false
  end

  return true
end

function modifier_sohei_ki_attraction_movement:IsHidden()
  return true
end

function modifier_sohei_ki_attraction_movement:IsPurgable()
  return true
end

function modifier_sohei_ki_attraction_movement:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_OVERRIDE_ANIMATION,
  }
end

function modifier_sohei_ki_attraction_movement:GetOverrideAnimation()
  return ACT_DOTA_FLAIL
end

function modifier_sohei_ki_attraction_movement:GetPriority()
  return DOTA_MOTION_CONTROLLER_PRIORITY_HIGHEST
end

function modifier_sohei_ki_attraction_movement:GetEffectName()
  if self:GetCaster():HasModifier("modifier_arcana_dbz") then
    return "particles/hero/sohei/arcana/dbz/sohei_knockback_dbz.vpcf"
  end
  return "particles/hero/sohei/knockback.vpcf"
end

function modifier_sohei_ki_attraction_movement:GetEffectAttachType()
  return PATTACH_ABSORIGIN_FOLLOW
end

function modifier_sohei_ki_attraction_movement:CheckState()
  return {
    [MODIFIER_STATE_NO_UNIT_COLLISION] = true,
    --[MODIFIER_STATE_FLYING_FOR_PATHING_PURPOSES_ONLY] = true
  }
end

if IsServer() then
  function modifier_sohei_ki_attraction_movement:OnCreated(event)
    -- Data sent with AddNewModifier (not available on the client)
    self.direction = Vector(event.direction_x, event.direction_y, 0)
    self.distance = event.distance + 1
    self.speed = event.speed

    if self:ApplyHorizontalMotionController() == false then
      self:Destroy()
      return
    end
  end

  function modifier_sohei_ki_attraction_movement:OnDestroy()
    local parent = self:GetParent()
    local caster = self:GetCaster()
    local ability = self:GetAbility()
    local parent_origin = parent:GetAbsOrigin()

    parent:RemoveHorizontalMotionController(self)

    -- Unstuck the parent
    --FindClearSpaceForUnit(parent, parent_origin, false)
    ResolveNPCPositions(parent_origin, 128)

    self:Damage(parent, caster, ability)
    self:Heal(parent, caster, ability)
  end

  function modifier_sohei_ki_attraction_movement:UpdateHorizontalMotion(parent, deltaTime)
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
          -- Collision Impact Sound
          parent:EmitSound("Sohei.Momentum.Collision")
          self:Destroy()
          return
        end
      end

      -- Check for high ground
      local previous_loc = GetGroundPosition(parentOrigin, parent)
      local new_loc = GetGroundPosition(tickOrigin, parent)
      if new_loc.z-previous_loc.z > 10 and not GridNav:IsTraversable(tickOrigin) then
        -- Collision Impact Sound
        parent:EmitSound("Sohei.Momentum.Collision")
        self:Destroy()
        return
      end

      -- Check for trees; GridNav:IsBlocked( tickOrigin ) doesn't give good results; Trees are destroyed on impact;
      if GridNav:IsNearbyTree(tickOrigin, 120, false) then
        GridNav:DestroyTreesAroundPoint(tickOrigin, 120, false)
        -- Collision Impact Sound
        parent:EmitSound("Sohei.Momentum.Collision")
        self:Destroy()
        return
      end

      -- Check for buildings (requires buildings lua library, otherwise it will return an error)
      if #FindAllBuildingsInRadius(tickOrigin, 30) > 0 or #FindCustomBuildingsInRadius(tickOrigin, 30) > 0 then
        -- Collision Impact Sound
        parent:EmitSound("Sohei.Momentum.Collision")
        self:Destroy()
        return
      end

      -- Check if another enemy hero is on a hero's knockback path, if yes apply debuffs and damage to both heroes
      if parent:IsHero() then
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
          self:Damage(hero_to_impact, caster, ability)
          -- Collision Impact Sound
          parent:EmitSound("Sohei.Momentum.Collision")
          self:Destroy()
          return
        end
      end
    end

    -- Move the unit to the new location if nothing above was detected;
    -- Unstucking (ResolveNPCPositions) is happening OnDestroy;
    parent:SetAbsOrigin(tickOrigin)
  end

  function modifier_sohei_ki_attraction_movement:OnHorizontalMotionInterrupted()
    self:Destroy()
  end

  function modifier_sohei_ki_attraction_movement:Damage(unit, caster, ability)
    -- Damage only enemies without spell immunity
    if not unit or unit:IsNull() or unit:IsMagicImmune() or unit:GetTeamNumber() == caster:GetTeamNumber() then
      return
    end

    local base_damage = ability:GetSpecialValueFor("damage")
    local str_multiplier = ability:GetSpecialValueFor("strength_damage")
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

  function modifier_sohei_ki_attraction_movement:Heal(unit, caster, ability)
    -- Heal only allies
    if not unit or unit:IsNull() or unit:GetTeamNumber() ~= caster:GetTeamNumber() then
      return
    end

    local heal_ratio = ability:GetSpecialValueFor("heal_ratio")
    if heal_ratio <= 0 then
      return
    end

    local base_damage = ability:GetSpecialValueFor("damage")
    local str_multiplier = ability:GetSpecialValueFor("strength_damage")

    local bonus_damage = str_multiplier * caster:GetStrength() * 0.01
    local total_damage = base_damage + bonus_damage

    local heal_amount = total_damage * heal_ratio

    -- Healing
    unit:Heal(heal_amount, ability)

    local part = ParticleManager:CreateParticle("particles/units/heroes/hero_omniknight/omniknight_purification.vpcf", PATTACH_ABSORIGIN_FOLLOW, unit)
    ParticleManager:SetParticleControl(part, 0, unit:GetAbsOrigin())
    ParticleManager:SetParticleControl(part, 1, Vector(unit:GetModelRadius(), 1, 1))
    ParticleManager:ReleaseParticleIndex(part)

    SendOverheadEventMessage(nil, OVERHEAD_ALERT_HEAL, unit, heal_amount, nil)
  end
end

---------------------------------------------------------------------------------------------------

modifier_sohei_ki_attraction_buff = class(ModifierBaseClass)

function modifier_sohei_ki_attraction_buff:IsHidden()
  return false
end

function modifier_sohei_ki_attraction_buff:IsDebuff()
  return false
end

function modifier_sohei_ki_attraction_buff:IsPurgable()
  return true
end

function modifier_sohei_ki_attraction_buff:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_TOTALDAMAGEOUTGOING_PERCENTAGE,
  }
end

function modifier_sohei_ki_attraction_buff:GetModifierTotalDamageOutgoing_Percentage()
  return self:GetAbility():GetSpecialValueFor("ally_damage_amp")
end

---------------------------------------------------------------------------------------------------

modifier_sohei_ki_attraction_debuff = class(ModifierBaseClass)

function modifier_sohei_ki_attraction_debuff:IsHidden()
  return false
end

function modifier_sohei_ki_attraction_debuff:IsDebuff()
  return true
end

function modifier_sohei_ki_attraction_debuff:IsPurgable()
  return true
end

function modifier_sohei_ki_attraction_debuff:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_TOTALDAMAGEOUTGOING_PERCENTAGE,
  }
end

function modifier_sohei_ki_attraction_debuff:GetModifierTotalDamageOutgoing_Percentage()
  return self:GetAbility():GetSpecialValueFor("enemy_damage_reduction")
end
