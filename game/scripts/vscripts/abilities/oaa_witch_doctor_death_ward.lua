witch_doctor_death_ward_oaa = class(AbilityBaseClass)

LinkLuaModifier("modifier_death_ward_oaa", "abilities/oaa_witch_doctor_death_ward.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_death_ward_hidden_oaa", "abilities/oaa_witch_doctor_death_ward.lua", LUA_MODIFIER_MOTION_NONE)

function witch_doctor_death_ward_oaa:IsStealable()
  return true
end

function witch_doctor_death_ward_oaa:OnSpellStart()
  local unit_name = "npc_dota_witch_doctor_death_ward_oaa" -- vanilla death ward unit doesn't work for some reason
  local point = self:GetCursorPosition()

  if not point then
    return
  end

  local caster = self:GetCaster()

  -- Create Death Ward unit
  local death_ward = CreateUnitByName(unit_name, point, true, caster, caster, caster:GetTeamNumber())
  death_ward:SetOwner(caster)
  death_ward:SetControllableByPlayer(caster:GetPlayerOwnerID(), true)

  -- Sound
  death_ward:EmitSound("Hero_WitchDoctor.Death_WardBuild")

  -- Get Death Ward damage (needed if physical and not a spell damage)
  --local damage = self:GetSpecialValueFor("damage")
  -- Set Death Ward damage (needed if physical and not a spell damage)
  --death_ward:SetBaseDamageMax(damage)
  --death_ward:SetBaseDamageMin(damage)

  -- Apply modifiers to Death Ward
  death_ward:AddNewModifier(caster, self, "modifier_death_ward_oaa", {})
  death_ward:AddNewModifier(caster, self, "modifier_phased", {duration = 0.03}) -- unit will insta unstuck after this built-in modifier expires.

  -- Variable needed for later
  self.ward_unit = death_ward
end

function witch_doctor_death_ward_oaa:OnProjectileHit_ExtraData(target, location, data)
  --if not self.ward_unit or self.ward_unit:IsNull() then
    --return
  --end

  -- If target doesn't exist (disjointed), don't continue
  if not target or target:IsNull() then
    return
  end

  -- Get the owner of the Death Ward
  local owner = self:GetCaster() -- self.ward_unit:GetOwner()

  -- If owner doesn't exist, don't continue
  if not owner or owner:IsNull() then
    return
  end

  -- Source of the damage
  local damage_source = owner --self.ward_unit

  -- Damage of the projectile
  local damage = self:GetSpecialValueFor("damage")

  -- Damage table of the projectile
  local damage_table = {
    attacker = damage_source,
    victim = target,
    damage = damage,
    damage_type = self:GetAbilityDamageType(),
    damage_flags = bit.bor(DOTA_DAMAGE_FLAG_REFLECTION, DOTA_DAMAGE_FLAG_NO_SPELL_LIFESTEAL),
    ability = self,
  }

  -- If the owner of the Death Ward has Aghanim Scepter
  if owner:HasScepter() then
    local projectile_speed = 1000
    if self.ward_unit and not self.ward_unit:IsNull() then
      projectile_speed = self.ward_unit:GetProjectileSpeed()
    end

    -- Copy data table into new_data table
    local new_data = {}
    for k, v in pairs(data) do
      new_data[k] = v
    end

    -- Mark the target as hit
    new_data[tostring(target:GetEntityIndex())] = 1

    local bounce_radius = self:GetSpecialValueFor("bounce_radius")
    local targets_flags = bit.bor(DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, DOTA_UNIT_TARGET_FLAG_NOT_ATTACK_IMMUNE, DOTA_UNIT_TARGET_FLAG_NO_INVIS, DOTA_UNIT_TARGET_FLAG_FOW_VISIBLE)
    -- Find nearest target and fire a projectile from it
    local enemies = FindUnitsInRadius(damage_source:GetTeamNumber(), target:GetAbsOrigin(), nil, bounce_radius, self:GetAbilityTargetTeam(), self:GetAbilityTargetType(), targets_flags, FIND_CLOSEST, false)
    for _, enemy in ipairs(enemies) do
      if enemy ~= target and new_data[tostring(enemy:GetEntityIndex())] ~= 1 then
        local projectile_info = {
          Target = enemy,
          Source = target,
          Ability = self,
          EffectName = "particles/units/heroes/hero_witchdoctor/witchdoctor_ward_attack.vpcf",
          bDodgable = true,
          bProvidesVision = false,
          bVisibleToEnemies = true,
          bReplaceExisting = false,
          iMoveSpeed = projectile_speed,
          bIsAttack = false,
          iSourceAttachment = DOTA_PROJECTILE_ATTACHMENT_HITLOCATION,
          ExtraData = new_data,
        }

        ProjectileManager:CreateTrackingProjectile(projectile_info)
        break
      end
    end
  end

  ApplyDamage(damage_table)
