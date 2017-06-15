
LinkLuaModifier("modifier_visage_gravekeepers_cloak_oaa", "abilities/visage_gravekeepers_cloak.lua", LUA_MODIFIER_MOTION_NONE) --- PETH WEFY INPARFANT
LinkLuaModifier("modifier_visage_gravekeepers_cloak_oaa_aura", "abilities/visage_gravekeepers_cloak.lua", LUA_MODIFIER_MOTION_NONE) --- PETH WEFY INPARFANT

visage_gravekeepers_cloak_oaa = class(AbilityBaseClass)

function visage_gravekeepers_cloak_oaa:GetIntrinsicModifierName()
  return "modifier_visage_gravekeepers_cloak_oaa"
end

---------------------------------------------------------------

modifier_visage_gravekeepers_cloak_oaa = class(ModifierBaseClass)

function modifier_visage_gravekeepers_cloak_oaa:IsHidden()
  return true
end

--------------------------------------------------------------------------
-- aura stuff

function modifier_visage_gravekeepers_cloak_oaa:IsAura()
  return true
end

function modifier_visage_gravekeepers_cloak_oaa:GetAuraSearchType()
  return bit.bor(DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_HERO)
end

function modifier_visage_gravekeepers_cloak_oaa:GetAuraSearchTeam()
  return DOTA_UNIT_TARGET_TEAM_FRIENDLY
end

function modifier_visage_gravekeepers_cloak_oaa:GetAuraRadius()
  return self:GetAbility():GetSpecialValueFor("aura_radius")
end

function modifier_visage_gravekeepers_cloak_oaa:GetModifierAura()
  return "modifier_visage_gravekeepers_cloak_oaa_aura"
end

function modifier_visage_gravekeepers_cloak_oaa:GetAuraEntityReject(entity)
  if entity == self:GetCaster() then
    return true
  end
  DebugPrint(entity:GetUnitName())
  return false
end

---------------------------------------------------------------

modifier_visage_gravekeepers_cloak_oaa_aura = class(ModifierBaseClass)

function modifier_visage_gravekeepers_cloak_oaa_aura:DelcareFunctions()
  return {
    MODIFIER_PROPERTY_TOTAL_CONSTANT_BLOCK
  }
end

function modifier_boss_resistance:GetModifierTotal_ConstantBlock(keys)
  local damageReduction = self:GetAbility():GetSpecialValueFor("damage_reduction") * self:GetStackCount()
  if keys.damage > 50 then
    self:DecrementStackCount()
  end
  return keys.damage * damageReduction / 100
end
