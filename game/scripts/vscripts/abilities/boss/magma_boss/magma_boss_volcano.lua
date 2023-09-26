LinkLuaModifier("modifier_magma_boss_volcano", "abilities/boss/magma_boss/magma_boss_volcano.lua", LUA_MODIFIER_MOTION_VERTICAL) --knockup from torrent
LinkLuaModifier("modifier_magma_boss_volcano_thinker", "abilities/boss/magma_boss/magma_boss_volcano.lua", LUA_MODIFIER_MOTION_NONE) --applied to volcano units to create magma pools
LinkLuaModifier("modifier_magma_boss_volcano_thinker_child", "abilities/boss/magma_boss/magma_boss_volcano.lua", LUA_MODIFIER_MOTION_NONE) --applied to volcano units to make them invulnerable and pop in
LinkLuaModifier("modifier_magma_boss_volcano_burning_effect", "abilities/boss/magma_boss/magma_boss_volcano.lua", LUA_MODIFIER_MOTION_NONE) --particles-only modifier for standing in magma

magma_boss_volcano = class(AbilityBaseClass)

function magma_boss_volcano:Spawn()
  self.volcano_name = "npc_dota_magma_boss_volcano"
  self.modifier_name = "modifier_magma_boss_volcano_thinker"
end

function magma_boss_volcano:Precache(context)
  PrecacheResource("model", "models/heroes/undying/undying_tower.vmdl", context)
  PrecacheResource("particle", "particles/units/heroes/hero_huskar/huskar_burning_spear_debuff.vpcf", context)
  --PrecacheResource("particle", "particles/magma_boss/boss_magma_mage_volcano_indicator1.vpcf", context)
  PrecacheResource("particle", "particles/darkmoon_creep_warning.vpcf", context)
  PrecacheResource("particle", "particles/magma_boss/boss_magma_mage_volcano_embers.vpcf", context)
  PrecacheResource("particle", "particles/magma_boss/boss_magma_mage_volcano1.vpcf", context)
  PrecacheResource("particle", "particles/magma_boss/magma_center.vpcf", context)
  PrecacheResource("particle", "particles/magma_boss/magma.vpcf", context)
  PrecacheResource("soundfile", "soundevents/bosses/magma_boss.vsndevts", context)
end

function magma_boss_volcano:OnOwnerDied()
  local caster = self:GetCaster()
  local team = caster:GetTeamNumber()
  self:KillAllVolcanos(team)
end

function magma_boss_volcano:OnSpellStart()
  local caster = self:GetCaster()
  local mainTarget = self:GetCursorPosition()
  local vTargetPositions = {}
  if not mainTarget then
    return
  end

  table.insert(vTargetPositions, mainTarget)

  if self.target_points then
    for _, target in pairs(self.target_points) do
      if target then
        table.insert(vTargetPositions, target)
      end
    end
    self.target_points = nil
  end

  for _, vLoc in ipairs(vTargetPositions) do
    local position = GetGroundPosition(vLoc, nil)
    local hUnit = CreateUnitByName("npc_dota_magma_boss_volcano", position, false, caster, caster, caster:GetTeamNumber())
    hUnit:AddNewModifier(caster, self, "modifier_magma_boss_volcano_thinker", {duration = self:GetSpecialValueFor("totem_duration_max")})
    hUnit:SetModelScale(0.01)
    local nMaxHealth = self:GetSpecialValueFor("totem_health")
    hUnit:SetBaseMaxHealth(nMaxHealth)
    hUnit:SetMaxHealth(nMaxHealth)
    hUnit:SetHealth(nMaxHealth)
    self.volcano_name = hUnit:GetName()
  end
end

--------------------------------------------------------------------------------

function magma_boss_volcano:KillAllVolcanos(team) --kill all volcanos created by this ability's caster
  if IsServer() then
    local volcanos = Entities:FindAllByName(self.volcano_name)
    for _, volcano in pairs(volcanos) do
      if not volcano:IsNull() and volcano:HasModifier(self.modifier_name) and volcano:GetTeamNumber() == team then
        volcano:ForceKillOAA(false)
      end
    end
  end
end

