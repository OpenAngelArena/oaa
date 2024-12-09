LinkLuaModifier("modifier_eul_typhoon_oaa_thinker", "abilities/eul/eul_typhoon.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_eul_typhoon_oaa_debuff", "abilities/eul/eul_typhoon.lua", LUA_MODIFIER_MOTION_NONE) -- needs tooltip
LinkLuaModifier("modifier_eul_typhoon_oaa_wind_god", "abilities/eul/eul_typhoon.lua", LUA_MODIFIER_MOTION_NONE)

eul_typhoon_oaa = class(AbilityBaseClass)

function eul_typhoon_oaa:GetCastRange(location, target)
  return self:GetSpecialValueFor("radius")
end

function eul_typhoon_oaa:GetAOERadius()
  return self:GetSpecialValueFor("radius")
end

function eul_typhoon_oaa:OnSpellStart()
  local caster = self:GetCaster()
  local cursor = self:GetCursorPosition()
  if not cursor then
    return
  end

  local team = caster:GetTeamNumber()
  local owner = caster:GetOwner()
  local effect_duration = self:GetSpecialValueFor("duration")
  local effect_radius = self:GetSpecialValueFor("radius")

  local positions = {}
  local top = cursor + effect_radius * Vector(0, 1, 0)
  local bottom = cursor + effect_radius * Vector(0, -1, 0)
  local left = cursor + effect_radius * Vector(-1, 0, 0)
  local right = cursor + effect_radius * Vector(1, 0, 0)
  table.insert(positions, top)
  table.insert(positions, bottom)
  table.insert(positions, left)
  table.insert(positions, right)

  -- Create a thinker at the location (used for dmg, vision, particles, sound and as an aura source for slow)
  local thinker = CreateUnitByName("npc_dota_custom_dummy_unit", cursor, false, caster, owner, team)
  thinker:AddNewModifier(caster, self, "modifier_eul_typhoon_oaa_thinker", {duration = effect_duration})
  thinker:AddNewModifier(caster, self, "modifier_kill", {duration = effect_duration})
  thinker:AddNewModifier(caster, self, "modifier_generic_dead_tracker_oaa", {duration = effect_duration + MANUAL_GARBAGE_CLEANING_TIME})

  -- Destroy trees
  GridNav:DestroyTreesAroundPoint(cursor, effect_radius, true)

  -- Create wind gods (used mostly for visual purposes and a little bit of vision)
  for _, pos in pairs(positions) do
    local wg = CreateUnitByName("npc_dota_eul_wildkin", pos, false, caster, owner, team) -- use npc_dota_neutral_wildkin if it becomes buggy again
    wg:AddNewModifier(caster, self, "modifier_eul_typhoon_oaa_wind_god", {duration = effect_duration})
    wg:AddNewModifier(caster, self, 'modifier_kill', {duration = effect_duration})
    wg:AddNewModifier(caster, self, 'modifier_generic_dead_tracker_oaa', {duration = effect_duration + MANUAL_GARBAGE_CLEANING_TIME})
    wg:SetNeverMoveToClearSpace(true)
    wg:SetForwardVector(cursor - pos) -- FaceTowards(cursor) is buggy
    wg:StartGesture(ACT_DOTA_CAST_ABILITY_1) -- this animation relies on move type or something in the kvs, works normally with the wildkin neutral creep
  end

  -- Cast Sound
  thinker:EmitSound("Eul.TyphoonCast")

  -- Check for 'Apply Wind Control To Allies'
  local apply_wind_control = self:GetSpecialValueFor("apply_wind_control") == 1
  if not apply_wind_control then
    return
  end

  local wind_control = caster:FindAbilityByName("eul_wind_shield_oaa")
  if not wind_control then
    return -- sorry Rubick
  end

  -- Check if it's learned
  if wind_control:GetLevel() <= 0 then
    return
  end

  local allies = FindUnitsInRadius(
    team,
    cursor,
    nil,
    effect_radius,
    DOTA_UNIT_TARGET_TEAM_FRIENDLY,
    bit.bor(DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_BASIC),
    DOTA_UNIT_TARGET_FLAG_INVULNERABLE,
    FIND_ANY_ORDER,
    false
  )

  -- Get Wind Control duration
  local wind_control_duration = wind_control:GetSpecialValueFor("active_duration")

  -- Check for Tornado Barrier
  local shield = wind_control:GetSpecialValueFor("all_damage_block") > 0

  -- Check for Ventus Deflect
  local deflect = wind_control:GetSpecialValueFor("attack_projectile_deflect") == 1

  -- Apply the Ventus primary buff to the caster because he is actually deflecting
  -- Applying this buff to every ally is overkill
  if deflect then
    caster:AddNewModifier(caster, wind_control, "modifier_eul_wind_shield_ventus", {duration = wind_control_duration})
  end

  for _, ally in pairs(allies) do
    if ally and not ally:IsNull() then
      ally:AddNewModifier(caster, wind_control, "modifier_eul_wind_shield_active", {duration = wind_control_duration})
      if shield then
        ally:AddNewModifier(caster, wind_control, "modifier_eul_wind_shield_tornado_barrier", {duration = wind_control_duration})
      end
      if deflect then
        ally:AddNewModifier(caster, wind_control, "modifier_eul_wind_shield_ventus_ally", {duration = wind_control_duration})
      end
    end
  end
