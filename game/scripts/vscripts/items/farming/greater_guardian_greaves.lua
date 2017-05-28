LinkLuaModifier( "modifier_item_greater_guardian_greaves", "items/farming/greater_guardian_greaves.lua", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_item_greater_guardian_greaves_aura", "items/farming/greater_guardian_greaves.lua", LUA_MODIFIER_MOTION_NONE )

LinkLuaModifier( "modifier_creep_assist_gold", "items/farming/modifier_creep_assist_gold.lua", LUA_MODIFIER_MOTION_NONE )

LinkLuaModifier( "modifier_intrinsic_muliplexer", "modifiers/modifier_intrinsic_muliplexer.lua", LUA_MODIFIER_MOTION_NONE )

item_greater_guardian_greaves = class({})

  --[[
      "14"
      {
        "var_type"                                        "FIELD_INTEGER"
        "assist_percent"                                  "30 50 75 100 150"
      }
    }
-item greater_guardian_greaves
]]

function item_greater_guardian_greaves:OnSpellStart()
  local caster = self:GetCaster()

  local heroes = FindUnitsInRadius(
    caster:GetTeamNumber(),
    caster:GetAbsOrigin(),
    nil,
    self:GetSpecialValueFor("replenish_radius"),
    DOTA_UNIT_TARGET_TEAM_FRIENDLY,
    DOTA_UNIT_TARGET_HERO,
    DOTA_UNIT_TARGET_FLAG_NONE,
    FIND_ANY_ORDER,
    false
  )

  heroes = iter(heroes)
  heroes:each(function (hero)
    hero:Heal(self:GetSpecialValueFor("replenish_health"), stone)
    hero:GiveMana(self:GetSpecialValueFor("replenish_mana"))
  end)

end

function item_greater_guardian_greaves:GetIntrinsicModifierName()
  return "modifier_intrinsic_muliplexer"
end
function item_greater_guardian_greaves:GetIntrinsicModifierNames()
  return {
    "modifier_item_greater_guardian_greaves",
    "modifier_creep_assist_gold"
  }
end

------------------------------------------------------------------------------

modifier_item_greater_guardian_greaves = class({})

function modifier_item_greater_guardian_greaves:IsHidden()
  return true
end

function modifier_item_greater_guardian_greaves:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_MOVESPEED_BONUS_UNIQUE,
    MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
    MODIFIER_PROPERTY_STATS_INTELLECT_BONUS,
    MODIFIER_PROPERTY_STATS_AGILITY_BONUS,
    MODIFIER_PROPERTY_MANA_BONUS,
    MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS
  }
end

function modifier_item_greater_guardian_greaves:GetModifierBonusStats_Agility()
  return self:GetAbility():GetSpecialValueFor("bonus_all_stats")
end
function modifier_item_greater_guardian_greaves:GetModifierBonusStats_Intellect()
  return self:GetAbility():GetSpecialValueFor("bonus_all_stats")
end
function modifier_item_greater_guardian_greaves:GetModifierBonusStats_Strength()
  return self:GetAbility():GetSpecialValueFor("bonus_all_stats")
end
function modifier_item_greater_guardian_greaves:GetModifierMoveSpeedBonus_Special_Boots()
  return self:GetAbility():GetSpecialValueFor("bonus_movement")
end
function modifier_item_greater_guardian_greaves:GetModifierMoveSpeedBonus_Special_Boots()
  return self:GetAbility():GetSpecialValueFor("bonus_movement")
end
function modifier_item_greater_guardian_greaves:GetModifierManaBonus()
  return self:GetAbility():GetSpecialValueFor("bonus_mana")
end
function modifier_item_greater_guardian_greaves:GetModifierPhysicalArmorBonus()
  return self:GetAbility():GetSpecialValueFor("bonus_armor")
end

--------------------------------------------------------------------------
-- aura stuff

function modifier_item_greater_guardian_greaves:IsAura()
  return true
end

function modifier_item_greater_guardian_greaves:GetAuraSearchType()
  return DOTA_UNIT_TARGET_HERO
end

function modifier_item_greater_guardian_greaves:GetAuraSearchTeam()
  return DOTA_UNIT_TARGET_TEAM_FRIENDLY
end

function modifier_item_greater_guardian_greaves:GetAuraRadius()
  return self:GetAbility():GetSpecialValueFor("aura_radius")
end

function modifier_item_greater_guardian_greaves:GetModifierAura()
  return "modifier_item_greater_guardian_greaves_aura"
end

function modifier_item_greater_guardian_greaves:GetAuraEntityReject(entity)
  if entity:IsRealHero() then
    return false
  end
  return true
end

------------------------------------------------------------------------------

modifier_item_greater_guardian_greaves_aura = class({})

function modifier_item_greater_guardian_greaves_aura:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT,
    MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS
  }
end

function modifier_item_greater_guardian_greaves_aura:GetModifierConstantHealthRegen()
  local hero = self:GetParent()
  if not hero or not hero.GetHealth then
    return
  end
  local hpPercent = (hero:GetHealth() / hero:GetMaxHealth()) * 100
  if hpPercent < self:GetAbility():GetSpecialValueFor("aura_bonus_threshold") then
    return self:GetAbility():GetSpecialValueFor("aura_health_regen_bonus")
  else
    return self:GetAbility():GetSpecialValueFor("aura_health_regen")
  end
end

function modifier_item_greater_guardian_greaves:GetModifierPhysicalArmorBonus()
  local hero = self:GetParent()
  if not hero or not hero.GetHealth then
    return
  end
  local hpPercent = (hero:GetHealth() / hero:GetMaxHealth()) * 100
  if hpPercent < self:GetAbility():GetSpecialValueFor("aura_bonus_threshold") then
    return self:GetAbility():GetSpecialValueFor("aura_armor_bonus")
  else
    return self:GetAbility():GetSpecialValueFor("aura_armor")
  end
  return self:GetAbility():GetSpecialValueFor("aura_armor")
end
