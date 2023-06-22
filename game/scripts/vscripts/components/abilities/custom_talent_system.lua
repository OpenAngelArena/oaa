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

-- Format:
-- ability_name = {
  -- kv_name_1 = {"custom_talent_name", "type"},
  -- kv_name_2 = {"custom_talent_name", "type"},
  -- ...
-- },
-- type can be: +, *, x, /, %
-- * and x are the same -  muliplies the base value with the talent value
-- / - can be used for dividing cooldowns, intervals etc.
-- % - increases the base value by the talent value (e.g. 20% increase of base value)

local abilities_with_custom_talents = {
  abaddon_frostmourne = {
    curse_attack_speed = {"special_bonus_unique_abaddon_1_oaa", "+"},
  },
  faceless_void_chronosphere = {
    AbilityCooldown = {"special_bonus_unique_faceless_void_2_oaa", "+"},
  },
  faceless_void_time_dilation = {
    radius = {"special_bonus_unique_faceless_void_1_oaa", "+"},
  },
  hoodwink_acorn_shot = {
    base_damage_pct = {"special_bonus_unique_hoodwink_1_oaa", "+"},
  },
  invoker_emp = {
    damage_per_mana_pct = {"special_bonus_unique_invoker_1_oaa", "+"},
  },
  invoker_sun_strike = {
    damage = {"special_bonus_unique_invoker_2_oaa", "+"},
  },
  life_stealer_feast = {
    hp_damage_percent = {"special_bonus_unique_lifestealer_3_oaa", "+"},
  },
  mars_arena_of_blood = {
    spear_damage = {"special_bonus_unique_mars_2_oaa", "+"},
  },
  mirana_leap = {
    leap_bonus_duration = {"special_bonus_unique_mirana_3_oaa", "+"},
  },
  queenofpain_shadow_strike = {
    duration_heal = {"special_bonus_unique_queen_of_pain_4_oaa", "+"},
  },
  silencer_last_word = {
    damage = {"special_bonus_unique_silencer_2_oaa", "+"},
  },
  skywrath_mage_arcane_bolt = {
    bolt_damage = {"special_bonus_unique_skywrath_1_oaa", "+"},
  },
  ursa_earthshock = {
    shock_radius = {"special_bonus_unique_ursa_1_oaa", "+"},
  },
  windrunner_powershot = {
    powershot_damage = {"special_bonus_unique_windranger_1_oaa", "+"},
  },
  winter_wyvern_cold_embrace = {
    heal_percentage = {"special_bonus_unique_winter_wyvern_1_oaa", "+"},
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
    local custom_talent = parent:FindAbilityByName(v[1])
    if string.find(keys.ability_special_value, k) and custom_talent and custom_talent:GetLevel() > 0 then
      return 1
    end
  end

  return 0
end

function modifier_talent_tracker_oaa:GetModifierOverrideAbilitySpecialValue(keys)
  local parent = self:GetParent()
  local value = keys.ability:GetLevelSpecialValueNoOverride(keys.ability_special_value, keys.ability_special_level)

  if not abilities_with_custom_talents[keys.ability:GetAbilityName()] then
    return value
  end

  local keyvalues_to_upgrade = abilities_with_custom_talents[keys.ability:GetAbilityName()]
  for k, v in pairs(keyvalues_to_upgrade) do
    local custom_talent = parent:FindAbilityByName(v[1])
    if string.find(keys.ability_special_value, k) and custom_talent and custom_talent:GetLevel() > 0 then
      local talent_type = v[2]
      local talent_value = custom_talent:GetSpecialValueFor("value")
      if talent_type == "+" then
        return value + talent_value
      elseif talent_type == "x" or talent_type == "*" then
        return value * talent_value
      elseif talent_type == "/" and talent_value ~= 0 then
        return value / talent_value
      elseif talent_type == "%" then
        return value * (1 + talent_value / 100)
      end
    end
  end

  return value
end
