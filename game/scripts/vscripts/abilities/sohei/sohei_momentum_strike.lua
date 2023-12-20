LinkLuaModifier("modifier_sohei_momentum_strike_knockback", "abilities/sohei/sohei_momentum_strike.lua", LUA_MODIFIER_MOTION_HORIZONTAL)
LinkLuaModifier("modifier_sohei_momentum_strike_slow", "abilities/sohei/sohei_momentum_strike.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_sohei_momentum_strike_stun", "abilities/sohei/sohei_momentum_strike.lua", LUA_MODIFIER_MOTION_NONE)

sohei_momentum_strike = class(AbilityBaseClass)

function sohei_momentum_strike:OnSpellStart()
  local caster = self:GetCaster()
  local point = self:GetCursorPosition()

  -- Calculate direction
  local direction = point - caster:GetAbsOrigin()
  direction.z = 0
  direction = direction:Normalized()

  -- Strike parameters
  local width = self:GetSpecialValueFor("strike_radius")
  local range = self:GetSpecialValueFor("strike_range")

  -- Find start and end location
  local start_point = caster:GetAbsOrigin()
  local end_point = start_point + direction * (range + caster:GetCastRangeBonus())

  local enemies = FindUnitsInLine(
    caster:GetTeamNumber(),
    start_point,
    end_point,
    nil,
    width,
    self:GetAbilityTargetTeam(),
    self:GetAbilityTargetType(),
    bit.bor(DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, DOTA_UNIT_TARGET_FLAG_NO_INVIS, DOTA_UNIT_TARGET_FLAG_NOT_ATTACK_IMMUNE)
  )

  -- Knockback parameters
  local knockback_distance = self:GetSpecialValueFor("knockback_distance")
  local knockback_speed = self:GetSpecialValueFor("knockback_speed")
  local knockback_duration = knockback_distance / knockback_speed

  -- Hit particle
  local particleName = "particles/hero/sohei/momentum.vpcf"
  if caster:HasModifier("modifier_arcana_dbz") then
    particleName = "particles/hero/sohei/arcana/dbz/sohei_momentum_dbz.vpcf"
  elseif caster:HasModifier("modifier_arcana_pepsi") then
    particleName = "particles/hero/sohei/arcana/pepsi/sohei_momentum_pepsi.vpcf"
  end

  local ki_strike_particle = ParticleManager:CreateParticle("particles/hero/sohei/ki_strike.vpcf", PATTACH_CUSTOMORIGIN, caster)
  ParticleManager:SetParticleControl(ki_strike_particle, 0, start_point)
  ParticleManager:SetParticleControl(ki_strike_particle, 1, end_point)
  ParticleManager:ReleaseParticleIndex(ki_strike_particle)

  -- Slow duration
  local slow_duration = self:GetSpecialValueFor("slow_duration")

  -- Sounds
  EmitSoundOnLocationWithCaster(start_point, "Sohei.Momentum", caster)
  EmitSoundOnLocationWithCaster(end_point, "Sohei.Momentum", caster)

  for _, enemy in pairs(enemies) do
    if enemy and not enemy:IsNull() then
      -- Apply knockback and slow to the enemy if not spell immune
      if not enemy:IsMagicImmune() then
        -- Impact sound
        --enemy:EmitSound("Sohei.Momentum")
        -- Remove previous instance of knockback
        enemy:RemoveModifierByName("modifier_sohei_momentum_strike_knockback")
        -- Apply new knockback
        enemy:AddNewModifier(caster, self, "modifier_sohei_momentum_strike_knockback", {
          duration = knockback_duration,
          distance = knockback_distance,
          speed = knockback_speed,
          direction_x = direction.x,
          direction_y = direction.y,
        })

        -- Apply slow debuff
        enemy:AddNewModifier(caster, self, "modifier_sohei_momentum_strike_slow", {duration = slow_duration})

        -- Hit particle
        local momentum_pfx = ParticleManager:CreateParticle(particleName, PATTACH_ABSORIGIN_FOLLOW, enemy)
        ParticleManager:SetParticleControl(momentum_pfx, 0, enemy:GetAbsOrigin())
        ParticleManager:ReleaseParticleIndex(momentum_pfx)
      end

      -- Hit the enemy with normal attack that cant miss
      if not caster:IsDisarmed() and not enemy:IsAttackImmune() then
        caster:PerformAttack(enemy, true, true, true, false, false, false, true)
      end
    end
  end
