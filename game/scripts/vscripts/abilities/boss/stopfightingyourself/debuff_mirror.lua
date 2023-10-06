
LinkLuaModifier("modifier_boss_stopfightingyourself_debuff_mirror", "abilities/boss/stopfightingyourself/debuff_mirror.lua", LUA_MODIFIER_MOTION_NONE)

boss_stopfightingyourself_debuff_mirror = class(AbilityBaseClass)

function boss_stopfightingyourself_debuff_mirror:GetIntrinsicModifierName()
  return "modifier_boss_stopfightingyourself_debuff_mirror"
end

modifier_boss_stopfightingyourself_debuff_mirror = class(ModifierBaseClass)

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

  local function IsDebuff(modifier)
    local whitelist = {
      "modifier_item_skadi_slow",
      "modifier_alchemist_acid_spray",
      "modifier_cold_feet",
      "modifier_ice_vortex",
      "modifier_ice_blast",
      "modifier_ursa_fury_swipes_damage_increase",
    }
    if contains(modifier:GetName(), whitelist) then
      return true
    end

    local blacklist = {
      "modifier_truesight",
      "modifier_item_stoneskin_properties",
    }
    if contains(modifier:GetName(), blacklist) then
      return false
    end

    return modifier:IsDebuff() and (not modifier:IsStunDebuff()) and (not modifier:IsHexDebuff())
  end

  --print('-------')
  local modifiers = caster:FindAllModifiers()
  --each(function(x) print(x:GetName()) end, iter(modifiers))
  local debuffs = filter(IsDebuff, iter(modifiers))
  --print('--')
  --each(function(x) print(x:GetName()) end, iter(debuffs))
  --print('--')

  if is_null(debuffs) then
    return
  end

  for _,modifier in ipairs(debuffs) do
    --print(modifier:GetCaster():GetName())
    --print(modifier:GetAbility():GetAbilityName())
    --print(modifier:GetName())
    --print('--')
    local duration = modifier:GetDuration() * self:GetAbility():GetSpecialValueFor('duration_multiplier')
    local stacks = modifier:GetStackCount()
    local newModifier = target:AddNewModifier(attacker, modifier:GetAbility(), modifier:GetName(), {
      duration = duration,
      duration_ranged = duration,
      duration_melee = duration,
    })
    newModifier:SetStackCount(stacks)
  end
end
