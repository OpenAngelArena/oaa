LinkLuaModifier("modifier_eul_innate_oaa", "abilities/eul/eul_innate.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_eul_hurricane_oaa", "abilities/eul/eul_innate.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_eul_innate_oaa_dead_tornado", "abilities/eul/eul_innate.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_eul_innate_oaa_dead_tornado_debuff", "abilities/eul/eul_innate.lua", LUA_MODIFIER_MOTION_NONE)

eul_innate_oaa = class(AbilityBaseClass)

function eul_innate_oaa:GetIntrinsicModifierName()
  return "modifier_eul_innate_oaa"
end

---------------------------------------------------------------------------------------------------
modifier_eul_innate_oaa = class(ModifierBaseClass)

function modifier_eul_innate_oaa:IsHidden()
  return true
end

function modifier_eul_innate_oaa:IsDebuff()
  return false
end

function modifier_eul_innate_oaa:IsPurgable()
  return false
end

function modifier_eul_innate_oaa:RemoveOnDeath()
  return false
end

function modifier_eul_innate_oaa:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_BASEATTACK_BONUSDAMAGE,
    MODIFIER_EVENT_ON_ABILITY_FULLY_CAST, -- needed for damage on enemies, spell block and spell reflect
    MODIFIER_EVENT_ON_ABILITY_EXECUTED, -- needed for dispel talent
    MODIFIER_EVENT_ON_DEATH, -- needed for Tornado spawn on death
    MODIFIER_EVENT_ON_RESPAWN, -- needed for reselecting the main hero when it respawns
  }
end

function modifier_eul_innate_oaa:GetModifierBaseAttack_BonusDamage()
  local int_grants_dmg = self:GetAbility():GetSpecialValueFor("attack_dmg_per_int") == 1
  if int_grants_dmg then
    return self:GetParent():GetIntellect(false)
  end
  return 0
end