end

---------------------------------------------------------------------------------------------------

-- Knockback modifier
modifier_sohei_momentum_strike_knockback = class(ModifierBaseClass)

function modifier_sohei_momentum_strike_knockback:IsHidden()
  return true
end

function modifier_sohei_momentum_strike_knockback:IsDebuff()
  return true
end

function modifier_sohei_momentum_strike_knockback:IsPurgable()
  return true
end

function modifier_sohei_momentum_strike_knockback:GetPriority()
  return DOTA_MOTION_CONTROLLER_PRIORITY_HIGHEST
end

function modifier_sohei_momentum_strike_knockback:GetEffectName()
  if self:GetCaster():HasModifier("modifier_arcana_dbz") then
    return "particles/hero/sohei/arcana/dbz/sohei_knockback_dbz.vpcf"
  end
  return "particles/hero/sohei/knockback.vpcf"
end

function modifier_sohei_momentum_strike_knockback:GetEffectAttachType()
  return PATTACH_ABSORIGIN_FOLLOW
end

function modifier_sohei_momentum_strike_knockback:CheckState()
  return {
    [MODIFIER_STATE_NO_UNIT_COLLISION] = true,
  }
end

function modifier_sohei_momentum_strike_knockback:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_OVERRIDE_ANIMATION,
  }
end

function modifier_sohei_momentum_strike_knockback:GetOverrideAnimation()
  return ACT_DOTA_FLAIL
end