function magma_boss_volcano:FindClosestMagmaPool() --returns the location (Vector) of the closest magma (edge of a magma pool)
  if IsServer() then
    local volcanos = Entities:FindAllByName(self.volcano_name)
    local hClosestVolcano
    local nClosestEdgeDistance = math.huge
    for _, volcano in pairs(volcanos) do
      if volcano:HasModifier(self.modifier_name) and (volcano:GetTeamNumber() == self:GetCaster():GetTeamNumber()) then
        local EdgeDistance = (self:GetOwner():GetOrigin() - volcano:GetOrigin()):Length2D() - volcano:FindModifierByName(self.modifier_name):GetMagmaRadius()
        if EdgeDistance < nClosestEdgeDistance then
          nClosestEdgeDistance = EdgeDistance
          hClosestVolcano = volcano
        end
      end
    end
    local vEdgeLoc
    if hClosestVolcano then
      vEdgeLoc = self:GetOwner():GetAbsOrigin() + (hClosestVolcano:GetAbsOrigin()-self:GetOwner():GetAbsOrigin()):Normalized()*nClosestEdgeDistance
      DebugDrawLine(self:GetOwner():GetOrigin(),vEdgeLoc,0,255,255,true,10)
    end
    return vEdgeLoc
  end
end

function magma_boss_volcano:GetNumVolcanos()
  if IsServer() then
    local volcanos = Entities:FindAllByName(self.volcano_name)
    local NumVolcanos = 0
    if #volcanos > 0 then
      for _, volcano in pairs(volcanos) do
        if volcano then
          local volcano_mod = volcano:FindModifierByNameAndCaster(self.modifier_name, self:GetCaster())
          if volcano_mod then
            NumVolcanos = NumVolcanos + 1
          end
        end
      end
    end
    return NumVolcanos
  end
end

function magma_boss_volcano:FindValidTarget(potential_target, main_target)
  if not IsServer() then
    return
  end

  local caster = self:GetCaster()
  local caster_loc = caster:GetAbsOrigin()

  local nearby = Entities:FindAllByNameWithin(self.volcano_name, potential_target, self:GetSpecialValueFor("magma_radius_max"))
  if #nearby == 0 then
    return potential_target
  end

  local overlapping = {}
  for _, volcano in pairs(nearby) do
    if volcano and not volcano:IsNull() and volcano:HasModifier(self.modifier_name) then
      table.insert(overlapping, volcano)
    end
  end
  if #overlapping == 0 then
    return potential_target
  end

  if main_target and (potential_target - main_target):Length2D() >= self:GetSpecialValueFor("torrent_aoe") and (potential_target - caster_loc):Length2D() <= 1500 then
    return potential_target
  end

  -- Try not to overlap locations, but use the last position attempted if we spend too long in the loop
  local nMaxAttempts = 7
  local nAttempts = 0
  local position = caster_loc

  repeat
    position = potential_target + RandomVector(RandomInt(self:GetSpecialValueFor("torrent_aoe"), 1500))
    nearby = Entities:FindAllByNameWithin(self.volcano_name, position, self:GetSpecialValueFor("magma_radius_max"))
    overlapping = {}
    for _, volcano in pairs(nearby) do
      if volcano and not volcano:IsNull() and volcano:HasModifier(self.modifier_name) then
        table.insert(overlapping, volcano)
      end
    end

    nAttempts = nAttempts + 1
    if nAttempts >= nMaxAttempts then
      -- If extremely unlucky
      if main_target and (position - main_target):Length2D() <= self:GetSpecialValueFor("torrent_aoe") then
        position = main_target + RandomVector(RandomInt(self:GetSpecialValueFor("torrent_aoe"), 1500))
      end
      break
    end
  until (#overlapping == 0 and (position - caster_loc):Length2D() <= 1500)

  return position
end

---------------------------------------------------------------------------------------------------

modifier_magma_boss_volcano = class(ModifierBaseClass)

GRAVITY_DECEL = 800

function modifier_magma_boss_volcano:IsHidden()
  return true
end

function modifier_magma_boss_volcano:IsDebuff()
  return true
end

function modifier_magma_boss_volcano:IsStunDebuff()
  return true
end

function modifier_magma_boss_volcano:IsPurgable()
  return false
end

function modifier_magma_boss_volcano:RemoveOnDeath()
  return true
end

function modifier_magma_boss_volcano:GetEffectName()
  return "particles/generic_gameplay/generic_stunned.vpcf"
end

function modifier_magma_boss_volcano:GetEffectAttachType()
  return PATTACH_OVERHEAD_FOLLOW
end

function modifier_magma_boss_volcano:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_OVERRIDE_ANIMATION,
  }