if IsServer() then
  function modifier_eul_innate_oaa:OnAbilityFullyCast(event)
    local cast_ability = event.ability
    local target = event.target
    local caster = event.unit

    if not cast_ability or cast_ability:IsNull() or not target or target:IsNull() or not caster or caster:IsNull() then
      return
    end

    -- Find Hurricane ability (it can be on the Rubick or Morphling too and they don't have this innate)
    local hurricane = caster:FindAbilityByName("eul_hurricane_oaa")
    if not hurricane then
      return
    end

    -- Check if cast ability is Hurricane
    if cast_ability:GetAbilityName() ~= hurricane:GetAbilityName() then
      return
    end

    -- Check for dispel
    local dispel = cast_ability:GetSpecialValueFor("dispel") == 1

    -- Check if target is on the enemy team
    if target:GetTeamNumber() ~= caster:GetTeamNumber() then
      if not target:TriggerSpellAbsorb(cast_ability) then
        -- Purge enemies before the damage
        if dispel then
          target:Purge(true, false, false, false, false)
        end
        -- Applying the debuff tracker
        target:AddNewModifier(caster, cast_ability, "modifier_eul_hurricane_oaa", {})
      else
        -- Remove the vanilla modifier because vanilla ability isn't blocked - thanks Valve for your consistency
        target:RemoveModifierByNameAndCaster("modifier_enraged_wildkin_hurricane", caster)
      end
    end
  end

  function modifier_eul_innate_oaa:OnAbilityExecuted(event)
    local cast_ability = event.ability
    local target = event.target
    local caster = event.unit

    if not cast_ability or cast_ability:IsNull() or not target or target:IsNull() or not caster or caster:IsNull() then
      return
    end

    -- Find Hurricane ability (it can be on the Rubick or Morphling too and they don't have this innate)
    local hurricane = caster:FindAbilityByName("eul_hurricane_oaa")
    if not hurricane then
      return
    end

    -- Check if cast ability is Hurricane
    if cast_ability:GetAbilityName() ~= hurricane:GetAbilityName() then
      return
    end

    -- Check for dispel
    local dispel = cast_ability:GetSpecialValueFor("dispel") == 1

    -- Check if target is on the enemy team
    if target:GetTeamNumber() == caster:GetTeamNumber() then
      -- Dispel allies
      if dispel then
        target:Purge(false, true, false, false, false)
      end
    end
  end

  function modifier_eul_innate_oaa:OnDeath(event)
    local parent = self:GetParent()
    local killer = event.attacker
    local dead = event.unit

    -- Don't continue if parent is an illusion or affected by break
    if parent:IsIllusion() or parent:PassivesDisabled() then
      return
    end

    -- Don't continue if the killer doesn't exist
    if not killer or killer:IsNull() then
      return
    end

    -- Check if the dead unit has this modifier
    if dead ~= parent then
      return
    end

    local dead_loc = parent:GetAbsOrigin()
    local dead_dmg = parent:GetAverageTrueAttackDamage(parent)
    local dead_ms = parent:GetIdealSpeedNoSlows()
    local dead_id = parent:GetPlayerOwnerID() or parent:GetPlayerID()
    local ability = self:GetAbility()
    local tornado_duration = ability:GetSpecialValueFor("tornado_linger_time")

    local tornado_dmg = dead_dmg * ability:GetSpecialValueFor("attack_damage_as_tornado_damage_pct") * 0.01

    local tornado = CreateUnitByName("npc_dota_eul_tornado", dead_loc, true, parent, parent:GetOwner(), parent:GetTeamNumber())
    FindClearSpaceForUnit(tornado, dead_loc, true)
    tornado:SetControllableByPlayer(dead_id, false)
    tornado:SetOwner(parent)
    tornado:SetBaseDamageMin(tornado_dmg) -- just for visual purposes, tornado can't actually attack
		tornado:SetBaseDamageMax(tornado_dmg) -- just for visual purposes, tornado can't actually attack
    tornado:SetBaseMoveSpeed(dead_ms)
    tornado:AddNewModifier(parent, ability, "modifier_eul_innate_oaa_dead_tornado", {duration = tornado_duration, dps = tornado_dmg})
    tornado:AddNewModifier(parent, ability, "modifier_kill", {duration = tornado_duration})
    tornado:AddNewModifier(parent, ability, "modifier_generic_dead_tracker_oaa", {duration = tornado_duration + MANUAL_GARBAGE_CLEANING_TIME})

    Timers:CreateTimer(1/30, function()
      local player = PlayerResource:GetPlayer(dead_id)
      if player then
        CustomGameEventManager:Send_ServerToPlayer(player, "AddRemoveSelection", {entity_to_add = tornado:GetEntityIndex(), entity_to_remove = parent:GetEntityIndex()})
      end
    end)
  end

  function modifier_eul_innate_oaa:OnRespawn(event)
    local parent = self:GetParent()

    -- Stuff that shoudln't happen if this ability is put on other heroes
    if parent:IsTempestDouble() or parent:IsClone() or parent:IsSpiritBearOAA() then
      return
    end

    if event.unit ~= parent then
      return
    end

    local playerID = parent:GetPlayerOwnerID()
    local player = PlayerResource:GetPlayer(playerID)
    if player then
      CustomGameEventManager:Send_ServerToPlayer(player, "AddRemoveSelection", {entity_to_add = parent:GetEntityIndex()})
    end
  end
end

---------------------------------------------------------------------------------------------------

modifier_eul_hurricane_oaa = class(ModifierBaseClass)

function modifier_eul_hurricane_oaa:IsHidden()
  return true
end

function modifier_eul_hurricane_oaa:IsDebuff()
  return false
end

function modifier_eul_hurricane_oaa:IsPurgable()
  return false
end

function modifier_eul_hurricane_oaa:RemoveOnDeath()
  return true
end

function modifier_eul_hurricane_oaa:OnCreated()
  if IsServer() then
    self:StartIntervalThink(0)
  end
end

function modifier_eul_hurricane_oaa:OnIntervalThink()
  if not IsServer() then
    return
  end

  local parent = self:GetParent()
  local caster = self:GetCaster()
  if not parent or parent:IsNull() or not caster or caster:IsNull() then
    self:StartIntervalThink(-1)
    self:Destroy()
    return
  end

  -- Check if parent is dead
  if not parent:IsAlive() then
    self:StartIntervalThink(-1)
    self:Destroy()
    return
  end

  -- Check if parent still has the vanilla modifier
  if not parent:HasModifier("modifier_enraged_wildkin_hurricane") then
    self:StartIntervalThink(-1)
    self:Destroy()
  end
end

function modifier_eul_hurricane_oaa:OnDestroy()
  if not IsServer() then
    return
  end

  local parent = self:GetParent()
  local ability = self:GetAbility()
  local caster = self:GetCaster()
  if not parent or parent:IsNull() or not caster or caster:IsNull() then
    return
  end

  -- Check if parent is dead
  if not parent:IsAlive() then
    return
  end

  if not ability or ability:IsNull() then
    ability = caster:FindAbilityByName("eul_hurricane_oaa")
    if not ability then
      return -- sorry Rubick and Morphling
    end
  end

  local damage_table = {
    attacker = caster,
    victim = parent,
    damage = ability:GetSpecialValueFor("damage"),
    damage_type = ability:GetAbilityDamageType(),
    ability = ability,
  }

  ApplyDamage(damage_table)

  -- Try to stop sound loops (does not work)
  local sound_name = "n_creep_Wildkin.Tornado"
  caster:StopSound(sound_name)
  StopSoundOn(sound_name, caster)
  if parent and not parent:IsNull() then
    parent:StopSound(sound_name)
    StopSoundOn(sound_name, parent)
  end
end

---------------------------------------------------------------------------------------------------

modifier_eul_innate_oaa_dead_tornado = class(ModifierBaseClass)

function modifier_eul_innate_oaa_dead_tornado:IsHidden()
  return true
end

function modifier_eul_innate_oaa_dead_tornado:IsDebuff()
  return false
end

function modifier_eul_innate_oaa_dead_tornado:IsPurgable()
  return false
end

function modifier_eul_innate_oaa_dead_tornado:IsAura()
  return true
end

function modifier_eul_innate_oaa_dead_tornado:GetModifierAura()
  return "modifier_eul_innate_oaa_dead_tornado_debuff"
end

function modifier_eul_innate_oaa_dead_tornado:GetAuraRadius()
  return self.radius
end

function modifier_eul_innate_oaa_dead_tornado:GetAuraSearchTeam()
  return DOTA_UNIT_TARGET_TEAM_ENEMY
end

function modifier_eul_innate_oaa_dead_tornado:GetAuraSearchType()
  return bit.bor(DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_BASIC)
end

function modifier_eul_innate_oaa_dead_tornado:GetAuraSearchFlags()
  return DOTA_UNIT_TARGET_FLAG_NONE
end

function modifier_eul_innate_oaa_dead_tornado:OnCreated(event)
  if not IsServer() then return end
  local ability = self:GetAbility()
  self.damage_interval = ability:GetSpecialValueFor("damage_interval")
  self.radius = ability:GetSpecialValueFor("tornado_radius")
  self.dps = event.dps
  self:StartIntervalThink(self.damage_interval)
end

function modifier_eul_innate_oaa_dead_tornado:OnIntervalThink()
  local tornado = self:GetParent()
  local ability = self:GetAbility()

  if not tornado or tornado:IsNull() or not ability or ability:IsNull() then
    return
  end

  local enemies = FindUnitsInRadius(
    tornado:GetTeamNumber(),
    tornado:GetAbsOrigin(),
    nil,
    self.radius,
    DOTA_UNIT_TARGET_TEAM_ENEMY,
    DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
    DOTA_UNIT_TARGET_FLAG_NONE,
    FIND_ANY_ORDER,
    false
  )

  local damage_table = {
    attacker = tornado,
    damage = self.dps * self.damage_interval,
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
end

function modifier_eul_innate_oaa_dead_tornado:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_BONUS_DAY_VISION,
    MODIFIER_PROPERTY_BONUS_NIGHT_VISION,
  }
end

function modifier_eul_innate_oaa_dead_tornado:GetBonusDayVision()
  return 300 -- total vision: 600
end

function modifier_eul_innate_oaa_dead_tornado:GetBonusNightVision()
  return 300 -- total vision: 600
end

function modifier_eul_innate_oaa_dead_tornado:CheckState()
  return {
    [MODIFIER_STATE_DISARMED] = true,
    [MODIFIER_STATE_ATTACK_IMMUNE] = true,
    [MODIFIER_STATE_INVULNERABLE] = true,
    [MODIFIER_STATE_MAGIC_IMMUNE] = true,
    [MODIFIER_STATE_NO_HEALTH_BAR] = true,
    [MODIFIER_STATE_NO_UNIT_COLLISION] = true,
    [MODIFIER_STATE_FLYING_FOR_PATHING_PURPOSES_ONLY] = true,
    [MODIFIER_STATE_UNTARGETABLE] = true,
    [MODIFIER_STATE_NOT_ON_MINIMAP] = true,
    [MODIFIER_STATE_CANNOT_BE_MOTION_CONTROLLED] = true,
  }
end

function modifier_eul_innate_oaa_dead_tornado:GetEffectName()
  return "particles/neutral_fx/tornado_ambient.vpcf"
end

function modifier_eul_innate_oaa_dead_tornado:GetEffectAttachType()
  return PATTACH_ABSORIGIN_FOLLOW
end

---------------------------------------------------------------------------------------------------

modifier_eul_innate_oaa_dead_tornado_debuff = class(ModifierBaseClass)

function modifier_eul_innate_oaa_dead_tornado_debuff:IsHidden()
  return false
end

function modifier_eul_innate_oaa_dead_tornado_debuff:IsDebuff()
  return true
end

function modifier_eul_innate_oaa_dead_tornado_debuff:IsPurgable()
  return false
end

function modifier_eul_innate_oaa_dead_tornado_debuff:OnCreated()
  self.move_slow = 0
  self.attack_slow = 0
  local ability = self:GetAbility()
  if ability and not ability:IsNull() then
    self.move_slow = ability:GetSpecialValueFor("movespeed_slow")
    self.attack_slow = ability:GetSpecialValueFor("attackspeed_slow")
  end
end

function modifier_eul_innate_oaa_dead_tornado_debuff:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
    MODIFIER_PROPERTY_ATTACKSPEED_PERCENTAGE,
  }
end

function modifier_eul_innate_oaa_dead_tornado_debuff:GetModifierMoveSpeedBonus_Percentage()
  return 0 - math.abs(self.move_slow)
end

function modifier_eul_innate_oaa_dead_tornado_debuff:GetModifierAttackSpeedPercentage()
  return 0 - math.abs(self.attack_slow)
end

function modifier_eul_innate_oaa_dead_tornado_debuff:GetEffectName()
  return "particles/units/heroes/hero_windrunner/windrunner_windrun_slow.vpcf"
end

function modifier_eul_innate_oaa_dead_tornado_debuff:GetEffectAttachType()
  return PATTACH_ABSORIGIN_FOLLOW
end