end

function witch_doctor_death_ward_oaa:OnUpgrade()
  local caster = self:GetCaster()
  local ability_level = self:GetLevel()
  local shard_ability = caster:FindAbilityByName("witch_doctor_voodoo_switcheroo_oaa")

  -- Check to not enter a level up loop
  if shard_ability and shard_ability:GetLevel() ~= ability_level then
    shard_ability:SetLevel(ability_level)
  end
end

--function witch_doctor_death_ward_oaa:GetCastAnimation()
  --return ACT_DOTA_CAST_ABILITY_4
--end

--function witch_doctor_death_ward_oaa:GetChannelAnimation()
	--return ACT_DOTA_VICTORY
--end

function witch_doctor_death_ward_oaa:OnChannelFinish(interrupted)
  if self.ward_unit and not self.ward_unit:IsNull() then
    self.ward_unit:StopSound("Hero_WitchDoctor.Death_WardBuild")
    self.ward_unit:AddNewModifier(self:GetCaster(), self, "modifier_death_ward_hidden_oaa", {duration = 3})
  end
end

function witch_doctor_death_ward_oaa:ProcsMagicStick()
  return true
end

---------------------------------------------------------------------------------------------------

modifier_death_ward_oaa = class(ModifierBaseClass)

function modifier_death_ward_oaa:IsHidden()
  return true
end

function modifier_death_ward_oaa:IsDebuff()
  return false
end

function modifier_death_ward_oaa:IsPurgable()
  return false
end

function modifier_death_ward_oaa:RemoveOnDeath()
  return true
end

function modifier_death_ward_oaa:OnCreated()
  local parent = self:GetParent()
  self.ward_particle = ParticleManager:CreateParticle("particles/units/heroes/hero_witchdoctor/witchdoctor_ward_skull.vpcf", PATTACH_POINT_FOLLOW, parent)
  ParticleManager:SetParticleControlEnt(self.ward_particle, 0, parent, PATTACH_POINT_FOLLOW, "attach_attack1", parent:GetAbsOrigin(), true)
  ParticleManager:SetParticleControl(self.ward_particle, 2, parent:GetAbsOrigin())

  local ability = self:GetAbility()

  local attack_range_bonus = ability:GetSpecialValueFor("bonus_attack_range")

  self.attack_range_bonus = attack_range_bonus

  if IsServer() then
    -- Change Acquisition range if there is an attack range bonus
    parent:SetAcquisitionRange(parent:GetAcquisitionRange() + attack_range_bonus)

    -- Change Night Vision
    local night_vision = math.max(800, parent:GetAttackRange() + attack_range_bonus)
    parent:SetNightTimeVisionRange(night_vision)

    -- Start attacking AI (which targets are allowed to be attacked)
    self:StartIntervalThink(0)
  end
end

