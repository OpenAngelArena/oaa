harpy_storm_null_field_oaa = class(AbilityBaseClass)

LinkLuaModifier("modifier_harpy_null_field_oaa_applier", "abilities/neutrals/oaa_harpy_storm_null_field.lua", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier("modifier_harpy_null_field_oaa_effect", "abilities/neutrals/oaa_harpy_storm_null_field.lua", LUA_MODIFIER_MOTION_NONE )

function harpy_storm_null_field_oaa:GetIntrinsicModifierName()
  return "modifier_harpy_null_field_oaa_applier"
end

--------------------------------------------------------------------------------

modifier_harpy_null_field_oaa_applier = class(ModifierBaseClass)

function modifier_harpy_null_field_oaa_applier:IsHidden()
  return true
end

function modifier_harpy_null_field_oaa_applier:IsDebuff()
  return false
end

function modifier_harpy_null_field_oaa_applier:IsPurgable()
  return false
end

function modifier_harpy_null_field_oaa_applier:IsAura()
  local parent = self:GetParent()
  if parent:PassivesDisabled() then
    return false
  end
  return true
end

function modifier_harpy_null_field_oaa_applier:GetModifierAura()
  return "modifier_harpy_null_field_oaa_effect"
end

function modifier_harpy_null_field_oaa_applier:GetAuraRadius()
  return self:GetAbility():GetSpecialValueFor("radius")
end

function modifier_harpy_null_field_oaa_applier:GetAuraSearchTeam()
  return DOTA_UNIT_TARGET_TEAM_ENEMY
end

function modifier_harpy_null_field_oaa_applier:GetAuraSearchType()
  return bit.bor(DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_BASIC)
end

function modifier_harpy_null_field_oaa_applier:GetAuraSearchFlags()
  return DOTA_UNIT_TARGET_FLAG_OUT_OF_WORLD
end

--------------------------------------------------------------------------------

modifier_harpy_null_field_oaa_effect = class(ModifierBaseClass)

function modifier_harpy_null_field_oaa_effect:IsHidden()
  return false
end

function modifier_harpy_null_field_oaa_effect:IsDebuff()
  return true
end

function modifier_harpy_null_field_oaa_effect:IsPurgable()
  return false
end

function modifier_harpy_null_field_oaa_effect:OnCreated()
  local ability = self:GetAbility()
  if ability then
    self.magic_resistance = ability:GetSpecialValueFor("magic_resistance")
  end
end

function modifier_harpy_null_field_oaa_effect:OnRefresh()
  local ability = self:GetAbility()
  if ability then
    self.magic_resistance = ability:GetSpecialValueFor("magic_resistance")
  end
end

function modifier_harpy_null_field_oaa_effect:DeclareFunctions()
  local funcs = {
    MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS,
  }
  return funcs
end

function modifier_harpy_null_field_oaa_effect:GetModifierMagicalResistanceBonus()
  if self.magic_resistance then
    return self.magic_resistance
  end
  return -15
end