end

function modifier_magma_boss_volcano:GetOverrideAnimation()
  return ACT_DOTA_FLAIL
end

function modifier_magma_boss_volcano:OnCreated( kv )
  if IsServer() then
    --set speed so that the rise/fall will match the knockup duration
    self.speed = kv.duration*GRAVITY_DECEL/2
    if self:ApplyVerticalMotionController() == false then
      self:Destroy()
    end
  end
end

function modifier_magma_boss_volcano:OnRefresh( kv )
  if IsServer() then
    local parent = self:GetParent()
    parent:RemoveVerticalMotionController(self)
    self.speed = kv.duration*GRAVITY_DECEL/2
    if self:ApplyVerticalMotionController() == false then
      self:Destroy()
    end
  end
end

function modifier_magma_boss_volcano:OnDestroy()
  if IsServer() then
    local parent = self:GetParent()
    parent:RemoveVerticalMotionController(self)
  end
end

function modifier_magma_boss_volcano:UpdateVerticalMotion( me, dt )
  if IsServer() then
    local parent = self:GetParent()
    local iVectLength = self.speed*dt
    self.speed = self.speed - GRAVITY_DECEL*dt
    local vVect = iVectLength*Vector(0,0,1)
    parent:SetOrigin(parent:GetOrigin()+vVect)
  end
end

function modifier_magma_boss_volcano:OnVerticalMotionInterrupted()
  self:Destroy()
end

function modifier_magma_boss_volcano:CheckState()
  return {
    [MODIFIER_STATE_STUNNED] = true
  }
end

---------------------------------------------------------------------------------------------------

modifier_magma_boss_volcano_burning_effect = class(ModifierBaseClass)

function modifier_magma_boss_volcano_burning_effect:IsHidden()
  return true
end

function modifier_magma_boss_volcano_burning_effect:IsDebuff()
  return true
end

function modifier_magma_boss_volcano_burning_effect:IsPurgable()
  return false
end

function modifier_magma_boss_volcano_burning_effect:RemoveOnDeath()
  return true
end

function modifier_magma_boss_volcano_burning_effect:GetEffectName()
  return "particles/units/heroes/hero_huskar/huskar_burning_spear_debuff.vpcf"
end

function modifier_magma_boss_volcano_burning_effect:GetEffectAttachType()
  return PATTACH_ABSORIGIN_FOLLOW
end

---------------------------------------------------------------------------------------------------

modifier_magma_boss_volcano_thinker = class (ModifierBaseClass)

function modifier_magma_boss_volcano_thinker:IsHidden()
  return true
end

function modifier_magma_boss_volcano_thinker:IsDebuff()
  return false
end

function modifier_magma_boss_volcano_thinker:IsPurgable()
  return false
end

function modifier_magma_boss_volcano_thinker:RemoveOnDeath()
  return true
end

function modifier_magma_boss_volcano_thinker:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_DISABLE_HEALING,
    MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_PHYSICAL,
    MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_MAGICAL,
    MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_PURE,
    MODIFIER_EVENT_ON_ATTACK_LANDED,
  }
end

function modifier_magma_boss_volcano_thinker:OnCreated()
  if not IsServer() then
    return
  end

  local parent = self:GetParent()
  local ability = self:GetAbility()
  local center = parent:GetAbsOrigin()

  self.delay = ability:GetSpecialValueFor("torrent_delay")
  self.interval = ability:GetSpecialValueFor("magma_damage_interval")
  self.radius = ability:GetSpecialValueFor("torrent_aoe")
  self.torrent_damage = ability:GetSpecialValueFor("torrent_damage")
  self.stun_duration = ability:GetSpecialValueFor("torrent_stun_duration")
  self.totem_rising_duration = ability:GetSpecialValueFor("totem_rising_duration")
  self.damage_per_second = ability:GetSpecialValueFor("magma_damage_per_second")
  --self.heal_per_second = ability:GetSpecialValueFor("magma_heal_per_second")
  self.aoe_per_second = ability:GetSpecialValueFor("magma_spread_speed")
  self.magma_radius =  ability:GetSpecialValueFor("magma_initial_radius")
  self.max_radius = ability:GetSpecialValueFor("magma_radius_max")

  self.damage_type = ability:GetAbilityDamageType() or DAMAGE_TYPE_MAGICAL

  -- Warning particle
  --self.warning_particle = ParticleManager:CreateParticle("particles/magma_boss/boss_magma_mage_volcano_indicator1.vpcf", PATTACH_WORLDORIGIN, parent)
  --ParticleManager:SetParticleControl(self.warning_particle, 0, center)
  --ParticleManager:SetParticleControl(self.warning_particle, 1, Vector(self.radius, self.delay, 0))
  self.warning_particle = ParticleManager:CreateParticle("particles/darkmoon_creep_warning.vpcf", PATTACH_CUSTOMORIGIN, parent)
  ParticleManager:SetParticleControl(self.warning_particle, 0, center)
  ParticleManager:SetParticleControl(self.warning_particle, 1, Vector(self.radius, self.radius, self.radius))
  ParticleManager:SetParticleControl(self.warning_particle, 15, Vector(255, 26, 26))

  self.ember_particle = ParticleManager:CreateParticle("particles/magma_boss/boss_magma_mage_volcano_embers.vpcf", PATTACH_WORLDORIGIN, parent)
  ParticleManager:SetParticleControl(self.ember_particle, 2, center)

  -- Warning Sound
  EmitSoundOnLocationWithCaster(center, "Magma_Boss.VolcanoAnnounce", self:GetCaster())

  self.bErupted = false
  self:StartIntervalThink(self.delay)