if IsServer() then
  function modifier_sohei_momentum_strike_knockback:OnCreated( event )
    -- Movement parameters (not available on the client)
    self.direction = Vector(event.direction_x, event.direction_y, 0)
    self.distance = event.distance + 1
    self.speed = event.speed

    if self:ApplyHorizontalMotionController() == false then
      self:Destroy()
      return
    end
  end

  function modifier_sohei_momentum_strike_knockback:OnDestroy()
    local parent = self:GetParent()

    parent:RemoveHorizontalMotionController( self )
    ResolveNPCPositions( parent:GetAbsOrigin(), 128 )
  end

  function modifier_sohei_momentum_strike_knockback:UpdateHorizontalMotion( parent, deltaTime )
    local caster = self:GetCaster()
    if not parent or parent:IsNull() or not parent:IsAlive() then
      return
    end
    local parentOrigin = parent:GetOrigin()
    local ability = self:GetAbility()

    local tickSpeed = self.speed * deltaTime
    tickSpeed = math.min( tickSpeed, self.distance )
    local tickOrigin = parentOrigin + ( tickSpeed * self.direction )

    self.distance = self.distance - tickSpeed

    -- Mars Arena: npc_dota_thinker - modifier_mars_arena_of_blood_thinker - duration: 9.60, createtime: 197.31
    -- Mars Arena: npc_dota_thinker - modifier_mars_arena_of_blood - duration: 9.00, createtime: 197.91
    -- Disruptor Field: npc_dota_thinker - modifier_disruptor_kinetic_field_thinker - duration: 3.80

    -- Check for phantom (thinkers) blockers (Fissure (modifier_earthshaker_fissure), Ice Shards (modifier_tusk_ice_shard) etc.)
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

    -- Check if another enemy hero is on a hero's knockback path, if yes apply debuffs to both heroes
    if parent:IsRealHero() then
      local heroes = FindUnitsInRadius(
        caster:GetTeamNumber(),
        tickOrigin,
        nil,
        parent:GetPaddedCollisionRadius(),
        DOTA_UNIT_TARGET_TEAM_ENEMY,
        DOTA_UNIT_TARGET_HERO,
        bit.bor(DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, DOTA_UNIT_TARGET_FLAG_NO_INVIS, DOTA_UNIT_TARGET_FLAG_NOT_ATTACK_IMMUNE),
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
        self:Destroy()
        return
      end
    end

    -- Move the unit to the new location if nothing above was detected;
    -- Unstucking (ResolveNPCPositions) is happening OnDestroy;
    parent:SetOrigin(tickOrigin)
  end

  function modifier_sohei_momentum_strike_knockback:ApplyStun(unit, caster, ability)
    local stun_duration = ability:GetSpecialValueFor("stun_duration")

    -- Talent that increases stun duration
    local talent = caster:FindAbilityByName("special_bonus_sohei_stun")
    if talent and talent:GetLevel() > 0 then
      stun_duration = stun_duration + talent:GetSpecialValueFor("value")
    end

    -- Duration is reduced with Status Resistance
    stun_duration = unit:GetValueChangedByStatusResistance(stun_duration)

    -- Apply stun debuff
    unit:AddNewModifier(caster, ability, "modifier_sohei_momentum_strike_stun", {duration = stun_duration})

    -- Collision Impact Sound
    unit:EmitSound("Sohei.Momentum.Collision")
  end
end

---------------------------------------------------------------------------------------------------

-- Slow debuff
modifier_sohei_momentum_strike_slow = class(ModifierBaseClass)

function modifier_sohei_momentum_strike_slow:IsHidden()
  return false
end

function modifier_sohei_momentum_strike_slow:IsDebuff()
  return true
end

function modifier_sohei_momentum_strike_slow:IsPurgable()
  return true
end

function modifier_sohei_momentum_strike_slow:OnCreated()
  local parent = self:GetParent()
  local movement_slow = self:GetAbility():GetSpecialValueFor("movement_slow")
  if IsServer() then
    -- Slow is reduced with Status Resistance
    self.slow = parent:GetValueChangedByStatusResistance(movement_slow)
  else
    self.slow = movement_slow
  end
end

function modifier_sohei_momentum_strike_slow:OnRefresh()
  local parent = self:GetParent()
  local movement_slow = self:GetAbility():GetSpecialValueFor("movement_slow")
  if IsServer() then
    -- Slow is reduced with Status Resistance
    self.slow = parent:GetValueChangedByStatusResistance(movement_slow)
  else
    self.slow = movement_slow
  end
end

function modifier_sohei_momentum_strike_slow:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
  }
end

function modifier_sohei_momentum_strike_slow:GetModifierMoveSpeedBonus_Percentage()
  return self.slow
end

---------------------------------------------------------------------------------------------------

-- Stun debuff
modifier_sohei_momentum_strike_stun = class(ModifierBaseClass)

function modifier_sohei_momentum_strike_stun:IsHidden()
  return false
end

function modifier_sohei_momentum_strike_stun:IsDebuff()
  return true
end

function modifier_sohei_momentum_strike_stun:IsStunDebuff()
  return true
end

function modifier_sohei_momentum_strike_stun:IsPurgable()
  return true
end

function modifier_sohei_momentum_strike_stun:GetEffectName()
  return "particles/generic_gameplay/generic_stunned.vpcf"
end

function modifier_sohei_momentum_strike_stun:GetEffectAttachType()
  return PATTACH_OVERHEAD_FOLLOW
end

function modifier_sohei_momentum_strike_stun:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_OVERRIDE_ANIMATION,
  }
end

function modifier_sohei_momentum_strike_stun:GetOverrideAnimation()
  return ACT_DOTA_DISABLED
end

function modifier_sohei_momentum_strike_stun:CheckState()
  return {
    [MODIFIER_STATE_STUNNED] = true,
  }
end