function modifier_death_ward_oaa:OnIntervalThink()
  if not IsServer() then
    return
  end
  local parent = self:GetParent()

  if self:IsInChronosphere() then
    self:StopAttacking(parent) -- Don't allow Death Ward to attack anything while inside Chronosphere
    return
  end

  local target = parent:GetForceAttackTarget()
  local aggro = parent:GetAggroTarget()
  local real_target = parent:GetAttackTarget()

  if target then
    parent:SetForceAttackTarget(nil) -- units with force attack target ignore orders so we remove that
    -- We remove force-to-attack-target but the ward should still have aggro over the target and still attack it in the next loop
    return
  end

  if aggro then
    if aggro:IsConsideredHero() then
      -- If aggro is on the hero-like unit, no need to continue (looking for hero-like units, force changing aggro)
      return
    end
  end

  if real_target and real_target.IsConsideredHero then
    if not real_target:IsConsideredHero() then
      -- If real_target is not the hero-like unit, stop attacking
      self:StopAttacking(parent)
      return
    end
  end

  local ability = self:GetAbility()
  local targets_flags = bit.bor(DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, DOTA_UNIT_TARGET_FLAG_NOT_ATTACK_IMMUNE, DOTA_UNIT_TARGET_FLAG_NO_INVIS, DOTA_UNIT_TARGET_FLAG_FOW_VISIBLE)
  -- Find nearest target and attack it
  local enemies = FindUnitsInRadius(parent:GetTeamNumber(), parent:GetAbsOrigin(), nil, parent:GetAttackRange(), ability:GetAbilityTargetTeam(), ability:GetAbilityTargetType(), targets_flags, FIND_CLOSEST, false)
  if #enemies > 0 then
    parent:SetIdleAcquire(true)
    parent:SetAcquisitionRange(parent:GetAttackRange())
    parent:SetForceAttackTarget(enemies[1])
    parent:SetAggroTarget(enemies[1]) -- neat trick of forcing the aggro on the hero-like unit
  else
    self:StopAttacking(parent)
  end
end

function modifier_death_ward_oaa:OnDestroy()
  if self.ward_particle then
    ParticleManager:DestroyParticle(self.ward_particle, true)
    ParticleManager:ReleaseParticleIndex(self.ward_particle)
    self.ward_particle = nil
  end
end

function modifier_death_ward_oaa:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_PHYSICAL,
    MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_MAGICAL,
    MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_PURE,
    MODIFIER_PROPERTY_ATTACK_RANGE_BONUS,
    MODIFIER_PROPERTY_DISABLE_HEALING,
    MODIFIER_EVENT_ON_ATTACK_START,
    MODIFIER_EVENT_ON_ATTACK_LANDED,
    MODIFIER_EVENT_ON_ORDER,
  }
end

function modifier_death_ward_oaa:GetAbsoluteNoDamagePhysical()
  return 1
end

function modifier_death_ward_oaa:GetAbsoluteNoDamageMagical()
  return 1
end

function modifier_death_ward_oaa:GetAbsoluteNoDamagePure()
  return 1
end

function modifier_death_ward_oaa:GetModifierAttackRangeBonus()
  return self.attack_range_bonus
end

function modifier_death_ward_oaa:GetDisableHealing()
  return 1
end