end

function modifier_magma_boss_volcano_thinker:OnDestroy()
  if not IsServer() then
    return
  end

  if self.warning_particle then
    ParticleManager:DestroyParticle(self.warning_particle, true)
    ParticleManager:ReleaseParticleIndex(self.warning_particle)
  end
  if self.ember_particle then
    ParticleManager:DestroyParticle(self.ember_particle, true)
    ParticleManager:ReleaseParticleIndex(self.ember_particle)
  end
  if self.eruption_particle then
    ParticleManager:DestroyParticle(self.eruption_particle, true)
    ParticleManager:ReleaseParticleIndex(self.eruption_particle)
  end
  if self.lava_bits then
    ParticleManager:DestroyParticle(self.lava_bits, true)
    ParticleManager:ReleaseParticleIndex(self.lava_bits)
  end
  if self.volcano_crater then
    ParticleManager:DestroyParticle(self.volcano_crater, false)
    ParticleManager:ReleaseParticleIndex(self.volcano_crater)
  end
  if self.lava_pool_inner then
    ParticleManager:DestroyParticle(self.lava_pool_inner, false)
    ParticleManager:ReleaseParticleIndex(self.lava_pool_inner)
  end
  if self.lava_pool_outer then
    ParticleManager:DestroyParticle(self.lava_pool_outer, false)
    ParticleManager:ReleaseParticleIndex(self.lava_pool_outer)
  end

  -- Instead of UTIL_Remove(self:GetParent())
  local parent = self:GetParent()
  if parent and not parent:IsNull() then
    parent:AddNoDraw()
    parent:ForceKillOAA(false)
  end
end

