
require('internal/util')

LinkLuaModifier("modifier_boss_stopfightingyourself_debuff_mirror", "abilities/stopfightingyourself/debuff_mirror.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_purgetester", "modifiers/modifier_purgetester.lua", LUA_MODIFIER_MOTION_NONE)



boss_stopfightingyourself_debuff_mirror = class({})

function boss_stopfightingyourself_debuff_mirror:GetIntrinsicModifierName()
  return "modifier_boss_stopfightingyourself_debuff_mirror"
end

function boss_stopfightingyourself_debuff_mirror:GetBehavior()
  return DOTA_ABILITY_BEHAVIOR_PASSIVE
end



modifier_boss_stopfightingyourself_debuff_mirror = class({})

function modifier_boss_stopfightingyourself_debuff_mirror:DeclareFunctions()
  return {
    MODIFIER_EVENT_ON_ATTACK_LANDED,
  }
end

function modifier_boss_stopfightingyourself_debuff_mirror:IsPurgable()
  return false
end

function modifier_boss_stopfightingyourself_debuff_mirror:OnAttackLanded(keys)
  local attacker = keys.attacker
  local target = keys.target
  local caster = self:GetCaster()

  if attacker ~= caster then
    return
  end

  function IsDebuff(modifier)
    local whitelist = {
      "modifier_item_skadi_slow",
      "modifier_alchemist_acid_spray",
      "modifier_cold_feet",
      "modifier_ice_vortex",
      "modifier_ice_blast",
      "modifier_ursa_fury_swipes_damage_increase",
    }
    if whitelist[modifier:GetName()] then
      return true
    end

    local blacklist = {
      "modifier_truesight",
    }
    if blacklist[modifier:GetName()] then
      return false
    end

    --[[if modifier:IsDebuff ~= nil then
      return modifier:IsDebuff()
    end]]

    -- Tests if given modifier is a debuff and purgable with a basic dispel
    --  Applies the modifier to a test unit, purges the unit with a basic dispel affecting debuffs only,
    --  then checks if the modifier was purged (All because IsDebuff and IsPurgable don't exist in the Lua API
    --  for built-in modifiers)
    function IsPurgableDebuff(modifier)
      local testUnit = CreateUnitByName("npc_dota_lone_druid_bear1", Vector(0, 0, 0), false, caster, caster:GetOwner(), caster:GetTeamNumber())
      testUnit:AddNewModifier(testUnit, nil, "modifier_purgetester", nil)
      testUnit:AddNewModifier(modifier:GetCaster(), modifier:GetAbility(), modifier:GetName(), nil)
      testUnit:Purge(false, true, true, false, false)
      local modifierIsPurgableDebuff = not testUnit:HasModifier(modifier:GetName())
      testUnit:RemoveSelf()
      return modifierIsPurgableDebuff
    end

    return IsPurgableDebuff(modifier)
  end

  --print('-------')
  local modifiers = caster:FindAllModifiers()
  --each(function(x) print(x:GetName()) end, iter(modifiers))
  local purgableDebuffs = filter(IsDebuff, iter(modifiers))
  --print('--')
  --each(function(x) print(x:GetName()) end, iter(purgableDebuffs))
  --print('--')

  if is_null(purgableDebuffs) then
    return
  end

  each(function(modifier)
    --print(modifier:GetName())
    --print(modifier:GetAbility():GetAbilityName())
    --print(modifier:GetCaster():GetName())
    --print('--')
    local duration = modifier:GetDuration() * self:GetAbility():GetSpecialValueFor('duration_multiplier')
    target:AddNewModifier(attacker, modifier:GetAbility(), modifier:GetName(), {
      duration = duration,
      duration_ranged = duration,
      duration_melee = duration,
    })
  end, purgableDebuffs)
end