if IsServer() then
  function modifier_death_ward_oaa:OnAttackStart(event)
    local parent = self:GetParent()
    local ability = self:GetAbility()
    local attacker = event.attacker
    local target = event.target

    -- Check if attacker exists
    if not attacker or attacker:IsNull() then
      return
    end

    -- Check if attacker has this modifier
    if attacker ~= parent then
      return
    end

    -- Check if attacked entity exists
    if not target or target:IsNull() then
      return
    end

    -- Check if attacked entity is an item, rune or something weird
    if target.GetUnitName == nil then
      return
    end

    if not target:IsConsideredHero() or self:IsInChronosphere() then
      return
    end

    -- Attack Sound
    parent:EmitSound("Hero_WitchDoctor_Ward.Attack")

    if IsServer() then
      -- check if ability is null
      if not ability or ability:IsNull() then
        return
      end
      local remainingTargets = ability:GetSpecialValueFor("initial_target_count")

      local targets_flags = bit.bor(DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, DOTA_UNIT_TARGET_FLAG_NOT_ATTACK_IMMUNE, DOTA_UNIT_TARGET_FLAG_NO_INVIS, DOTA_UNIT_TARGET_FLAG_FOW_VISIBLE)

      -- Find closest target and fire a projectile from it
      local enemies = FindUnitsInRadius(parent:GetTeamNumber(), target:GetAbsOrigin(), nil, parent:GetAttackRange(), ability:GetAbilityTargetTeam(), ability:GetAbilityTargetType(), targets_flags, FIND_CLOSEST, false)
      for _, enemy in ipairs(enemies) do
        remainingTargets = remainingTargets - 1
        if remainingTargets < 1 then
          break
        end
        if enemy ~= target then
          local useCastAttackOrb = false
          local processProcs = true
          local skipCooldown = true
          local ignoreInvis = false
          local useProjectile = true -- only ranged units need a projectile
          local fakeAttack = false

          local owner = self:GetCaster()
          local neverMiss = owner and not owner:IsNull() and owner:HasScepter()

          -- fortunately this doesn't then call OnAttackStart
          -- so we don't need to worry about recursion
          attacker:PerformAttack(enemy, useCastAttackOrb, processProcs, skipCooldown, ignoreInvis, useProjectile, fakeAttack, neverMiss)
        end
      end

    end
  end

  function modifier_death_ward_oaa:IsInChronosphere()
    local parent = self:GetParent()
    local chronos = {}
    local thinkers = Entities:FindAllByClassnameWithin("npc_dota_thinker", parent:GetAbsOrigin(), 500)
    for _, thinker in pairs(thinkers) do
      if thinker and thinker:HasModifier("modifier_faceless_void_chronosphere") then
        table.insert(chronos, thinker)
      end
    end

    if #chronos > 0 then
      return true
    end

    return false
  end

  function modifier_death_ward_oaa:StopAttacking(unit)
    unit:SetForceAttackTarget(nil)
    unit:SetIdleAcquire(false)
    unit:SetAcquisitionRange(0)
    unit:Interrupt()
    unit:Stop()
    unit:Hold()
  end

  function modifier_death_ward_oaa:OnAttackLanded(event)
    local parent = self:GetParent()
    local owner = self:GetCaster() --parent:GetOwner()
    local attacker = event.attacker
    local target = event.target

    -- Check if attacker exists
    if not attacker or attacker:IsNull() then
      return
    end

    -- Check if attacker has this modifier
    if attacker ~= parent then
      return
    end

    -- Check if attacked entity exists
    if not target or target:IsNull() then
      return
    end

    -- Don't trigger when attacking items or runes; this also prevents bouncing off items or runes
    if target.GetUnitName == nil then
      return
    end

    if not target:IsConsideredHero() or self:IsInChronosphere() then
      return
    end

    local ability = self:GetAbility()
    if not ability or ability:IsNull() then
      return
    end

    -- Damage of the projectile
    local damage = ability:GetSpecialValueFor("damage")

    local damage_source = owner --parent

    -- Damage table of the projectile
    local damage_table = {
      attacker = damage_source,
      victim = target,
      damage = damage,
      damage_type = ability:GetAbilityDamageType(),
      damage_flags = bit.bor(DOTA_DAMAGE_FLAG_REFLECTION, DOTA_DAMAGE_FLAG_NO_SPELL_LIFESTEAL),
      ability = ability,
    }

    -- Handle Aghanim Scepter bounces
    if owner:HasScepter() then
      -- Initialize data table for the scepter bounce
      local data = {}

      -- Mark the target as hit
      data[tostring(target:GetEntityIndex())] = 1

      local bounce_radius = ability:GetSpecialValueFor("bounce_radius")
      local targets_flags = bit.bor(DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, DOTA_UNIT_TARGET_FLAG_NOT_ATTACK_IMMUNE, DOTA_UNIT_TARGET_FLAG_NO_INVIS, DOTA_UNIT_TARGET_FLAG_FOW_VISIBLE)

      -- Find closest target and fire a projectile from it
      local enemies = FindUnitsInRadius(parent:GetTeamNumber(), target:GetAbsOrigin(), nil, bounce_radius, ability:GetAbilityTargetTeam(), ability:GetAbilityTargetType(), targets_flags, FIND_CLOSEST, false)
      for _, enemy in ipairs(enemies) do
        if enemy ~= target then
          local projectile_info = {
            Target = enemy,
            Source = target,
            Ability = ability,
            EffectName = "particles/units/heroes/hero_witchdoctor/witchdoctor_ward_attack.vpcf",
            bDodgable = true,
            bProvidesVision = false,
            bVisibleToEnemies = true,
            bReplaceExisting = false,
            iMoveSpeed = parent:GetProjectileSpeed(),
            bIsAttack = false,
            iSourceAttachment = DOTA_PROJECTILE_ATTACHMENT_HITLOCATION,--DOTA_PROJECTILE_ATTACHMENT_ATTACK_1,
            ExtraData = data,
          }

          ProjectileManager:CreateTrackingProjectile(projectile_info)
          break
        end
      end
    end

    ApplyDamage(damage_table)
  end

  function modifier_death_ward_oaa:OnOrder(event)
    local parent = self:GetParent()
    local unit = event.unit
    local order = event.order_type

    if unit ~= parent then
      return
    end

    if order == DOTA_UNIT_ORDER_ATTACK_TARGET then
      self:StartIntervalThink(0.2) -- start thinking again
    else
      self:StartIntervalThink(-1) -- stop thinking
      self:StopAttacking(parent) -- stop attacking
    end
  end