function modifier_magma_boss_volcano_thinker:OnIntervalThink()
  if not IsServer() then
    return
  end
  local parent = self:GetParent()
  if not parent or parent:IsNull() or not parent:IsAlive() then
    self:StartIntervalThink(-1)
    self:Destroy()
    return
  end
  if self.bErupted == true then
    local aoe_per_interval = self.aoe_per_second*self.interval
    --local heal_per_interval = self.heal_per_second*self.interval
    local damage_per_interval = self.damage_per_second*self.interval

    local ability = self:GetAbility()
    local damage_table = {
      attacker = self:GetCaster(),
      damage = damage_per_interval,
      damage_type = self.damage_type,
      ability = ability,
    }
    local units = FindUnitsInRadius(
      parent:GetTeamNumber(),
      parent:GetAbsOrigin(),
      nil,
      self.magma_radius,
      DOTA_UNIT_TARGET_TEAM_ENEMY,
      bit.bor(DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_BASIC),
      DOTA_UNIT_TARGET_FLAG_NONE,
      FIND_ANY_ORDER,
      false
    )

    for _, unit in pairs(units) do
      if unit and not unit:IsNull() then
        local unit_origin = unit:GetOrigin()
        local ground_origin = GetGroundPosition(unit_origin, unit)
        local unit_z = unit_origin.z
        local ground_z = ground_origin.z
        if not unit:HasFlyMovementCapability() and unit_z - ground_z < 10 and not unit:HasModifier("modifier_magma_boss_volcano") and not unit:IsMagicImmune() and not unit:IsDebuffImmune() then
          -- Damage enemies only if touching the magma on the ground or underground
          -- Visual Effect
          unit:AddNewModifier(damage_table.attacker, ability, "modifier_magma_boss_volcano_burning_effect", {duration = self.interval+0.1})
          -- Damage
          damage_table.victim = unit
          ApplyDamage(damage_table)
        end
      end
    end

    self.magma_radius = math.min(self.magma_radius + math.sqrt(aoe_per_interval/math.pi), self.max_radius)

    -- Remove the eruption particle
    if self.eruption_particle then
      ParticleManager:DestroyParticle(self.eruption_particle, false)
      ParticleManager:ReleaseParticleIndex(self.eruption_particle)
      self.eruption_particle = nil
    end

    -- Magma/Lava particles
    ParticleManager:SetParticleControl(self.lava_bits, 1, Vector(self.magma_radius, 0, 0))

    if self.magma_radius >= self.max_radius / 2 and not self.lava_pool_inner then
      self.lava_pool_inner = ParticleManager:CreateParticle("particles/magma_boss/magma.vpcf", PATTACH_WORLDORIGIN, parent)
      ParticleManager:SetParticleControl(self.lava_pool_inner, 0, parent:GetAbsOrigin())
      ParticleManager:SetParticleControl(self.lava_pool_inner, 4, Vector(self.magma_radius, 0, 0))
      ParticleManager:SetParticleControl(self.lava_pool_inner, 2, Vector(self:GetRemainingTime(), 0, 0))
    end
    if self.magma_radius == self.max_radius and not self.lava_pool_outer then
      self.lava_pool_outer = ParticleManager:CreateParticle("particles/magma_boss/magma.vpcf", PATTACH_WORLDORIGIN, parent)
      ParticleManager:SetParticleControl(self.lava_pool_outer, 0, parent:GetAbsOrigin())
      ParticleManager:SetParticleControl(self.lava_pool_outer, 4, Vector(self.max_radius-50, 0, 0))
      ParticleManager:SetParticleControl(self.lava_pool_outer, 2, Vector(self:GetRemainingTime(), 0, 0))
    end
  else
    self:MagmaErupt()
    self.bErupted = true
    self:StartIntervalThink(self.interval)
  end
end

function modifier_magma_boss_volcano_thinker:CheckState()
  local state = {
    [MODIFIER_STATE_NO_UNIT_COLLISION] = true,
  }
  if self.bErupted == false then
    state[MODIFIER_STATE_NO_HEALTH_BAR] = true
    state[MODIFIER_STATE_UNSELECTABLE] = true
    state[MODIFIER_STATE_INVISIBLE] = true
    state[MODIFIER_STATE_TRUESIGHT_IMMUNE] = true
  end
  return state
end

function modifier_magma_boss_volcano_thinker:MagmaErupt()
  local parent = self:GetParent()
  local caster = self:GetCaster()
  local ability = self:GetAbility()
  local center = parent:GetAbsOrigin()

  -- Remove the indicator
  if self.warning_particle then
    ParticleManager:DestroyParticle(self.warning_particle, false)
    ParticleManager:ReleaseParticleIndex(self.warning_particle)
    self.warning_particle = nil
  end

  -- Eruption particle
  self.eruption_particle = ParticleManager:CreateParticle("particles/magma_boss/boss_magma_mage_volcano1.vpcf", PATTACH_WORLDORIGIN, parent)
  ParticleManager:SetParticleControl(self.eruption_particle, 0, center)
  ParticleManager:SetParticleControl(self.eruption_particle, 1, Vector(self.radius, 0, 0))

  -- Eruption sound
  EmitSoundOnLocationWithCaster(center, "Magma_Boss.VolcanoErupt", caster)

  parent:AddNewModifier(caster, ability, "modifier_magma_boss_volcano_thinker_child", {duration = self.totem_rising_duration})

  local enemies = FindUnitsInRadius(
    parent:GetTeamNumber(),
    center,
    parent,
    self.radius,
    DOTA_UNIT_TARGET_TEAM_ENEMY,
    bit.bor(DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_BASIC),
    DOTA_UNIT_TARGET_FLAG_NONE,
    FIND_ANY_ORDER,
    false
  )

  local damage_table = {
    attacker = caster,
    damage = self.torrent_damage,
    damage_type = self.damage_type,
    ability = ability,
  }

  for _, enemy in pairs(enemies) do
    if enemy and not enemy:IsNull() and not enemy:IsMagicImmune() and not enemy:IsDebuffImmune() then
      -- Apply stun and motion controller
      local actual_duration = enemy:GetValueChangedByStatusResistance(self.stun_duration)
      enemy:AddNewModifier(caster, ability, "modifier_magma_boss_volcano", {duration = actual_duration})

      -- Apply damage
      damage_table.victim = enemy
      ApplyDamage(damage_table)
    end
  end

  -- Magma/Lava bits particle
  self.lava_bits = ParticleManager:CreateParticle("particles/magma_boss/boss_magma_mage_volcano_indicator1.vpcf", PATTACH_WORLDORIGIN, parent)
  ParticleManager:SetParticleControl(self.lava_bits, 0, center)
  ParticleManager:SetParticleControl(self.lava_bits, 1, Vector(self.magma_radius, 0, 0))

  -- Volcano center particle
  self.volcano_crater = ParticleManager:CreateParticle("particles/magma_boss/magma_center.vpcf", PATTACH_WORLDORIGIN, parent)
  ParticleManager:SetParticleControl(self.volcano_crater, 0, center)
  ParticleManager:SetParticleControl(self.volcano_crater, 2, Vector(self:GetRemainingTime(), 0, 0))

  -- Destroy trees
  GridNav:DestroyTreesAroundPoint(center, self.radius, false)
