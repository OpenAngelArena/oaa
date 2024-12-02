LinkLuaModifier("modifier_eul_tornado_collector_passive", "abilities/eul/eul_tornado_collector.lua", LUA_MODIFIER_MOTION_NONE) -- needs tooltip
LinkLuaModifier("modifier_eul_tornado_passive", "abilities/eul/eul_tornado_collector.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_eul_tornado_hidden", "abilities/eul/eul_tornado_collector.lua", LUA_MODIFIER_MOTION_NONE)

eul_tornado_collector_oaa = class(AbilityBaseClass)

function eul_tornado_collector_oaa:GetIntrinsicModifierName()
  return "modifier_eul_tornado_collector_passive"
end

function eul_tornado_collector_oaa:CastFilterResult()
  local caster = self:GetCaster()
  -- Check for tornados
  local tornados = caster:GetModifierStackCount("modifier_eul_tornado_collector_passive", caster)
  if tornados <= 0 then
    -- Check for Displacement
    local displacement = self:GetSpecialValueFor("displacement") == 1
    if not displacement then
      return UF_FAIL_CUSTOM
    end
  end

  return UF_SUCCESS
end

function eul_tornado_collector_oaa:GetCustomCastError()
  return "#oaa_hud_error_eul_no_tornados" -- No Tornados To Consume
end

function eul_tornado_collector_oaa:GetBehavior()
  -- Check for Displacement
  local displacement = self:GetSpecialValueFor("displacement") == 1
  if displacement then
    return DOTA_ABILITY_BEHAVIOR_NO_TARGET + DOTA_ABILITY_BEHAVIOR_IMMEDIATE + DOTA_ABILITY_BEHAVIOR_ROOT_DISABLES
  end

  return DOTA_ABILITY_BEHAVIOR_NO_TARGET + DOTA_ABILITY_BEHAVIOR_IMMEDIATE
end

function eul_tornado_collector_oaa:GetCooldown(level)
  local cd = self.BaseClass.GetCooldown(self, level)
  -- Check for Displacement
  local displacement = self:GetSpecialValueFor("displacement") == 1
  if displacement then
    return self:GetSpecialValueFor("displacement_cooldown")
  end
end

function eul_tornado_collector_oaa:OnSpellStart()
  local caster = self:GetCaster()

  -- Displacement
  local displacement = self:GetSpecialValueFor("displacement") == 1
  if displacement then
    local displacement_range = self:GetSpecialValueFor("displacement_range")
    local displacement_dmg = self:GetSpecialValueFor("displacement_damage")

    local origin = caster:GetAbsOrigin()
    local destination = origin + RandomVector(displacement_range)

    -- Blink
    FindClearSpaceForUnit(caster, destination, true)

    -- Disjoint disjointable/dodgeable projectiles
    ProjectileManager:ProjectileDodge(caster)

    local enemies = FindUnitsInRadius(
      caster:GetTeamNumber(),
      destination,
      nil,
      displacement_range,
      DOTA_UNIT_TARGET_TEAM_ENEMY,
      DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
      DOTA_UNIT_TARGET_FLAG_NONE,
      FIND_ANY_ORDER,
      false
    )

    local damage_table = {
      attacker = caster,
      damage = displacement_dmg,
      damage_type = self:GetAbilityDamageType(),
      damage_flags = DOTA_DAMAGE_FLAG_NONE,
      ability = self,
    }

    for _, enemy in pairs(enemies) do
      if enemy and not enemy:IsNull() then
        -- Apply damage
        damage_table.victim = enemy
        ApplyDamage(damage_table)
      end
    end
  end

  local summon_mod = caster:FindModifierByName("modifier_eul_tornado_collector_passive")

  local tornados = summon_mod.tornados
  if #tornados <= 0 then
    return
  end

  local first_tornado = tornados[1]
  if not first_tornado or first_tornado:IsNull() then
    return
  end

  local tornado_passive = first_tornado:FindModifierByName("modifier_eul_tornado_passive")
  if not tornado_passive then
    return
  end

  tornado_passive:Destroy()
end

function eul_tornado_collector_oaa:TornadoHeal()
  if not IsServer() then
    return
  end

  local caster = self:GetCaster()

  if not caster:IsAlive() then
    return
  end

  local heal_amount = self:GetSpecialValueFor("heal_per_tornado")

  caster:Heal(heal_amount, self)

  SendOverheadEventMessage(nil, OVERHEAD_ALERT_HEAL, caster, heal_amount, nil)

  --local particle = ParticleManager:CreateParticle("", PATTACH_ABSORIGIN_FOLLOW, caster)
  --ParticleManager:SetParticleControlEnt(particle, 0, caster, PATTACH_ABSORIGIN_FOLLOW, "origin_follow", Vector(0,0,0), false)
  --ParticleManager:ReleaseParticleIndex(particle)

  caster:EmitSound("n_creep_ForestTrollHighPriest.Heal")