end

function modifier_death_ward_oaa:CheckState()
  local state = {
    [MODIFIER_STATE_INVULNERABLE] = true,
    [MODIFIER_STATE_MAGIC_IMMUNE] = true,
    [MODIFIER_STATE_OUT_OF_GAME] = true,
    [MODIFIER_STATE_NO_HEALTH_BAR] = true,
    [MODIFIER_STATE_ATTACK_IMMUNE] = true,
  }

  local owner = self:GetCaster()
  if owner:HasScepter() then
    state[MODIFIER_STATE_CANNOT_MISS] = true
  end

  return state
end

---------------------------------------------------------------------------------------------------

witch_doctor_voodoo_switcheroo_oaa = class(AbilityBaseClass)

LinkLuaModifier("modifier_voodoo_switcheroo_oaa", "abilities/oaa_witch_doctor_death_ward.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_voodoo_switcheroo_ward_oaa", "abilities/oaa_witch_doctor_death_ward.lua", LUA_MODIFIER_MOTION_NONE)

function witch_doctor_voodoo_switcheroo_oaa:OnSpellStart()
  local unit_name = "npc_dota_witch_doctor_death_ward_oaa"
  local caster = self:GetCaster()
  local point = caster:GetAbsOrigin()

  -- Disjoint disjointable/dodgeable projectiles
  ProjectileManager:ProjectileDodge(caster)

  -- Hide the caster
  caster:AddNewModifier(caster, self, "modifier_voodoo_switcheroo_oaa", {duration = self:GetSpecialValueFor("duration")})

  -- Create Death Ward unit
  local death_ward = CreateUnitByName(unit_name, point, true, caster, caster, caster:GetTeamNumber())
  death_ward:SetOwner(caster)
  death_ward:SetControllableByPlayer(caster:GetPlayerOwnerID(), true)

  -- Sound
  death_ward:EmitSound("Hero_WitchDoctor.Death_WardBuild")

  -- Get Death Ward damage (needed if physical and not a spell damage)
  --local damage = self:GetSpecialValueFor("damage")
  -- Set Death Ward damage (needed if physical and not a spell damage)
  --death_ward:SetBaseDamageMax(damage)
  --death_ward:SetBaseDamageMin(damage)

  -- Apply modifiers to Death Ward
  death_ward:AddNewModifier(caster, self, "modifier_death_ward_oaa", {})
  death_ward:AddNewModifier(caster, self, "modifier_phased", {duration = 0.03}) -- unit will insta unstuck after this built-in modifier expires.
  death_ward:AddNewModifier(caster, self, "modifier_voodoo_switcheroo_ward_oaa", {}) -- attack speed penalty for the ward

  -- Variable needed for later
  self.ward_unit = death_ward
end