end

---------------------------------------------------------------------------------------------------

modifier_eul_typhoon_oaa_thinker = class(ModifierBaseClass)

function modifier_eul_typhoon_oaa_thinker:IsHidden()
  return true
end

function modifier_eul_typhoon_oaa_thinker:IsDebuff()
  return false
end

function modifier_eul_typhoon_oaa_thinker:IsPurgable()
  return false
end

function modifier_eul_typhoon_oaa_thinker:IsAura()
  return true
end

function modifier_eul_typhoon_oaa_thinker:GetModifierAura()
  return "modifier_eul_typhoon_oaa_debuff"
end

function modifier_eul_typhoon_oaa_thinker:GetAuraRadius()
  return self.min_effect_radius
end

function modifier_eul_typhoon_oaa_thinker:GetAuraSearchTeam()
  return DOTA_UNIT_TARGET_TEAM_ENEMY
end

function modifier_eul_typhoon_oaa_thinker:GetAuraSearchType()
  return bit.bor(DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_BASIC)
end

function modifier_eul_typhoon_oaa_thinker:GetAuraSearchFlags()
  return DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES
end

function modifier_eul_typhoon_oaa_thinker:OnCreated()
  local ability = self:GetAbility()
  if ability and not ability:IsNull() then
    self.max_dmg = ability:GetSpecialValueFor("max_dps")
    self.min_dmg = ability:GetSpecialValueFor("min_dps")
    self.max_effect_radius = ability:GetSpecialValueFor("max_effect_radius")
    self.min_effect_radius = ability:GetSpecialValueFor("radius")
  end

  if IsServer() then
    self.counter = 0
    self.think_interval = 0.1

    local caster = self:GetCaster()
    local parent_loc = self:GetParent():GetAbsOrigin()

    -- Check for 'Generate Tornados'
    if ability then
      local gen_tornado_interval = ability:GetSpecialValueFor("tornado_generate_interval")
      local tornado_collector = caster:FindAbilityByName("eul_tornado_collector_oaa")
      -- Check if interval is a positive non-zero number and if the caster has Tornado Collector ability
      if gen_tornado_interval > 0 and tornado_collector then
        -- Check if it's learned
        if tornado_collector:GetLevel() >= 1 then
          self.spawn_interval = gen_tornado_interval
        end
      end
    end

    -- Particles
    self.part = ParticleManager:CreateParticle("particles/hero/eul/eul_typhoon.vpcf", PATTACH_WORLDORIGIN, caster)
    ParticleManager:SetParticleControl(self.part, 0, parent_loc)
    ParticleManager:SetParticleControl(self.part, 1, Vector(0, self.min_effect_radius, 0))
    ParticleManager:SetParticleControl(self.part, 3, Vector(0, 90, 0))

    -- self.part2 = ParticleManager:CreateParticle("particles/hero/eul/eul_typhoon_wind.vpcf", PATTACH_WORLDORIGIN, caster)
    -- ParticleManager:SetParticleControl(self.part2, 0, parent_loc)
    -- ParticleManager:SetParticleControl(self.part2, 1, Vector(0, 2*self.max_effect_radius, 0))

    -- self.part3 = ParticleManager:CreateParticle("particles/hero/eul/eul_typhoon_ring_smoke.vpcf", PATTACH_WORLDORIGIN, caster)
    -- ParticleManager:SetParticleControl(self.part3, 0, parent_loc)
    -- ParticleManager:SetParticleControl(self.part3, 1, Vector(0, self.max_effect_radius, 0))

    self:OnIntervalThink()
    self:StartIntervalThink(self.think_interval)
  end
end