end

function eul_tornado_collector_oaa:OnUnStolen()
  local caster = self:GetCaster()
  caster:RemoveModifierByName(self:GetIntrinsicModifierName())
end

---------------------------------------------------------------------------------------------------

modifier_eul_tornado_collector_passive = class(ModifierBaseClass)

function modifier_eul_tornado_collector_passive:IsHidden()
  return false
end

function modifier_eul_tornado_collector_passive:IsDebuff()
  return false
end

function modifier_eul_tornado_collector_passive:IsPurgable()
  return false
end

function modifier_eul_tornado_collector_passive:RemoveOnDeath()
  return false
end

function modifier_eul_tornado_collector_passive:OnCreated()
  self.tornados = {}
  self.pool = {}

  self:OnRefresh()
end

function modifier_eul_tornado_collector_passive:OnRefresh()
  local ability = self:GetAbility()
  if not ability or ability:IsNull() then
    return
  end

  self.interval = ability:GetSpecialValueFor("spawn_interval")

  if IsServer() then
    --self:OnIntervalThink() -- uncomment if you want a tornado to spawn immediately
    self:StartIntervalThink(self.interval)
  end
end

function modifier_eul_tornado_collector_passive:OnIntervalThink()
  self:SpawnTornado()

  if self:GetParent():HasShardOAA() then
    self:OnRefresh()
  end
end

