item_greater_power_treads = class(ItemBaseClass)

LinkLuaModifier( "modifier_item_greater_power_treads", "items/greater_power_treads.lua", LUA_MODIFIER_MOTION_NONE )

--[[ old
function item_greater_power_treads:GetAbilityTextureName()
  local baseName = self.BaseClass.GetAbilityTextureName( self )

  if not self:IsSwappable() then
    return baseName
  end

  local attribute = -1

  if self.treadMod then
    attribute = self.treadMod:GetStackCount()
  end

  local attributeName = ""

  if attribute == DOTA_ATTRIBUTE_INTELLECT then
    attributeName = "_int"
  elseif attribute == DOTA_ATTRIBUTE_AGILITY then
    attributeName = "_agi"
  elseif attribute == DOTA_ATTRIBUTE_STRENGTH then
    attributeName = "_str"
  end

  return baseName .. attributeName
end
]]

function item_greater_power_treads:GetIntrinsicModifierName()
  return "modifier_item_greater_power_treads"
end

--[[ old
function item_greater_power_treads:OnSpellStart()
  if self.treadMod then
    local attribute = self.treadMod:GetStackCount()

    attribute = attribute - 1

    if attribute < DOTA_ATTRIBUTE_STRENGTH then
      attribute = DOTA_ATTRIBUTE_INTELLECT
    end

    self.treadMod:SetStackCount( attribute )
    self.attribute = attribute

    local caster = self:GetCaster()

    caster:CalculateStatBonus(false)
  end
end

function item_greater_power_treads:IsSwappable()
  return self:GetSpecialValueFor("bonus_stat") > 0
end
]]

item_greater_power_treads_2 = class(item_greater_power_treads)
item_greater_power_treads_3 = class(item_greater_power_treads)
item_greater_power_treads_4 = class(item_greater_power_treads)

---------------------------------------------------------------------------------------------------

modifier_item_greater_power_treads = class(ModifierBaseClass)

function modifier_item_greater_power_treads:IsHidden()
  return true
end

function modifier_item_greater_power_treads:IsDebuff()
  return false
end

function modifier_item_greater_power_treads:IsPurgable()
  return false
end

-- We don't have this on purpose because we don't want people to buy multiple of these
--function modifier_item_greater_power_treads:GetAttributes()
  --return MODIFIER_ATTRIBUTE_MULTIPLE
--end

function modifier_item_greater_power_treads:OnCreated()
  self:OnRefresh()
  if IsServer() then
    self:StartIntervalThink(0.1)
  end
end

function modifier_item_greater_power_treads:OnRefresh()
  local ability = self:GetAbility()
  if not ability or ability:IsNull() then
    return
  end

  --if ability.attribute then
    --self:SetStackCount( ability.attribute )
  --end

  --ability.treadMod = self

  self.moveSpd = ability:GetSpecialValueFor("bonus_movement_speed")
  self.atkSpd = ability:GetSpecialValueFor("bonus_attack_speed")
  self.bonus_damage = ability:GetSpecialValueFor("bonus_damage")
  self.magic_resistance = ability:GetSpecialValueFor("bonus_magic_resistance")
  self.spell_amp = ability:GetSpecialValueFor("bonus_spell_amp")
  self.multiplier = ability:GetSpecialValueFor("primary_attribute_multiplier")
  self.bonus_to_primary_stat = ability:GetSpecialValueFor("primary_attribute_bonus")
  self.bonus_to_secondary_stats = ability:GetSpecialValueFor("bonus_secondary_stats")

  self.bonus_stat_for_universal = math.ceil(self.bonus_to_primary_stat/3) + math.ceil(self.bonus_to_secondary_stats/2)
end

if IsServer() then
  function modifier_item_greater_power_treads:OnIntervalThink()
    local parent = self:GetParent()

    if not parent or parent:IsNull() then
      self:StartIntervalThink(-1)
      return
    end

    -- Ignore Meepo clones
    if parent:IsClone() then
      self:StartIntervalThink(-1) -- dynamic clones still don't exist, so we can stop thinking
      self:SetStackCount(DOTA_ATTRIBUTE_MAX+1) -- don't grant STR, AGI or INT to clones
      return
    end

    local attribute = parent:GetPrimaryAttribute()
    self:SetStackCount(attribute)
    -- We can stop the interval if dynamic changing of the primary attribute doesn't exist
    -- Morphling ultimate changes primary attribute ...
    self:StartIntervalThink(-1)
  end
end

function modifier_item_greater_power_treads:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_MOVESPEED_BONUS_UNIQUE,
    MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
    MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
    MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
    MODIFIER_PROPERTY_STATS_AGILITY_BONUS,
    MODIFIER_PROPERTY_STATS_INTELLECT_BONUS,
    MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS,
    MODIFIER_PROPERTY_SPELL_AMPLIFY_PERCENTAGE,
    --MODIFIER_EVENT_ON_ATTACK_LANDED,
  }
end

function modifier_item_greater_power_treads:GetModifierMoveSpeedBonus_Special_Boots()
  return self.moveSpd
end

function modifier_item_greater_power_treads:GetModifierBonusStats_Strength()
  local attribute = self:GetStackCount()
  if attribute == DOTA_ATTRIBUTE_STRENGTH then
    return self.bonus_to_primary_stat
  elseif attribute == DOTA_ATTRIBUTE_ALL then
    return self.bonus_stat_for_universal
  elseif attribute == DOTA_ATTRIBUTE_MAX+1 then
    return 0
  end
  return self.bonus_to_secondary_stats