function modifier_eul_typhoon_oaa_thinker:OnIntervalThink()
  local caster = self:GetCaster()
  local parent = self:GetParent() -- this is the thinker
  local ability = self:GetAbility()

  if not parent or parent:IsNull() or not caster or caster:IsNull() then
    return
  end

  local parent_loc = parent:GetAbsOrigin() -- thinker center

  -- Destroy trees
  GridNav:DestroyTreesAroundPoint(parent_loc, self.min_effect_radius, true)

  local enemies = FindUnitsInRadius(
    caster:GetTeamNumber(),
    parent_loc,
    nil,
    self.min_effect_radius,
    DOTA_UNIT_TARGET_TEAM_ENEMY,
    DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
    DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES,
    FIND_ANY_ORDER,
    false
  )

  local damage_table = {
    attacker = caster,
    damage_type = DAMAGE_TYPE_MAGICAL,
    damage_flags = DOTA_DAMAGE_FLAG_NONE,
    ability = ability,
  }

  for _, enemy in pairs(enemies) do
    if enemy and not enemy:IsNull() then
      local enemy_loc = enemy:GetAbsOrigin()
      local distance = (enemy_loc - parent_loc):Length2D()
      local dps = self.min_dmg
      if distance <= self.max_effect_radius then
        -- Max dmg
        dps = self.max_dmg
      elseif distance <= self.min_effect_radius then
        dps = (self.max_dmg - self.min_dmg) * (distance - self.min_effect_radius) / (self.max_effect_radius - self.min_effect_radius) + self.min_dmg
      end
      damage_table.damage = dps * self.think_interval
      damage_table.victim = enemy
      ApplyDamage(damage_table)
    end
  end

  -- Check for 'Generate Tornados'
  if self.spawn_interval then
    local tornado_collector = caster:FindAbilityByName("eul_tornado_collector_oaa")
      -- Check if the caster has Tornado Collector ability
      if tornado_collector then
        -- Check if it's learned
        if tornado_collector:GetLevel() >= 1 then
          if self.counter % (self.spawn_interval / self.think_interval) == 0 then
            local summon_mod = caster:FindModifierByName("modifier_eul_tornado_collector_passive")
            if summon_mod then
              summon_mod:SpawnTornado()
            end
          end
        end
      end
  end

  self.counter = self.counter + 1
end

function modifier_eul_typhoon_oaa_thinker:OnDestroy()
  if not IsServer() then
    return
  end
  if self.part then
    ParticleManager:DestroyParticle(self.part, false)
    ParticleManager:ReleaseParticleIndex(self.part)
  end
  if self.part2 then
    ParticleManager:DestroyParticle(self.part2, false)
    ParticleManager:ReleaseParticleIndex(self.part2)
  end
  if self.part3 then
    ParticleManager:DestroyParticle(self.part3, false)
    ParticleManager:ReleaseParticleIndex(self.part3)
  end
  local parent = self:GetParent()
  if parent and not parent:IsNull() then
    parent:AddNoDraw()
  end
end

function modifier_eul_typhoon_oaa_thinker:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_PHYSICAL,
    MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_MAGICAL,
    MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_PURE,
    MODIFIER_PROPERTY_BONUS_DAY_VISION,
    MODIFIER_PROPERTY_BONUS_NIGHT_VISION,
  }
end

function modifier_eul_typhoon_oaa_thinker:GetAbsoluteNoDamagePhysical()
  return 1
end

function modifier_eul_typhoon_oaa_thinker:GetAbsoluteNoDamageMagical()
  return 1
end

function modifier_eul_typhoon_oaa_thinker:GetAbsoluteNoDamagePure()
  return 1
end

function modifier_eul_typhoon_oaa_thinker:GetBonusDayVision()
  return self.min_effect_radius
end

function modifier_eul_typhoon_oaa_thinker:GetBonusNightVision()
  return self.min_effect_radius
end

function modifier_eul_typhoon_oaa_thinker:CheckState()
  return {
    [MODIFIER_STATE_ROOTED] = true,
    [MODIFIER_STATE_ATTACK_IMMUNE] = true,
    [MODIFIER_STATE_MAGIC_IMMUNE] = true,
    --[MODIFIER_STATE_INVULNERABLE] = true,
    [MODIFIER_STATE_UNSELECTABLE] = true,
    [MODIFIER_STATE_NO_HEALTH_BAR] = true,
    [MODIFIER_STATE_NO_UNIT_COLLISION] = true,
    [MODIFIER_STATE_NOT_ON_MINIMAP] = true,
    [MODIFIER_STATE_OUT_OF_GAME] = true,
    [MODIFIER_STATE_NO_TEAM_MOVE_TO] = true,
    [MODIFIER_STATE_NO_TEAM_SELECT] = true,
    [MODIFIER_STATE_COMMAND_RESTRICTED] = true,
    [MODIFIER_STATE_FLYING] = true,
  }
