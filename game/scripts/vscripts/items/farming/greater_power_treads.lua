item_greater_power_treads = class(ItemBaseClass)

LinkLuaModifier( "modifier_item_greater_power_treads", "items/farming/greater_power_treads.lua", LUA_MODIFIER_MOTION_NONE )

--------------------------------------------------------------------------------

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

--------------------------------------------------------------------------------

function item_greater_power_treads:GetIntrinsicModifierName()
  return "modifier_item_greater_power_treads"
end

--------------------------------------------------------------------------------

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

    caster:CalculateStatBonus()
  end
end

--------------------------------------------------------------------------------

function item_greater_power_treads:IsSwappable()
  return self:GetSpecialValueFor("bonus_stat") > 0
end

--------------------------------------------------------------------------------

modifier_item_greater_power_treads = class(ModifierBaseClass)

--------------------------------------------------------------------------------

function modifier_item_greater_power_treads:IsHidden()
  return true
end

function modifier_item_greater_power_treads:IsDebuff()
  return false
end

function modifier_item_greater_power_treads:IsPurgable()
  return false
end

function modifier_item_greater_power_treads:GetAttributes()
  return MODIFIER_ATTRIBUTE_MULTIPLE
end

--------------------------------------------------------------------------------

function modifier_item_greater_power_treads:OnCreated( event )
  local spell = self:GetAbility()

  if not spell then
    return
  end

  if spell.attribute then
    self:SetStackCount( spell.attribute )
  end

  spell.treadMod = self

  self.moveSpd = spell:GetSpecialValueFor( "bonus_movement_speed" )
  self.atkSpd = spell:GetSpecialValueFor( "bonus_attack_speed" )
  self.stat = spell:GetSpecialValueFor( "bonus_stat" )
  self.bonus_damage = spell:GetSpecialValueFor( "bonus_damage" )
  self.all_stats = spell:GetSpecialValueFor( "all_stats" )
end

--------------------------------------------------------------------------------

function modifier_item_greater_power_treads:OnRefresh( event )
  return self:OnCreated( event )
end

--------------------------------------------------------------------------------

function modifier_item_greater_power_treads:OnRemoved()
  local spell = self:GetAbility()

  if not spell then
    return
  end

  if spell and not spell:IsNull() then
    spell.treadMod = nil
  end
end

--------------------------------------------------------------------------------

function modifier_item_greater_power_treads:DeclareFunctions()
  local funcs = {
    MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE_UNIQUE,
    MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
    MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
    MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
    MODIFIER_PROPERTY_STATS_AGILITY_BONUS,
    MODIFIER_PROPERTY_STATS_INTELLECT_BONUS,
    --MODIFIER_EVENT_ON_ATTACK_LANDED,
  }

  return funcs
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


function modifier_item_greater_power_treads:GetModifierMoveSpeedBonus_Percentage_Unique()
  return self.moveSpd
end

--------------------------------------------------------------------------------

function modifier_item_greater_power_treads:GetModifierAttackSpeedBonus_Constant()
  return self.atkSpd
end

--------------------------------------------------------------------------------

function modifier_item_greater_power_treads:GetModifierBonusStats_Strength()
  local attribute = self:GetStackCount() or DOTA_ATTRIBUTE_STRENGTH
  local bonus = self.all_stats

  if attribute == DOTA_ATTRIBUTE_STRENGTH then
    bonus = bonus + self.stat
  end

  return bonus
end

--------------------------------------------------------------------------------

function modifier_item_greater_power_treads:GetModifierBonusStats_Agility()
  local attribute = self:GetStackCount() or DOTA_ATTRIBUTE_STRENGTH
  local bonus = self.all_stats

  if attribute == DOTA_ATTRIBUTE_AGILITY then
    bonus = bonus + self.stat
  end

  return bonus
end

--------------------------------------------------------------------------------

function modifier_item_greater_power_treads:GetModifierBonusStats_Intellect()
  local attribute = self:GetStackCount() or DOTA_ATTRIBUTE_STRENGTH
  local bonus = self.all_stats

  if attribute == DOTA_ATTRIBUTE_INTELLECT then
    bonus = bonus + self.stat
  end

  return bonus
end

function modifier_item_greater_power_treads:GetModifierPreAttack_BonusDamage()
  local spell = self:GetAbility()

  return self.bonus_damage or spell:GetSpecialValueFor("bonus_damage")
end

--------------------------------------------------------------------------------

item_greater_power_treads_2 = class(item_greater_power_treads)
item_greater_power_treads_3 = class(item_greater_power_treads)
item_greater_power_treads_4 = class(item_greater_power_treads)
item_greater_power_treads_5 = class(item_greater_power_treads)
--item_power_origin = class(item_greater_power_treads)
