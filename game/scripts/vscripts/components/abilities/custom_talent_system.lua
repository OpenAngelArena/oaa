if CustomTalentSystem == nil then
  CustomTalentSystem = class({})
end

function CustomTalentSystem:Init()
  self.moduleName = "CustomTalentSystem"
  LinkLuaModifier("modifier_talent_tracker_oaa", "components/abilities/custom_talent_system.lua", LUA_MODIFIER_MOTION_NONE)
  GameEvents:OnHeroInGame(partial(self.InitializeTalentTracker, self))
end

function CustomTalentSystem:InitializeTalentTracker(hero)
  if hero:GetTeamNumber() == DOTA_TEAM_NEUTRALS then
    return
  end

  --Timers:CreateTimer(2, function ()
  if not hero:HasModifier("modifier_talent_tracker_oaa") then
    hero:AddNewModifier(hero, nil, "modifier_talent_tracker_oaa", {})
  end

  --end)
end

local abilities_with_custom_talents = {
  faceless_void_chronosphere = {
    AbilityCooldown = "special_bonus_unique_faceless_void_2_oaa",
  },
  faceless_void_time_dilation = {
    radius = "special_bonus_unique_faceless_void_1_oaa",
  },
  invoker_emp = {
    damage_per_mana_pct = "special_bonus_unique_invoker_1_oaa",
  },
  invoker_sun_strike = {
    damage = "special_bonus_unique_invoker_2_oaa",
  },
  mirana_leap = {
    leap_bonus_duration = "special_bonus_unique_mirana_3_oaa",
  },
  ursa_earthshock = {
    shock_radius = "special_bonus_unique_ursa_1_oaa",
  },
  windrunner_powershot = {
    powershot_damage = "special_bonus_unique_windranger_1_oaa",
  },
  winter_wyvern_cold_embrace = {
    heal_percentage = "special_bonus_unique_winter_wyvern_1_oaa",
  },
}

---------------------------------------------------------------------------------------------------

modifier_talent_tracker_oaa = class({})

function modifier_talent_tracker_oaa:IsHidden()
  return true
end

function modifier_talent_tracker_oaa:IsPurgable()
  return false
end

function modifier_talent_tracker_oaa:RemoveOnDeath()
  return false
end

function modifier_talent_tracker_oaa:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_OVERRIDE_ABILITY_SPECIAL,
    MODIFIER_PROPERTY_OVERRIDE_ABILITY_SPECIAL_VALUE
  }
end

function modifier_talent_tracker_oaa:GetModifierOverrideAbilitySpecial(keys)
  local parent = self:GetParent()
  if not keys.ability or not keys.ability_special_value then
    return 0
  end

  if not abilities_with_custom_talents[keys.ability:GetAbilityName()] then
    return 0
  end

  local keyvalues_to_upgrade = abilities_with_custom_talents[keys.ability:GetAbilityName()]
  for k, v in pairs(keyvalues_to_upgrade) do
    local custom_talent = parent:FindAbilityByName(v)
    if string.find(keys.ability_special_value, k) and custom_talent and custom_talent:GetLevel() > 0 then
      return 1
    end
  end

  return 0
end

function modifier_talent_tracker_oaa:GetModifierOverrideAbilitySpecialValue(keys)
  local parent = self:GetParent()
  if not abilities_with_custom_talents[keys.ability:GetAbilityName()] then
    return 0
  end
  local value = keys.ability:GetLevelSpecialValueNoOverride(keys.ability_special_value, keys.ability_special_level)
  local keyvalues_to_upgrade = abilities_with_custom_talents[keys.ability:GetAbilityName()]
  for k, v in pairs(keyvalues_to_upgrade) do
    local custom_talent = parent:FindAbilityByName(v)
    if string.find(keys.ability_special_value, k) and custom_talent and custom_talent:GetLevel() > 0 then
      return value + custom_talent:GetSpecialValueFor("value")
    end
  end

  return value
end