function modifier_eul_tornado_collector_passive:SpawnTornado()
  local parent = self:GetParent()

  -- Stop thinking while dead
  if not parent:IsAlive() then
    self:StartIntervalThink(-1)
    return
  end

  -- Check if affected by break
  if parent:PassivesDisabled() then
    return
  end

  local ability = self:GetAbility()
  if not ability or ability:IsNull() then
    return
  end

  local tornado
  local max_tornados = ability:GetSpecialValueFor("max_tornados")
  local tornado_duration = ability:GetSpecialValueFor("tornado_duration")
  local position = parent:GetAbsOrigin()

  -- check if are at max
  if #self.tornados >= max_tornados then
    -- Heal
    ability:TornadoHeal()
    -- Remove the first tornado temporarily, it will be readded at the end of the table
    tornado = table.remove(self.tornados, 1) -- self.tornados[1]
  else
    -- if less than the max
    -- check if there is one in the pool
    if #self.pool <= 0 then
      -- if there is none then create a completely new one
      tornado = CreateUnitByName("npc_dota_eul_tornado", position, true, parent, parent:GetOwner(), parent:GetTeam())
      tornado:SetOwner(parent)
    else
      -- if there is one in the pool then use that one
      tornado = table.remove(self.pool, 1)
      -- Find the pool modifier and remove it -> this reveals the tornado
      local pool_mod = tornado:FindModifierByName("modifier_eul_tornado_hidden")
      if pool_mod then
        pool_mod:Destroy()
      end
    end

    -- Spawn/Move on top of parent
    FindClearSpaceForUnit(tornado, position, true)
  end

  if tornado then
    -- if we are at max, it will refresh the first tornado duration
    -- otherwise it's setting the duration of the tornado
    tornado:AddNewModifier(parent, ability, "modifier_eul_tornado_passive", {duration = tornado_duration})

    -- Store the tornado into a table
    table.insert(self.tornados, tornado)
  end

  self:SetStackCount(#self.tornados)
end

function modifier_eul_tornado_collector_passive:DeclareFunctions()
  return {
    MODIFIER_EVENT_ON_DEATH,
    MODIFIER_EVENT_ON_RESPAWN
  }
end

if IsServer() then
  function modifier_eul_tornado_collector_passive:OnDeath(event)
    local parent = self:GetParent()
    local killer = event.attacker
    local dead = event.unit

    -- Ignore illusions
    if parent:IsIllusion() then
      return
    end

    -- Spawn a tornado from kills
    if killer == parent then
      -- Spawn only if killer is alive and not affected by break
      if parent:IsAlive() and not parent:PassivesDisabled() then
        self:SpawnTornado()
      end
    end

    -- Pool (hide) all tornados
    if dead == parent then
      for i = 1, #self.tornados do
        local tornado = self.tornados[i]
        tornado:AddNewModifier(parent, self:GetAbility(), "modifier_eul_tornado_hidden", {})
        table.insert(self.pool, tornado)
      end
      self.tornados = {}
      self:SetStackCount(0)
    end
  end

  function modifier_eul_tornado_collector_passive:OnRespawn(event)
    if event.unit ~= self:GetParent() then return end

    -- Start thinking again
    self:StartIntervalThink(self.interval)
  end
end

-- Called when tornado expires, heals the owner and hides it
function modifier_eul_tornado_collector_passive:PoolTornado(tornado)
  local ability = self:GetAbility()
  local found = false -- Heal should work only if expired tornado was an active tornado

  for i = 1, #self.tornados do
    if self.tornados[i] == tornado then

      table.remove(self.tornados, i)

      tornado:AddNewModifier(self:GetCaster(), ability, "modifier_eul_tornado_hidden", {})

      table.insert(self.pool, tornado)

      found = true

      break
    end
  end

  self:SetStackCount(#self.tornados)

  if found then
    ability:TornadoHeal()
  end
end

-- This should not happen in most situations
function modifier_eul_tornado_collector_passive:OnDestroy()
  if not IsServer() then
    return
  end

  -- Destroy the hidden pooled tornados
  for _, tornado in pairs(self.pool) do
    if tornado and not tornado:IsNull() then
      tornado:ForceKillOAA(false)
    end
  end
end

---------------------------------------------------------------------------------------------------

modifier_eul_tornado_hidden = class(ModifierBaseClass)

function modifier_eul_tornado_hidden:IsHidden()
  return true
end

function modifier_eul_tornado_hidden:IsDebuff()
  return false
end

function modifier_eul_tornado_hidden:IsPurgable()
  return false
end

function modifier_eul_tornado_hidden:CheckState()
  return {
    [MODIFIER_STATE_DISARMED] = true,
    [MODIFIER_STATE_ATTACK_IMMUNE] = true,
    [MODIFIER_STATE_INVULNERABLE] = true,
    [MODIFIER_STATE_MAGIC_IMMUNE] = true,
    [MODIFIER_STATE_UNSELECTABLE] = true,
    [MODIFIER_STATE_NO_HEALTH_BAR] = true,
    [MODIFIER_STATE_NO_HEALTH_BAR_FOR_ENEMIES] = true,
    [MODIFIER_STATE_NO_UNIT_COLLISION] = true,
    [MODIFIER_STATE_FLYING_FOR_PATHING_PURPOSES_ONLY] = true,
    [MODIFIER_STATE_UNTARGETABLE] = true,
    [MODIFIER_STATE_NOT_ON_MINIMAP] = true,
    [MODIFIER_STATE_CANNOT_BE_MOTION_CONTROLLED] = true,
    [MODIFIER_STATE_ALLOW_PATHING_THROUGH_CLIFFS] = true,
    [MODIFIER_STATE_ALLOW_PATHING_THROUGH_FISSURE] = true,
    [MODIFIER_STATE_OUT_OF_GAME] = true,
  }
end

function modifier_eul_tornado_hidden:OnCreated()
  if not IsServer() then
    return
  end
  self:GetParent():AddNoDraw()
end

function modifier_eul_tornado_hidden:OnDestroy()
  if not IsServer() then
    return
  end
  self:GetParent():RemoveNoDraw()
end

---------------------------------------------------------------------------------------------------

modifier_eul_tornado_passive = class(ModifierBaseClass)

function modifier_eul_tornado_passive:IsHidden()
  return true
end

function modifier_eul_tornado_passive:IsDebuff()
  return false
end

function modifier_eul_tornado_passive:IsPurgable()
  return false
end

function modifier_eul_tornado_passive:OnCreated()
  if not IsServer() then return end

  self:RandomizeBehavior()

  self.damage_counter = 0
  self.think_interval = 0.2
  self.damage_interval = 1

  self:StartIntervalThink(self.think_interval)
end

function modifier_eul_tornado_passive:CheckState()
  return {
    [MODIFIER_STATE_DISARMED] = true,
    [MODIFIER_STATE_ATTACK_IMMUNE] = true,
    [MODIFIER_STATE_INVULNERABLE] = true,
    [MODIFIER_STATE_MAGIC_IMMUNE] = true,
    [MODIFIER_STATE_UNSELECTABLE] = true,
    [MODIFIER_STATE_NO_HEALTH_BAR] = true,
    [MODIFIER_STATE_NO_HEALTH_BAR_FOR_ENEMIES] = true,
    [MODIFIER_STATE_NO_UNIT_COLLISION] = true,
    [MODIFIER_STATE_FLYING_FOR_PATHING_PURPOSES_ONLY] = true,
    [MODIFIER_STATE_UNTARGETABLE] = true,
    [MODIFIER_STATE_NOT_ON_MINIMAP] = true,
    [MODIFIER_STATE_CANNOT_BE_MOTION_CONTROLLED] = true,
    [MODIFIER_STATE_ALLOW_PATHING_THROUGH_CLIFFS] = true,
    [MODIFIER_STATE_ALLOW_PATHING_THROUGH_FISSURE] = true,
  }
end

function modifier_eul_tornado_passive:RandomizeBehavior()
  local origin = Vector(0, 0, 0)
  local random_angle = QAngle(0, RandomInt(0, 360), 0)
  local length = self:GetAbility():GetSpecialValueFor("wander_radius")
  local end_pos = Vector(length, 0, 0)
  self.local_move_to = RotatePosition(origin, random_angle, end_pos)
  self.wander_counter = 0
end

function modifier_eul_tornado_passive:OnIntervalThink()
  local caster = self:GetCaster()
  local tornado = self:GetParent()
  local ability = self:GetAbility()

  if not tornado or tornado:IsNull() or not ability or ability:IsNull() or not caster or caster:IsNull() then
    return
  end

  -- Check if caster is dead
  if not caster:IsAlive() then
    return
  end

  if self.wander_counter >= 2 then
    self:RandomizeBehavior()
  end

  local caster_pos = caster:GetAbsOrigin()

  tornado:MoveToPosition(caster_pos + self.local_move_to)

  local leash = ability:GetSpecialValueFor("leash_range")
  local diff = caster:GetAbsOrigin() - tornado:GetAbsOrigin()
  local length = diff:Length2D()

  -- Leash the tornados to the caster if caster wanders too far (e.g. blinks)
  if length >= leash then
    FindClearSpaceForUnit(tornado, caster:GetAbsOrigin(), true)
  end

  if self.damage_counter >= self.damage_interval / self.think_interval then
    local radius = ability:GetSpecialValueFor("tornado_damage_radius")
    local dps = ability:GetSpecialValueFor("tornado_dps")

    local enemies = FindUnitsInRadius(
      caster:GetTeamNumber(),
      tornado:GetAbsOrigin(),
      nil,
      radius,
      DOTA_UNIT_TARGET_TEAM_ENEMY,
      DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
      DOTA_UNIT_TARGET_FLAG_NONE,
      FIND_ANY_ORDER,
      false
    )

    local damage_table = {
      attacker = caster,
      damage = dps,
      damage_type = ability:GetAbilityDamageType(),
      damage_flags = DOTA_DAMAGE_FLAG_NONE,
      ability = ability,
    }

    for _, enemy in pairs(enemies) do
      if enemy and not enemy:IsNull() then
        -- Apply damage
        damage_table.victim = enemy
        ApplyDamage(damage_table)
      end
    end

    self.damage_counter = 0
  end

  -- Increase counters
  self.wander_counter = self.wander_counter + 1
  self.damage_counter = self.damage_counter + 1
end

function modifier_eul_tornado_passive:OnDestroy()
  if not IsServer() then
    return
  end

  local caster = self:GetCaster()
  if not caster or caster:IsNull() then
    -- This happens when owner of the tornados does not exist anymore
    -- For example when you change heroes with -switchhero command owning hero gets removed/deleted from the game
    local parent = self:GetParent()
    if not parent or parent:IsNull() then
      return
    end
    -- PoolTornado cannot be called without caster so we hide the tornado manually and destroy it after a delay
    parent:AddNewModifier(parent, self:GetAbility(), "modifier_eul_tornado_hidden", {})
    parent:ForceKillOAA(false)
    return
  end

  local summon_mod = caster:FindModifierByName("modifier_eul_tornado_collector_passive")
  if summon_mod then
    summon_mod:PoolTornado(self:GetParent())
  end
end

function modifier_eul_tornado_passive:GetEffectName()
  return "particles/hero/eul/eul_tornado_ambient.vpcf" --"particles/neutral_fx/tornado_ambient.vpcf"
end

function modifier_eul_tornado_passive:GetEffectAttachType()
  return PATTACH_ABSORIGIN_FOLLOW
end
