sohei_momentum_strike = class( AbilityBaseClass )

LinkLuaModifier("modifier_sohei_momentum_strike_passive", "abilities/sohei/sohei_momentum_strike.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_sohei_momentum_strike_knockback", "abilities/sohei/sohei_momentum_strike.lua", LUA_MODIFIER_MOTION_HORIZONTAL)
LinkLuaModifier("modifier_sohei_momentum_strike_slow", "abilities/sohei/sohei_momentum_strike.lua", LUA_MODIFIER_MOTION_NONE)

---------------------------------------------------------------------------------------------------

function sohei_momentum_strike:GetIntrinsicModifierName()
	return "modifier_sohei_momentum_strike_passive"
end

function sohei_momentum_strike:OnSpellStart()
  local caster = self:GetCaster()
  local point = self:GetCursorPosition()

  -- Projectile parameters
  local projectile_name = "particles/hero/sohei/momentum_strike_projectile.vpcf"
  local projectile_distance = self:GetSpecialValueFor("max_travel_distance")
  local projectile_speed = self:GetSpecialValueFor("projectile_speed")
  local projectile_width = self:GetSpecialValueFor("collision_radius")
  local projectile_vision = self:GetSpecialValueFor("vision_radius")

  -- Projectile direction
  local direction = point - caster:GetAbsOrigin()
  direction.z = 0
  direction = direction:Normalized()

  -- Projectile info
  local info = {
    Source = caster,
    Ability = self,
    EffectName = projectile_name,
    vSpawnOrigin = caster:GetAbsOrigin(),
    fDistance = projectile_distance,
    fStartRadius = projectile_width,
    fEndRadius = projectile_width,
    bHasFrontalCone = false,
    bReplaceExisting = false,
    iUnitTargetTeam = self:GetAbilityTargetTeam(),
    iUnitTargetType = self:GetAbilityTargetType(),
    iUnitTargetFlags = bit.bor(DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, DOTA_UNIT_TARGET_FLAG_NO_INVIS, DOTA_UNIT_TARGET_FLAG_NOT_ATTACK_IMMUNE), --self:GetAbilityTargetFlags(),
    --bDeleteOnHit = true, -- DOESN'T WORK
    vVelocity = direction*projectile_speed,
    bProvidesVision = true,
    iVisionRadius = projectile_vision,
    iVisionTeamNumber = caster:GetTeamNumber(),
  }

  ProjectileManager:CreateLinearProjectile(info)

  -- Play sound
  caster:EmitSound("Sohei.Momentum")

  -- Remove Arcana Glow particle
  local dbzArcana = caster:FindModifierByName('modifier_arcana_dbz')
  local pepsiArcana = caster:FindModifierByName('modifier_arcana_pepsi')
  if dbzArcana then
    ParticleManager:SetParticleControl(dbzArcana.Glow, 2, Vector(0,0,0))
  elseif pepsiArcana then
    ParticleManager:SetParticleControl(pepsiArcana.Glow, 2, Vector(0,0,0))
  end
end

function sohei_momentum_strike:OnProjectileHitHandle(target, location, projectile_id)
  if not target or target:IsNull() or not projectile_id then
    return true
  end

  -- Ignore couriers
  if target:IsCourier() then
    return false
  end

  local caster = self:GetCaster()
  local projectile_velocity = ProjectileManager:GetLinearProjectileVelocity(projectile_id)
  local projectile_speed = self:GetSpecialValueFor("projectile_speed")

  -- Knockback parameters
  local distance = self:GetSpecialValueFor("knockback_distance")
  local speed = self:GetSpecialValueFor("knockback_speed")
  local duration = distance / speed
  local collision_radius = self:GetSpecialValueFor("collision_radius")
  local direction = projectile_velocity/projectile_speed

  -- Apply Momentum Strike Knockback to the target
  target:RemoveModifierByName("modifier_sohei_momentum_strike_knockback")
  target:AddNewModifier(caster, self, "modifier_sohei_momentum_strike_knockback", {
    duration = duration,
    distance = distance,
    speed = speed,
    collision_radius = collision_radius,
    direction_x = direction.x,
    direction_y = direction.y,
  })

  -- Hit particle
  local particleName = "particles/hero/sohei/momentum.vpcf"

  if caster:HasModifier('modifier_arcana_dbz') then
    particleName = "particles/hero/sohei/arcana/dbz/sohei_momentum_strike_dbz.vpcf"
  elseif caster:HasModifier('modifier_arcana_pepsi') then
    particleName = "particles/hero/sohei/arcana/dbz/sohei_momentum_strike_pepsi.vpcf"
  end

  local momentum_pfx = ParticleManager:CreateParticle(particleName, PATTACH_ABSORIGIN_FOLLOW, target)
  ParticleManager:SetParticleControl(momentum_pfx, 0, target:GetAbsOrigin())
  ParticleManager:ReleaseParticleIndex(momentum_pfx)

  -- Hit the unit with normal attack that cant miss
  if not caster:IsDisarmed() and not target:IsAttackImmune() then
    caster:PerformAttack(target, true, true, true, false, false, false, true)
    -- Crit is done with the passive modifier
  end

  return true -- destroys the projectile
