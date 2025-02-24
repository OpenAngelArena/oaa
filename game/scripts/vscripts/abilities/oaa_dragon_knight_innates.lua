dragon_knight_innates_oaa = class(AbilityBaseClass)

--LinkLuaModifier( "modifier_dragon_knight_frostbite_debuff_oaa", "abilities/oaa_elder_dragon_form.lua", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_dragon_knight_custom_effects_oaa", "abilities/oaa_dragon_knight_innates.lua", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_dragon_knight_custom_shard_thinker_oaa", "abilities/oaa_dragon_knight_innates.lua", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_dragon_knight_custom_shard_effect_oaa", "abilities/oaa_dragon_knight_innates.lua", LUA_MODIFIER_MOTION_NONE )

function dragon_knight_innates_oaa:Spawn()
  if IsServer() then
    local caster = self:GetCaster()
    if not caster:HasModifier("modifier_dragon_knight_custom_effects_oaa") then
      caster:AddNewModifier(caster, self, "modifier_dragon_knight_custom_effects_oaa", {})
    end
  end
end

---------------------------------------------------------------------------------------------------

modifier_dragon_knight_custom_effects_oaa = class(ModifierBaseClass)

function modifier_dragon_knight_custom_effects_oaa:IsHidden()
  return true
end

function modifier_dragon_knight_custom_effects_oaa:IsDebuff()
  return false
end

function modifier_dragon_knight_custom_effects_oaa:IsPurgable()
  return false
end

function modifier_dragon_knight_custom_effects_oaa:RemoveOnDeath()
  return false
end

function modifier_dragon_knight_custom_effects_oaa:DeclareFunctions()
  return {
    MODIFIER_EVENT_ON_MODIFIER_ADDED,
    --MODIFIER_EVENT_ON_ABILITY_EXECUTED,
  }
end

if IsServer() then
  function modifier_dragon_knight_custom_effects_oaa:OnModifierAdded(event)
    local parent = self:GetParent()

    -- Check if illusion and for shard
    if parent:IsIllusion() or not parent:HasShardOAA() then
      return
    end

    -- Unit that gained a modifier
    local unit = event.unit

    -- Check if unit exists
    if not unit or unit:IsNull() then
      return
    end

    -- If the unit is not actually a unit but its an entity that can gain modifiers
    if unit.HasModifier == nil then
      return
    end

    -- Actual modifier added
    local mod = event.added_buff
    -- modifier_dragon_knight_fireball is the modifier on thinker
    -- modifier_dragon_knight_fireball_burn is the burn modifier

    -- Frost Breath is being applied with splash and Breath Fire in vanilla dota
    -- caster of the modifier is always the original hero, even if the illusion splashed, Thanks Valve
    -- so we can't use OnModifierAdded in a way we want because of this and because it doesn't trigger on reapply
    -- we also don't want illusions to apply Frostbite debuff

    -- Shard additional effect (add to thinker, adding with burn modifier doesnt work)
    if mod and not mod:IsNull() then
      if mod:GetName() == "modifier_dragon_knight_fireball" then
        unit:AddNewModifier(parent, mod:GetAbility(), "modifier_dragon_knight_custom_shard_thinker_oaa", {duration = mod:GetRemainingTime()})
      end
    end
  end

--[[
  function modifier_dragon_knight_custom_effects_oaa:OnAbilityExecuted(event)
    local parent = self:GetParent()
    local cast_ability = event.ability
    local casting_unit = event.unit

    -- Check if caster of the executed ability exists
    if not casting_unit or casting_unit:IsNull() then
      return
    end

    -- Check if caster has this modifier
    if casting_unit ~= parent then
      return
    end

    -- Check if cast ability exists
    if not cast_ability or cast_ability:IsNull() then
      return
    end

    local ability = self:GetAbility() or parent:FindAbilityByName("dragon_knight_elder_dragon_form_oaa")
    if not ability or ability:IsNull() then
      return
    end

    local level = ability:GetLevel()
    if cast_ability:GetAbilityName() == "dragon_knight_breathe_fire" and (level >= 5 or (level >= 4 and parent:HasScepter())) then
      self.radius = cast_ability:GetSpecialValueFor("start_radius") + cast_ability:GetSpecialValueFor("range") + cast_ability:GetSpecialValueFor("end_radius") + parent:GetCastRangeBonus()
      self.travel_time = self.radius / math.max(cast_ability:GetSpecialValueFor("speed"), 1)
      self.cast_ability = cast_ability

      self:StartIntervalThink(self.travel_time)
    end
  end

  function modifier_dragon_knight_custom_effects_oaa:OnIntervalThink()
    local parent = self:GetParent()
    local enemies = FindUnitsInRadius(
      parent:GetTeamNumber(),
      parent:GetAbsOrigin(),
      nil,
      self.radius,
      self.cast_ability:GetAbilityTargetTeam(),
      self.cast_ability:GetAbilityTargetType(),
      self.cast_ability:GetAbilityTargetFlags(),
      FIND_ANY_ORDER,
      false
    )
    local dragon_form = parent:FindAbilityByName("dragon_knight_elder_dragon_form_oaa")
    for _, enemy in pairs(enemies) do
      if enemy and not enemy:IsNull() and enemy:HasModifier("modifier_dragonknight_breathefire_reduction") and enemy:HasModifier("modifier_dragon_knight_frost_breath_slow") then
        -- Apply max level dragon form debuff
        enemy:AddNewModifier(parent, dragon_form, "modifier_dragon_knight_frostbite_debuff_oaa", {duration = dragon_form:GetSpecialValueFor("frost_duration")})
      end
    end

    self:StartIntervalThink(-1)
  end
  ]]
end

---------------------------------------------------------------------------------------------------

modifier_dragon_knight_custom_shard_thinker_oaa = class(ModifierBaseClass)

function modifier_dragon_knight_custom_shard_thinker_oaa:IsHidden()
  return true
end

function modifier_dragon_knight_custom_shard_thinker_oaa:IsDebuff()
  return false
end

function modifier_dragon_knight_custom_shard_thinker_oaa:IsPurgable()
  return false
end

function modifier_dragon_knight_custom_shard_thinker_oaa:OnCreated()
  if IsServer() then
    self:StartIntervalThink(0.1)
  end
end

function modifier_dragon_knight_custom_shard_thinker_oaa:OnIntervalThink()
  if IsServer() then
    local parent = self:GetParent()
    local caster = self:GetCaster()
    if not parent or parent:IsNull() or not caster or caster:IsNull() then
      self:StartIntervalThink(-1)
      self:Destroy()
      return
    end
    local radius = 350
    local linger = 2
    local ability = self:GetAbility()
    if ability and not ability:IsNull() then
      radius = ability:GetSpecialValueFor("radius")
      linger = ability:GetSpecialValueFor("linger_duration")
    end
    local enemies = FindUnitsInRadius(
      parent:GetTeamNumber(),
      parent:GetAbsOrigin(),
      nil,
      radius,
      DOTA_UNIT_TARGET_TEAM_ENEMY,
      DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
      DOTA_UNIT_TARGET_FLAG_NONE,
      FIND_ANY_ORDER,
      false
    )
    for _, enemy in pairs(enemies) do
      if enemy and not enemy:IsNull() then
        enemy:AddNewModifier(caster, ability, "modifier_dragon_knight_custom_shard_effect_oaa", {duration = linger})
      end
    end
  end
end

---------------------------------------------------------------------------------------------------

modifier_dragon_knight_custom_shard_effect_oaa = class(ModifierBaseClass)

function modifier_dragon_knight_custom_shard_effect_oaa:IsHidden()
  return false
end

function modifier_dragon_knight_custom_shard_effect_oaa:IsDebuff()
  return true
end

function modifier_dragon_knight_custom_shard_effect_oaa:IsPurgable()
  return true
end

function modifier_dragon_knight_custom_shard_effect_oaa:OnCreated()
  if not IsServer() then
    return
  end

  self:OnRefresh()
  self:OnIntervalThink()
  self:StartIntervalThink(self.interval)
end

function modifier_dragon_knight_custom_shard_effect_oaa:OnRefresh()
  if not IsServer() then
    return
  end

  local ability = self:GetAbility()
  if ability and not ability:IsNull() then
    self.percent_damage = ability:GetSpecialValueFor("max_hp_damage")
    self.interval = ability:GetSpecialValueFor("burn_interval")
  else
    self.percent_damage = 4
    self.interval = 0.5
  end

  -- Do reduced damage to bosses
  if self:GetParent():IsOAABoss() then
    self.percent_damage = self.percent_damage * (1 - BOSS_DMG_RED_FOR_PCT_SPELLS/100)
  end
end

function modifier_dragon_knight_custom_shard_effect_oaa:OnIntervalThink()
  if not IsServer() then
    return
  end

  local parent = self:GetParent()
  local caster = self:GetCaster()
  local ability = self:GetAbility()

  -- ApplyDamage crashes the game if attacker or victim do not exist
  if not parent or parent:IsNull() or not caster or caster:IsNull() then
    self:StartIntervalThink(-1)
    self:Destroy()
    return
  end

  local dmg_type = DAMAGE_TYPE_MAGICAL
  local dmg_flags = DOTA_DAMAGE_FLAG_NONE
  -- Green Dragon
  if caster:GetHeroFacetID() == 2 then
    dmg_type = DAMAGE_TYPE_PHYSICAL
    dmg_flags = DOTA_DAMAGE_FLAG_BYPASSES_PHYSICAL_BLOCK
  end

  -- Calculate dps
  local damage_per_second = self.percent_damage * parent:GetMaxHealth() * 0.01

  local damage_table = {
    victim = parent,
    attacker = caster,
    damage = damage_per_second * self.interval,
    damage_type = dmg_type,
    damage_flags = dmg_flags,
    ability = ability,
  }

  ApplyDamage(damage_table)
end

if IsServer() then
  function modifier_dragon_knight_custom_shard_effect_oaa:CheckState()
    local parent = self:GetParent()
    local caster = self:GetCaster()

    if not caster or caster:IsNull() or parent:HasModifier("modifier_slark_shadow_dance") or parent:HasModifier("modifier_slark_depth_shroud") then
      return {}
    end

    return {
      [MODIFIER_STATE_INVISIBLE] = false
    }
  end
end

function modifier_dragon_knight_custom_shard_effect_oaa:GetPriority()
  return MODIFIER_PRIORITY_SUPER_ULTRA
end

