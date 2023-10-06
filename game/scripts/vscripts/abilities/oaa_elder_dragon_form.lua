dragon_knight_elder_dragon_form_oaa = class(AbilityBaseClass)

LinkLuaModifier( "modifier_dragon_knight_elder_dragon_form_oaa", "abilities/oaa_elder_dragon_form.lua", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_dragon_knight_max_level_oaa", "abilities/oaa_elder_dragon_form.lua", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_dragon_knight_frostbite_debuff_oaa", "abilities/oaa_elder_dragon_form.lua", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_dragon_knight_custom_effects_oaa", "abilities/oaa_elder_dragon_form.lua", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_dragon_knight_custom_shard_thinker_oaa", "abilities/oaa_elder_dragon_form.lua", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_dragon_knight_custom_shard_effect_oaa", "abilities/oaa_elder_dragon_form.lua", LUA_MODIFIER_MOTION_NONE )

function dragon_knight_elder_dragon_form_oaa:Spawn()
  if IsServer() then
    local caster = self:GetCaster()
    if not caster:HasModifier("modifier_dragon_knight_custom_effects_oaa") then
      caster:AddNewModifier(caster, self, "modifier_dragon_knight_custom_effects_oaa", {})
    end
  end
end

-- this makes the ability passive when it hits level 5 and caster has scepter
function dragon_knight_elder_dragon_form_oaa:GetBehavior()
  if self:GetLevel() >= 5 and self:GetCaster():HasScepter() then
    return DOTA_ABILITY_BEHAVIOR_PASSIVE
  end

  return self.BaseClass.GetBehavior(self)
end

-- this is meant to accompany the above, removing the mana cost and cooldown
-- from the tooltip when it becomes passive
function dragon_knight_elder_dragon_form_oaa:GetCooldown(level)
  local caster = self:GetCaster() or self:GetOwner()
  if (self:GetLevel() >= 5 or level >= 5) and caster:HasScepter() then
    return 0
  end

  return self.BaseClass.GetCooldown(self, level)
end

function dragon_knight_elder_dragon_form_oaa:GetManaCost(level)
  local caster = self:GetCaster() or self:GetOwner()
  if (self:GetLevel() >= 5 or level >= 5) and caster:HasScepter() then
    return 0
  end

  return self.BaseClass.GetManaCost(self, level)
end

function dragon_knight_elder_dragon_form_oaa:OnSpellStart()
  local caster = self:GetCaster()
  local level = self:GetLevel()
  local duration = self:GetSpecialValueFor("duration")
  local ability = caster:FindAbilityByName("dragon_knight_elder_dragon_form")

  if ability then
    if level >= 4 then
      if caster:HasScepter() then
        ability:SetLevel(3)
      else
        ability:SetLevel(4)
      end
    end
  else
    ability = self
  end

  if level >= 5 and caster:HasScepter() then
    duration = -1
  end

  -- apply the standard dragon form modifier ( for movespeed and the model change )
  caster:AddNewModifier( caster, ability, "modifier_dragon_knight_dragon_form", { duration = duration, } )

  -- apply the corrosive breath modifier, don't need to check its level really
  caster:AddNewModifier( caster, ability, "modifier_dragon_knight_corrosive_breath", { duration = duration, } )

  -- apply the leveled modifiers
  if level >= 2 then
    caster:AddNewModifier( caster, ability, "modifier_dragon_knight_splash_attack", { duration = duration, } )
  end

  if level >= 3 then
    caster:AddNewModifier( caster, ability, "modifier_dragon_knight_frost_breath", { duration = duration, } )
  end

  if level >= 5 or ( level >= 4 and caster:HasScepter() ) then
    caster:AddNewModifier( caster, self, "modifier_dragon_knight_max_level_oaa", { duration = duration, } )
  end

  -- Manage Attack Projectile if there is none (if it's not handled with vanilla modifiers)
  local projectile_name = caster:GetRangedProjectileName()
  if not projectile_name or projectile_name == "" then
    if self:IsStolen() then
      -- For Rubick if he doesn't have a projectile in Dragon Form at least add his base projectile
      caster:SetRangedProjectileName(caster:GetBaseRangedProjectileName())
    else
      caster:ChangeAttackProjectile()
    end
  end
end

function dragon_knight_elder_dragon_form_oaa:GetIntrinsicModifierName()
  if self:GetLevel() >= 5 then
    return "modifier_dragon_knight_elder_dragon_form_oaa"
  end
end

function dragon_knight_elder_dragon_form_oaa:OnUpgrade()
  local caster = self:GetCaster()
  local ability_level = self:GetLevel()

  local vanilla_ability = caster:FindAbilityByName("dragon_knight_elder_dragon_form")
  if not vanilla_ability then
    return
  end

  if ability_level >= 4 then
    if caster:HasScepter() then
      vanilla_ability:SetLevel(3)
    else
      vanilla_ability:SetLevel(4)
    end
    return
  end

  vanilla_ability:SetLevel(ability_level)
end

-- function dragon_knight_elder_dragon_form_oaa:GetAssociatedSecondaryAbilities()
  -- return "dragon_knight_elder_dragon_form"
-- end

-- function dragon_knight_elder_dragon_form_oaa:OnStolen(hSourceAbility)
  -- local caster = self:GetCaster()
  -- local vanilla_ability = caster:FindAbilityByName("dragon_knight_elder_dragon_form")
  -- if not vanilla_ability then
    -- return
  -- end
  -- vanilla_ability:SetHidden(true)
-- end

function dragon_knight_elder_dragon_form_oaa:OnUnStolen()
  local caster = self:GetCaster()
  if caster:HasModifier("modifier_dragon_knight_elder_dragon_form_oaa") then
    caster:RemoveModifierByName("modifier_dragon_knight_elder_dragon_form_oaa")
  end
end

function dragon_knight_elder_dragon_form_oaa:ProcsMagicStick()
  if self:GetLevel() >= 5 and self:GetCaster():HasScepter() then
    return false
  end

  return true
end

---------------------------------------------------------------------------------------------------
-- This modifier handles lvl 5 and scepter equip/unequip edge cases
modifier_dragon_knight_elder_dragon_form_oaa = class(ModifierBaseClass)

function modifier_dragon_knight_elder_dragon_form_oaa:IsHidden()
  return true
end

function modifier_dragon_knight_elder_dragon_form_oaa:IsDebuff()
  return false
end

function modifier_dragon_knight_elder_dragon_form_oaa:IsPurgable()
  return false
end

function modifier_dragon_knight_elder_dragon_form_oaa:RemoveOnDeath()
  return false
end

function modifier_dragon_knight_elder_dragon_form_oaa:OnCreated()
  if not IsServer() then
    return
  end

  self:StartIntervalThink(1)
end

function modifier_dragon_knight_elder_dragon_form_oaa:OnRefresh()
  if not IsServer() then
    return
  end

  self:OnIntervalThink()
end

-- Check periodically if parent has scepter or not if the ability is level 5 or above
function modifier_dragon_knight_elder_dragon_form_oaa:OnIntervalThink()
  if not IsServer() then
    return
  end

  local parent = self:GetParent()

  if not parent or parent:IsNull() then
    return
  end

  if parent:IsIllusion() then
    return
  end

  local ability = self:GetAbility() or parent:FindAbilityByName("dragon_knight_elder_dragon_form_oaa")

  if not ability or ability:IsNull() then
    return
  end

  if ability:GetLevel() >= 5 then
    -- Vanilla Dragon Form modifier
    local modifier = parent:FindModifierByName("modifier_dragon_knight_dragon_form")
    if parent:HasScepter() then
      if not modifier then
        ability:OnSpellStart()
      else
        if modifier:GetDuration() ~= -1 then
          ability:OnSpellStart()
        end
      end
    else
      -- Parent doesn't have scepter -> indirectly check if parent dropped/sold his scepter
      -- by checking if it has dragon form modifiers and by checking modifier durations
      if not modifier then
        -- Modifier doesn't exist and parent doesn't have scepter -> don't do anything
        return
      else
        if modifier:GetDuration() == -1 then
          -- Duration of the modifier is -1 (infinite) but parent doesn't have scepter
          -- Reapply Dragon Form modifiers to give them normal duration
          ability:OnSpellStart()
        end
      end
    end
  end
end

--[[
function modifier_dragon_knight_elder_dragon_form_oaa:DeclareFunctions()
  return {
    MODIFIER_EVENT_ON_ATTACK_LANDED,
  }
end

-- Rage chance - chance to transform into Dragon Form when attack lands, doesn't matter what is the attacked target
if IsServer() then
  function modifier_dragon_knight_elder_dragon_form_oaa:OnAttackLanded(event)
    local parent = self:GetParent()
    local spell = self:GetAbility()
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

    -- no rage while broken
    if parent:PassivesDisabled() then
      return
    end

    if not spell or spell:GetLevel() ~= 4 then
      return
    end

    local chance = spell:GetSpecialValueFor( "rage_chance" ) / 100

    -- we're using the modifier's stack to store the amount of prng failures
    -- this could be something else but since this modifier is hidden anyway ...
    local prngMult = self:GetStackCount() + 1

    -- compared prng to slightly less prng
    if RandomFloat( 0.0, 1.0 ) <= ( PrdCFinder:GetCForP(chance) * prngMult ) then
      -- reset failure count
      self:SetStackCount( 0 )

      local duration = spell:GetSpecialValueFor( "rage_duration" )

      -- check if the ability is already active, and if so, grab the current
      -- duration
      local mod = parent:FindModifierByName( "modifier_dragon_knight_dragon_form" )

      if mod then
        duration = duration + mod:GetRemainingTime()
      end

      local edfMods = {
        "modifier_dragon_knight_dragon_form",
        "modifier_dragon_knight_corrosive_breath",
        "modifier_dragon_knight_splash_attack",
        "modifier_dragon_knight_frost_breath",
      }

      -- apply the edf modifiers with the new duration
      for _, modName in pairs( edfMods ) do
        parent:AddNewModifier( parent, spell, modName, { duration = duration } )
      end
    else
      -- increment failure count
      self:SetStackCount( prngMult )
    end
  end
end
]]

---------------------------------------------------------------------------------------------------

modifier_dragon_knight_max_level_oaa = class(ModifierBaseClass)

function modifier_dragon_knight_max_level_oaa:IsHidden()
  return false
end

function modifier_dragon_knight_max_level_oaa:IsDebuff()
  return false
end

function modifier_dragon_knight_max_level_oaa:IsPurgable()
  return false
end

function modifier_dragon_knight_max_level_oaa:RemoveOnDeath()
  return true
end

function modifier_dragon_knight_max_level_oaa:OnCreated()
  local ability = self:GetAbility()
  local mr_at_4 = ability:GetLevelSpecialValueFor("magic_resistance", 3)
  local mr_at_5 = ability:GetLevelSpecialValueFor("magic_resistance", 4)

  if mr_at_5 > mr_at_4 and mr_at_4 ~= 100 then
    self.bonus_mr = 100 * (mr_at_5 - mr_at_4) / (100 - mr_at_4)
  else
    self.bonus_mr = 0
  end
end

function modifier_dragon_knight_max_level_oaa:OnRefresh()
  self:OnCreated()
end

function modifier_dragon_knight_max_level_oaa:DeclareFunctions()
  return {
    MODIFIER_EVENT_ON_ATTACK_LANDED,
    MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS,
  }
end

function modifier_dragon_knight_max_level_oaa:GetModifierMagicalResistanceBonus()
  return self.bonus_mr
end

if IsServer() then
  function modifier_dragon_knight_max_level_oaa:OnAttackLanded(event)
    local parent = self:GetParent()
    local ability = self:GetAbility()
    local attacker = event.attacker
    local target = event.target

    if parent:IsIllusion() then
      return
    end

    -- Check if attacker exists
    if not attacker or attacker:IsNull() then
      return
    end

    -- Check if attacker has this modifier
    if attacker ~= parent then
      return
    end

    -- Check if attacked unit exists
    if not target or target:IsNull() then
      return
    end

    -- Check for existence of GetUnitName method to determine if target is a unit or an item (or rune)
    -- items don't have that method -> nil; if the target is an item, don't continue
    if target.GetUnitName == nil then
      return
    end

    -- Don't affect buildings, wards, spell-immune units and invulnerable units.
    if target:IsTower() or target:IsBarracks() or target:IsBuilding() or target:IsOther() or target:IsMagicImmune() or target:IsInvulnerable() then
      return
    end

    local duration = ability:GetSpecialValueFor("frost_duration")

    -- Apply the debuff
    target:AddNewModifier(parent, ability, "modifier_dragon_knight_frostbite_debuff_oaa", {duration = duration})
  end
end
---------------------------------------------------------------------------------------------------

modifier_dragon_knight_frostbite_debuff_oaa = class(ModifierBaseClass)

function modifier_dragon_knight_frostbite_debuff_oaa:IsHidden()
  return false
end

function modifier_dragon_knight_frostbite_debuff_oaa:IsDebuff()
  return true
end

function modifier_dragon_knight_frostbite_debuff_oaa:IsPurgable()
  return true
end

function modifier_dragon_knight_frostbite_debuff_oaa:GetEffectName()
  return "particles/items4_fx/spirit_vessel_damage.vpcf"
end

function modifier_dragon_knight_frostbite_debuff_oaa:OnCreated()
  self.heal_suppression_pct = self:GetAbility():GetSpecialValueFor("heal_suppression_pct")
  -- No effect if caster is an illusion
  local caster = self:GetCaster()
  if caster:IsIllusion() then
    self:Destroy()
  end
end

function modifier_dragon_knight_frostbite_debuff_oaa:OnRefresh()
  self.heal_suppression_pct = self:GetAbility():GetSpecialValueFor("heal_suppression_pct")
  -- No effect if caster is an illusion
  local caster = self:GetCaster()
  if caster:IsIllusion() then
    self:Destroy()
  end
end

function modifier_dragon_knight_frostbite_debuff_oaa:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_HEAL_AMPLIFY_PERCENTAGE_TARGET,
    MODIFIER_PROPERTY_HP_REGEN_AMPLIFY_PERCENTAGE,
    MODIFIER_PROPERTY_LIFESTEAL_AMPLIFY_PERCENTAGE,
    MODIFIER_PROPERTY_SPELL_LIFESTEAL_AMPLIFY_PERCENTAGE,
  }
end

function modifier_dragon_knight_frostbite_debuff_oaa:GetModifierHealAmplify_PercentageTarget()
  return -self.heal_suppression_pct
end

function modifier_dragon_knight_frostbite_debuff_oaa:GetModifierHPRegenAmplify_Percentage()
  return -self.heal_suppression_pct
end

function modifier_dragon_knight_frostbite_debuff_oaa:GetModifierLifestealRegenAmplify_Percentage()
  return -self.heal_suppression_pct
end

function modifier_dragon_knight_frostbite_debuff_oaa:GetModifierSpellLifestealRegenAmplify_Percentage()
  return -self.heal_suppression_pct
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
    MODIFIER_EVENT_ON_ABILITY_EXECUTED,
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

    if cast_ability:GetAbilityName() == "dragon_knight_breathe_fire" and parent:HasModifier("modifier_dragon_knight_max_level_oaa") then
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
  if IsServer() then
    self.percent_damage = 4
    self.interval = 0.5
    local ability = self:GetAbility()
    if ability and not ability:IsNull() then
      self.percent_damage = ability:GetSpecialValueFor("max_hp_damage")
      self.interval = ability:GetSpecialValueFor("burn_interval")
    end
    self:StartIntervalThink(self.interval)
  end
end

function modifier_dragon_knight_custom_shard_effect_oaa:OnRefresh()
  if IsServer() then
    self.percent_damage = 4
    self.interval = 0.5
    local ability = self:GetAbility()
    if ability and not ability:IsNull() then
      self.percent_damage = ability:GetSpecialValueFor("max_hp_damage")
      self.interval = ability:GetSpecialValueFor("burn_interval")
    end
  end
end

function modifier_dragon_knight_custom_shard_effect_oaa:OnIntervalThink()
  if not IsServer() then
    return
  end
  local parent = self:GetParent()
  local caster = self:GetCaster()
  local ability = self:GetAbility()

  if not parent or parent:IsNull() or not caster or caster:IsNull() then
    self:StartIntervalThink(-1)
    self:Destroy()
    return
  end

  local percent_damage = self.percent_damage
  if ability and not ability:IsNull() then
    percent_damage = ability:GetSpecialValueFor("max_hp_damage")
  end

  -- Calculate dps
  local damage_per_second = percent_damage * parent:GetMaxHealth() * 0.01

  -- Do reduced damage to bosses
  if parent:IsOAABoss() then
    damage_per_second = damage_per_second * 15/100
  end

  local damage_table = {
    victim = parent,
    attacker = caster,
    damage = damage_per_second * self.interval,
    damage_type = DAMAGE_TYPE_MAGICAL,
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