end

function sohei_momentum_strike:OnUnStolen()
  local caster = self:GetCaster()
  local modifier = caster:FindModifierByName("modifier_sohei_momentum_strike_passive")
  if modifier then
    caster:RemoveModifierByName("modifier_sohei_momentum_strike_passive")
  end
end

---------------------------------------------------------------------------------------------------

-- Momentum Strike knockback modifier
modifier_sohei_momentum_strike_knockback = class( ModifierBaseClass )

function modifier_sohei_momentum_strike_knockback:IsDebuff()
  return true
end

function modifier_sohei_momentum_strike_knockback:IsHidden()
  return true
end

function modifier_sohei_momentum_strike_knockback:IsPurgable()
  return false
end

function modifier_sohei_momentum_strike_knockback:IsStunDebuff()
  return false
end

function modifier_sohei_momentum_strike_knockback:GetPriority()
  return DOTA_MOTION_CONTROLLER_PRIORITY_HIGHEST--DOTA_MOTION_CONTROLLER_PRIORITY_MEDIUM
end

function modifier_sohei_momentum_strike_knockback:GetEffectName()
  if self:GetCaster():HasModifier('modifier_arcana_dbz') then
    return "particles/hero/sohei/arcana/dbz/sohei_knockback_dbz.vpcf"
  end
  return "particles/hero/sohei/knockback.vpcf"
end

function modifier_sohei_momentum_strike_knockback:GetEffectAttachType()
  return PATTACH_ABSORIGIN_FOLLOW
end

function modifier_sohei_momentum_strike_knockback:CheckState()
  local state = {
    [MODIFIER_STATE_NO_UNIT_COLLISION] = true,
  }

  return state
end

function modifier_sohei_momentum_strike_knockback:DeclareFunctions()
  local funcs = {
    MODIFIER_PROPERTY_OVERRIDE_ANIMATION,
    MODIFIER_PROPERTY_OVERRIDE_ANIMATION_RATE,
  }

  return funcs
end

function modifier_sohei_momentum_strike_knockback:GetOverrideAnimation( event )
  return ACT_DOTA_FLAIL
end