end

function modifier_item_greater_power_treads:GetModifierBonusStats_Agility()
  local attribute = self:GetStackCount()
  if attribute == DOTA_ATTRIBUTE_AGILITY then
    return self.bonus_to_primary_stat
  elseif attribute == DOTA_ATTRIBUTE_ALL then
    return self.bonus_stat_for_universal
  elseif attribute == DOTA_ATTRIBUTE_MAX+1 then
    return 0
  end
  return self.bonus_to_secondary_stats
end

function modifier_item_greater_power_treads:GetModifierBonusStats_Intellect()
  local attribute = self:GetStackCount()
  if attribute == DOTA_ATTRIBUTE_INTELLECT then
    return self.bonus_to_primary_stat
  elseif attribute == DOTA_ATTRIBUTE_ALL then
    return self.bonus_stat_for_universal
  elseif attribute == DOTA_ATTRIBUTE_MAX+1 then
    return 0
  end
  return self.bonus_to_secondary_stats
end

function modifier_item_greater_power_treads:GetModifierMagicalResistanceBonus()
  local attribute = self:GetStackCount()
  if attribute == DOTA_ATTRIBUTE_STRENGTH then
    return self.multiplier * self.magic_resistance
  end
  return self.magic_resistance
end

function modifier_item_greater_power_treads:GetModifierAttackSpeedBonus_Constant()
  local attribute = self:GetStackCount()
  if attribute == DOTA_ATTRIBUTE_AGILITY then
    return self.multiplier * self.atkSpd
  end
  return self.atkSpd
end

function modifier_item_greater_power_treads:GetModifierSpellAmplify_Percentage()
  local attribute = self:GetStackCount()
  if attribute == DOTA_ATTRIBUTE_INTELLECT then
    return self.multiplier * self.spell_amp
  end
  return self.spell_amp
end

function modifier_item_greater_power_treads:GetModifierPreAttack_BonusDamage()
  local attribute = self:GetStackCount()
  if attribute == DOTA_ATTRIBUTE_ALL then
    return self.multiplier * self.bonus_damage
  end
  return self.bonus_damage
end

--------------------------------------------------------------------------------
-- farewell power treads splash
-- i loved you
--[[
if IsServer() then
  function modifier_item_greater_power_treads:OnAttackLanded( event )
    local parent = self:GetParent()

    -- with lua events, you need to make sure you're actually looking for the right unit's
    -- attacks and stuff
    if event.attacker == parent and event.process_procs then
      local target = event.target

      -- make sure the initial target is an appropriate unit to split off of
      -- ( so no wards, items, or towers )
      local parentTeam = parent:GetTeamNumber()
      local targetTeam = DOTA_UNIT_TARGET_TEAM_ENEMY
      local targetType = bit.bor( DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_BASIC )
      local targetFlags = DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES

      -- if not, cancel
      if UnitFilter( target, targetTeam, targetType, targetFlags, parentTeam ) ~= UF_SUCCESS then
        return
      end

      local spell = self:GetAbility()
      local parentOrigin = parent:GetAbsOrigin()
      local targetOrigin = target:GetAbsOrigin()

      -- set the targeting requirements for the actual targets
      targetTeam = DOTA_UNIT_TARGET_TEAM_ENEMY
      targetType = DOTA_UNIT_TARGET_BASIC
      targetFlags = bit.bor( DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, DOTA_UNIT_TARGET_FLAG_NOT_CREEP_HERO )

      -- get the radius
      local radius = spell:GetSpecialValueFor( "split_radius" )

      -- find all appropriate targets around the initial target
      local units = FindUnitsInRadius(
        parentTeam,
        targetOrigin,
        nil,
        radius,
        targetTeam,
        targetType,
        targetFlags,
        FIND_ANY_ORDER,
        false
      )

      -- remove the initial target from the list
      for k, unit in pairs( units ) do
        if unit == target then
          table.remove( units, k )
          break
        end
      end

      -- only play the particle if it actually damages something
      local doParticle = false

      -- get the wearer's damage
      local damage = event.original_damage

      -- get the damage modifier
      local damageMod = spell:GetSpecialValueFor( "split_damage" )

      if parent:GetAttackCapability() == DOTA_UNIT_CAP_RANGED_ATTACK then
        damageMod = spell:GetSpecialValueFor( "split_damage_ranged" )
      end

      damageMod = damageMod * 0.01

      -- apply the damage modifier
      damage = damage * damageMod

      -- iterate through all targets
      for k, unit in pairs( units ) do
        -- inflict damage
        -- DOTA_DAMAGE_FLAG_NO_SPELL_AMPLIFICATION prevents spell amp and spell lifesteal
        if ApplyDamage( {
          victim = unit,
          attacker = self:GetCaster(),
          damage = damage,
          damage_type = DAMAGE_TYPE_PHYSICAL,
          damage_flags = DOTA_DAMAGE_FLAG_NO_SPELL_AMPLIFICATION,
          ability = self,
        } ) then
          doParticle = true
        end
      end

      if doParticle == true then
        -- play the particle
        local part = ParticleManager:CreateParticle( "particles/items/powertreads_splash.vpcf", PATTACH_POINT, target )
        ParticleManager:SetParticleControl( part, 5, Vector( 1, 0, radius ) )
        ParticleManager:ReleaseParticleIndex( part )
      end
    end
  end
end
--]]