function witch_doctor_voodoo_switcheroo_oaa:OnProjectileHit_ExtraData(target, location, data)
  --if not self.ward_unit or self.ward_unit:IsNull() then
    --return
  --end

  -- If target doesn't exist (disjointed), don't continue
  if not target or target:IsNull() then
    return
  end

  -- Get the owner of the Death Ward
  local owner = self:GetCaster() -- self.ward_unit:GetOwner()

  -- If owner doesn't exist, don't continue
  if not owner or owner:IsNull() then
    return
  end

  -- Source of the damage
  local damage_source = owner --self.ward_unit

  -- Damage of the projectile
  local damage = self:GetSpecialValueFor("damage")

  -- Damage table of the projectile
  local damage_table = {
    attacker = damage_source,
    victim = target,
    damage = damage,
    damage_type = self:GetAbilityDamageType(),
    damage_flags = bit.bor(DOTA_DAMAGE_FLAG_REFLECTION, DOTA_DAMAGE_FLAG_NO_SPELL_LIFESTEAL),
    ability = self
  }

  -- If the owner of the Death Ward has Aghanim Scepter
  if owner:HasScepter() then
    local projectile_speed = 1000
    if self.ward_unit and not self.ward_unit:IsNull() then
      projectile_speed = self.ward_unit:GetProjectileSpeed()
    end

    -- Copy data table into new_data table
    local new_data = {}
    for k, v in pairs(data) do
      new_data[k] = v
    end

    -- Mark the target as hit
    new_data[tostring(target:GetEntityIndex())] = 1

    local bounce_radius = self:GetSpecialValueFor("bounce_radius")
    local targets_flags = bit.bor(DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, DOTA_UNIT_TARGET_FLAG_NOT_ATTACK_IMMUNE, DOTA_UNIT_TARGET_FLAG_NO_INVIS, DOTA_UNIT_TARGET_FLAG_FOW_VISIBLE)
    -- Find nearest target and fire a projectile from it
    local enemies = FindUnitsInRadius(damage_source:GetTeamNumber(), target:GetAbsOrigin(), nil, bounce_radius, self:GetAbilityTargetTeam(), self:GetAbilityTargetType(), targets_flags, FIND_CLOSEST, false)
    for _, enemy in ipairs(enemies) do
      if enemy ~= target and new_data[tostring(enemy:GetEntityIndex())] ~= 1 then
        local projectile_info = {
          Target = enemy,
          Source = target,
          Ability = self,
          EffectName = "particles/units/heroes/hero_witchdoctor/witchdoctor_ward_attack.vpcf",
          bDodgable = true,
          bProvidesVision = false,
          bVisibleToEnemies = true,
          bReplaceExisting = false,
          iMoveSpeed = projectile_speed,
          bIsAttack = false,
          iSourceAttachment = DOTA_PROJECTILE_ATTACHMENT_HITLOCATION,
          ExtraData = new_data,
        }

        ProjectileManager:CreateTrackingProjectile(projectile_info)
        break
      end
    end
  end

  ApplyDamage(damage_table)
end

function witch_doctor_voodoo_switcheroo_oaa:OnHeroCalculateStatBonus()
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

function witch_doctor_voodoo_switcheroo_oaa:IsStealable()
  return true
end

function witch_doctor_voodoo_switcheroo_oaa:ProcsMagicStick()
  return true
end

---------------------------------------------------------------------------------------------------

modifier_voodoo_switcheroo_oaa = class(ModifierBaseClass)

function modifier_voodoo_switcheroo_oaa:IsHidden()
  return true
end

function modifier_voodoo_switcheroo_oaa:IsDebuff()
  return false
end

function modifier_voodoo_switcheroo_oaa:IsPurgable()
  return false
end

if IsServer() then
  function modifier_voodoo_switcheroo_oaa:OnCreated()
    local parent = self:GetParent()
    -- Hide the parent visually
    parent:AddNoDraw()
  end

  function modifier_voodoo_switcheroo_oaa:OnDestroy()
    local parent = self:GetParent()

    -- Unhide the parent visually
    parent:RemoveNoDraw()

    -- Remove the ward
    local ability = self:GetAbility()
    if ability.ward_unit and not ability.ward_unit:IsNull() then
      ability.ward_unit:StopSound("Hero_WitchDoctor.Death_WardBuild")
      ability.ward_unit:AddNewModifier(parent, ability, "modifier_death_ward_hidden_oaa", {duration = 3})
    end
  end
end