end

---------------------------------------------------------------------------------------------------

modifier_eul_typhoon_oaa_debuff = class(ModifierBaseClass)

function modifier_eul_typhoon_oaa_debuff:IsHidden()
  return false
end

function modifier_eul_typhoon_oaa_debuff:IsDebuff()
  return true
end

function modifier_eul_typhoon_oaa_debuff:IsPurgable()
  return false
end

function modifier_eul_typhoon_oaa_debuff:OnCreated()
  local ability = self:GetAbility()
  if ability and not ability:IsNull() then
    self.max_slow = ability:GetSpecialValueFor("max_move_slow")
    self.min_slow = ability:GetSpecialValueFor("min_move_slow")
    self.max_effect_radius = ability:GetSpecialValueFor("max_effect_radius")
    self.min_effect_radius = ability:GetSpecialValueFor("radius")
  end

  self.think_interval = 0.1

  if IsServer() then
    self:OnIntervalThink()
    self:StartIntervalThink(self.think_interval)
  end
end

function modifier_eul_typhoon_oaa_debuff:OnIntervalThink()
  local caster = self:GetAuraOwner() -- this is the thinker (nil on client?)
  local parent = self:GetParent() -- this is the affected enemy

  if not parent or parent:IsNull() or not caster or caster:IsNull() then
    return
  end

  local parent_loc = parent:GetAbsOrigin() -- location of affected enemy
  local caster_loc = caster:GetAbsOrigin() -- thinker center

  local distance = (parent_loc - caster_loc):Length2D()
  local slow = self.min_slow
  if distance <= self.max_effect_radius then
    -- Max slow
    slow = self.max_slow
  elseif distance <= self.min_effect_radius then
    slow = (self.max_slow - self.min_slow) * (distance - self.min_effect_radius) / (self.max_effect_radius - self.min_effect_radius) + self.min_slow
  end

  self:SetStackCount(0 - slow)
end

function modifier_eul_typhoon_oaa_debuff:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
  }
end

function modifier_eul_typhoon_oaa_debuff:GetModifierMoveSpeedBonus_Percentage()
  return 0 - math.abs(self:GetStackCount())
end

function modifier_eul_typhoon_oaa_debuff:GetEffectName()
  return "particles/units/heroes/hero_windrunner/windrunner_windrun_slow.vpcf"
end

function modifier_eul_typhoon_oaa_debuff:GetEffectAttachType()
  return PATTACH_ABSORIGIN_FOLLOW
end

---------------------------------------------------------------------------------------------------

modifier_eul_typhoon_oaa_wind_god = class(ModifierBaseClass)

function modifier_eul_typhoon_oaa_wind_god:IsHidden()
  return true
end

function modifier_eul_typhoon_oaa_wind_god:IsDebuff()
  return false
end

function modifier_eul_typhoon_oaa_wind_god:IsPurgable()
  return false
end

function modifier_eul_typhoon_oaa_wind_god:RemoveOnDeath()
  return true
end

function modifier_eul_typhoon_oaa_wind_god:CheckState()
  return {
    [MODIFIER_STATE_ROOTED] = true,
    [MODIFIER_STATE_ATTACK_IMMUNE] = true,
    [MODIFIER_STATE_MAGIC_IMMUNE] = true,
    [MODIFIER_STATE_INVULNERABLE] = true,
    [MODIFIER_STATE_UNSELECTABLE] = true,
    [MODIFIER_STATE_NO_HEALTH_BAR] = true,
    [MODIFIER_STATE_NO_UNIT_COLLISION] = true,
    [MODIFIER_STATE_NOT_ON_MINIMAP] = true,
    [MODIFIER_STATE_OUT_OF_GAME] = true,
    [MODIFIER_STATE_FORCED_FLYING_VISION] = true,
    [MODIFIER_STATE_DISARMED] = true,
  }
end

function modifier_eul_typhoon_oaa_wind_god:OnDestroy()
  if not IsServer() then
    return
  end
  local parent = self:GetParent()
  if parent and not parent:IsNull() then
    parent:AddNoDraw()
  end
end