if IsServer() then
  function modifier_sohei_momentum_strike_knockback:OnCreated( event )
    -- Movement parameters
    self.direction = Vector(event.direction_x, event.direction_y, 0)
    self.distance = event.distance + 1
    self.speed = event.speed
    self.collision_radius = event.collision_radius

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
    local thinkers = Entities:FindAllByClassnameWithin("npc_dota_thinker", tickOrigin, self.collision_radius)
    for _, thinker in pairs(thinkers) do
      if thinker and thinker:IsPhantomBlocker() then
        self:SlowAndStun(parent, caster, ability)
        self:Destroy()
        return
      end
    end

    -- Check for high ground
    local previous_loc = GetGroundPosition(parentOrigin, parent)
    local new_loc = GetGroundPosition(tickOrigin, parent)
    if new_loc.z-previous_loc.z > 10 and not GridNav:IsTraversable(tickOrigin) then
      self:SlowAndStun(parent, caster, ability)
      self:Destroy()
      return
    end

    -- Check for trees; GridNav:IsBlocked( tickOrigin ) doesn't give good results; Trees are destroyed on impact;
    if GridNav:IsNearbyTree(tickOrigin, self.collision_radius, false) then
      self:SlowAndStun(parent, caster, ability)
      GridNav:DestroyTreesAroundPoint(tickOrigin, self.collision_radius, false)
      self:Destroy()
      return
    end

    -- Check for buildings (requires buildings lua library, otherwise it will return an error)
    if #FindAllBuildingsInRadius(tickOrigin, self.collision_radius) > 0 or #FindCustomBuildingsInRadius(tickOrigin, self.collision_radius) > 0 then
      self:SlowAndStun(parent, caster, ability)
      self:Destroy()
      return
    end

    -- Check if another enemy hero is on a hero's knockback path, if yes apply debuffs to both heroes
    if parent:IsRealHero() then
      local heroes = FindUnitsInRadius(
        caster:GetTeamNumber(),
        tickOrigin,
        nil,
        self.collision_radius,
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
        self:SlowAndStun(parent, caster, ability)
        self:SlowAndStun(hero_to_impact, caster, ability)
        self:Destroy()
        return
      end
    end

    -- Move the unit to the new location if nothing above was detected;
    -- Unstucking (ResolveNPCPositions) is happening OnDestroy;
    parent:SetOrigin(tickOrigin)
  end

  function modifier_sohei_momentum_strike_knockback:SlowAndStun( unit, caster, ability )
    -- Apply slow debuff
    unit:AddNewModifier(caster, ability, "modifier_sohei_momentum_strike_slow", {duration = ability:GetSpecialValueFor("slow_duration")})

    local stun_duration = ability:GetSpecialValueFor("stun_duration")
    local talent = caster:FindAbilityByName("special_bonus_sohei_stun")

    if talent and talent:GetLevel() > 0 then
      stun_duration = stun_duration + talent:GetSpecialValueFor("value")
    end

    -- Duration is reduced with Status Resistance
    stun_duration = unit:GetValueChangedByStatusResistance(stun_duration)

    -- Apply stun debuff
    unit:AddNewModifier(caster, ability, "modifier_stunned", {duration = stun_duration})

    -- Collision Impact Sound
    unit:EmitSound("Sohei.Momentum.Collision")
  end
end

---------------------------------------------------------------------------------------------------

-- Momentum Strike slow modifier
modifier_sohei_momentum_strike_slow = class( ModifierBaseClass )

function modifier_sohei_momentum_strike_slow:IsDebuff()
  return true
end

function modifier_sohei_momentum_strike_slow:IsHidden()
  return false
end

function modifier_sohei_momentum_strike_slow:IsPurgable()
  return true
end

function modifier_sohei_momentum_strike_slow:IsStunDebuff()
  return false
end

function modifier_sohei_momentum_strike_slow:OnCreated( event )
  local parent = self:GetParent()
  local movement_slow = self:GetAbility():GetSpecialValueFor( "movement_slow" )
  if IsServer() then
    -- Slow is reduced with Status Resistance
    self.slow = parent:GetValueChangedByStatusResistance( movement_slow )
  else
    self.slow = movement_slow
  end
end

function modifier_sohei_momentum_strike_slow:OnRefresh( event )
  local parent = self:GetParent()
  local movement_slow = self:GetAbility():GetSpecialValueFor( "movement_slow" )
  if IsServer() then
    -- Slow is reduced with Status Resistance
    self.slow = parent:GetValueChangedByStatusResistance( movement_slow )
  else
    self.slow = movement_slow
  end
end

function modifier_sohei_momentum_strike_slow:DeclareFunctions()
  local funcs = {
    MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE
  }

  return funcs
end

function modifier_sohei_momentum_strike_slow:GetModifierMoveSpeedBonus_Percentage()
  return self.slow
end

---------------------------------------------------------------------------------------------------

-- Momentum Strike passive modifier
modifier_sohei_momentum_strike_passive = class( ModifierBaseClass )

function modifier_sohei_momentum_strike_passive:IsHidden()
  return true
end

function modifier_sohei_momentum_strike_passive:IsPurgable()
  return false
end

function modifier_sohei_momentum_strike_passive:IsDebuff()
  return false
end

function modifier_sohei_momentum_strike_passive:DeclareFunctions()
  local funcs = {
    MODIFIER_PROPERTY_PREATTACK_CRITICALSTRIKE,
  }

  return funcs
end

function modifier_sohei_momentum_strike_passive:GetModifierPreAttack_CriticalStrike(event)
  local parent = self:GetParent()

  if parent ~= event.attacker then
    return 0
  end

  if not IsServer() then
    return 0
  end

  local ability = self:GetAbility()
  local ufResult = UnitFilter(
    event.target,
    ability:GetAbilityTargetTeam(),
    ability:GetAbilityTargetType(),
    bit.bor(DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, DOTA_UNIT_TARGET_FLAG_NO_INVIS, DOTA_UNIT_TARGET_FLAG_NOT_ATTACK_IMMUNE),
    parent:GetTeamNumber()
  )

  if ufResult ~= UF_SUCCESS then
    return 0
  end

  -- Crit only if the target is affected by Momentum Strike from the parent
  if event.target:FindModifierByNameAndCaster("modifier_sohei_momentum_strike_knockback", parent) then
    return ability:GetSpecialValueFor("crit_damage")
  end

  return 0
end

function modifier_sohei_momentum_strike_passive:OnCreated()
  self:StartIntervalThink(0.1)
end

function modifier_sohei_momentum_strike_passive:OnIntervalThink()
  local ability = self:GetAbility()
  local parent = self:GetParent()

  if not IsServer() then
    return
  end

  -- If Momentum Strike is not on cooldown, make arcana particles glow
  if ability and ability:IsCooldownReady() then
    local dbzArcana = parent:FindModifierByName( 'modifier_arcana_dbz' )
    local pepsiArcana = parent:FindModifierByName( 'modifier_arcana_pepsi' )

    if dbzArcana then
      ParticleManager:SetParticleControl( dbzArcana.Glow, 2, Vector(30,0,0) )
    elseif pepsiArcana then
      ParticleManager:SetParticleControl( pepsiArcana.Glow, 2, Vector(100,0,0) )
    end
  end
end