end

if IsServer() then
  function modifier_magma_boss_volcano_thinker:OnAttackLanded(event)
    local parent = self:GetParent()
    local attacker = event.attacker
    local target = event.target

    -- Check if attacker exists
    if not attacker or attacker:IsNull() then
      return
    end

    -- Check if attacked unit exists
    if not target or target:IsNull() then
      return
    end

    -- Check if attacked unit is the parent
    if target ~= parent then
      return
    end

    local ability = self:GetAbility()
    local damage_dealt = 1
    if attacker:IsRealHero() then
      if ability and not ability:IsNull() then
        damage_dealt = math.ceil(ability:GetSpecialValueFor("totem_health") / ability:GetSpecialValueFor("totem_hero_attacks_to_destroy"))
      else
        damage_dealt = 6
      end
    end

    -- To prevent dead staying in memory (preventing SetHealth(0) or SetHealth(-value) )
    if parent:GetHealth() - damage_dealt <= 0 then
      parent:Kill(ability, attacker)
    else
      parent:SetHealth(parent:GetHealth() - damage_dealt)
    end
  end
end

function modifier_magma_boss_volcano_thinker:GetAbsoluteNoDamagePhysical()
  return 1
end

function modifier_magma_boss_volcano_thinker:GetAbsoluteNoDamageMagical()
  return 1
end

function modifier_magma_boss_volcano_thinker:GetAbsoluteNoDamagePure()
  return 1
end

function modifier_magma_boss_volcano_thinker:GetDisableHealing()
  return 1
end

function modifier_magma_boss_volcano_thinker:GetMagmaRadius()
  return self.magma_radius
end

---------------------------------------------------------------------------------------------------

modifier_magma_boss_volcano_thinker_child = class(ModifierBaseClass)

function modifier_magma_boss_volcano_thinker_child:IsHidden()
  return true
end

function modifier_magma_boss_volcano_thinker_child:IsDebuff()
  return false
end

function modifier_magma_boss_volcano_thinker_child:IsPurgable()
  return false
end

function modifier_magma_boss_volcano_thinker_child:RemoveOnDeath()
  return true
end

function modifier_magma_boss_volcano_thinker_child:OnCreated(kv)
  if IsServer() then
    self.duration = kv.duration
    self.end_model_scale = self:GetAbility():GetSpecialValueFor("totem_model_scale")
    self:StartIntervalThink(1/15)
  end
end

function modifier_magma_boss_volcano_thinker_child:OnIntervalThink()
  local scale = self.end_model_scale*(1-self:GetRemainingTime()/self.duration)
  self:GetParent():SetModelScale(scale)
end

function modifier_magma_boss_volcano_thinker_child:CheckState()
  return {
    [MODIFIER_STATE_UNSELECTABLE] = true,
    [MODIFIER_STATE_INVULNERABLE] = true,
    [MODIFIER_STATE_NO_HEALTH_BAR] = true,
  }
end