function modifier_voodoo_switcheroo_oaa:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_PHYSICAL,
    MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_MAGICAL,
    MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_PURE,
  }
end

function modifier_voodoo_switcheroo_oaa:GetAbsoluteNoDamagePhysical()
  return 1
end

function modifier_voodoo_switcheroo_oaa:GetAbsoluteNoDamageMagical()
  return 1
end

function modifier_voodoo_switcheroo_oaa:GetAbsoluteNoDamagePure()
  return 1
end

function modifier_voodoo_switcheroo_oaa:CheckState()
  return {
    [MODIFIER_STATE_INVULNERABLE] = true,
    [MODIFIER_STATE_MAGIC_IMMUNE] = true,
    [MODIFIER_STATE_OUT_OF_GAME] = true,
    [MODIFIER_STATE_NO_HEALTH_BAR] = true,
    [MODIFIER_STATE_ATTACK_IMMUNE] = true,
    [MODIFIER_STATE_COMMAND_RESTRICTED] = true,
    [MODIFIER_STATE_UNSELECTABLE] = true,
    [MODIFIER_STATE_DISARMED] = true,
  }
end

---------------------------------------------------------------------------------------------------

modifier_death_ward_hidden_oaa = class(ModifierBaseClass)

function modifier_death_ward_hidden_oaa:IsDebuff()
  return false
end

function modifier_death_ward_hidden_oaa:IsHidden()
  return true
end

function modifier_death_ward_hidden_oaa:IsPurgable()
  return false
end

if IsServer() then
  function modifier_death_ward_hidden_oaa:OnCreated()
    local parent = self:GetParent()
    -- Hide the parent visually
    parent:AddNoDraw()
  end

  function modifier_death_ward_hidden_oaa:OnDestroy()
    local parent = self:GetParent()
    -- Kill the ward if it still exists
    if parent and not parent:IsNull() then
      parent:ForceKillOAA(false)
    end
  end
end

function modifier_death_ward_hidden_oaa:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_PHYSICAL,
    MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_MAGICAL,
    MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_PURE,
  }
end

function modifier_death_ward_hidden_oaa:GetAbsoluteNoDamagePhysical()
  return 1
end

function modifier_death_ward_hidden_oaa:GetAbsoluteNoDamageMagical()
  return 1
end

function modifier_death_ward_hidden_oaa:GetAbsoluteNoDamagePure()
  return 1
end

function modifier_death_ward_hidden_oaa:CheckState()
  return {
    [MODIFIER_STATE_INVULNERABLE] = true,
    [MODIFIER_STATE_MAGIC_IMMUNE] = true,
    [MODIFIER_STATE_OUT_OF_GAME] = true,
    [MODIFIER_STATE_NO_HEALTH_BAR] = true,
    [MODIFIER_STATE_ATTACK_IMMUNE] = true,
    [MODIFIER_STATE_COMMAND_RESTRICTED] = true,
    [MODIFIER_STATE_DISARMED] = true,
  }
end

---------------------------------------------------------------------------------------------------

modifier_voodoo_switcheroo_ward_oaa = class(ModifierBaseClass)

function modifier_voodoo_switcheroo_ward_oaa:IsHidden()
  return true
end

function modifier_voodoo_switcheroo_ward_oaa:IsDebuff()
  return false
end

function modifier_voodoo_switcheroo_ward_oaa:IsPurgable()
  return false
end

function modifier_voodoo_switcheroo_ward_oaa:OnCreated()
  local ability = self:GetAbility()
  if ability and not ability:IsNull() then
    self.attack_speed = ability:GetSpecialValueFor("ward_attack_speed_penalty")
  end
end

function modifier_voodoo_switcheroo_ward_oaa:OnRefresh()
  local ability = self:GetAbility()
  if ability and not ability:IsNull() then
    self.attack_speed = ability:GetSpecialValueFor("ward_attack_speed_penalty")
  end
end

function modifier_voodoo_switcheroo_ward_oaa:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
  }
end

function modifier_voodoo_switcheroo_ward_oaa:GetModifierAttackSpeedBonus_Constant()
  return self.attack_speed or self:GetAbility():GetSpecialValueFor("ward_attack_speed_penalty")
end
