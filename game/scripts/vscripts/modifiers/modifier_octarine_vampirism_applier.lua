-- thanks darklord

modifier_octarine_vampirism_applier = class({})

function modifier_octarine_vampirism_applier:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_STATS_INTELLECT_BONUS,
    MODIFIER_PROPERTY_HEALTH_BONUS,
    MODIFIER_PROPERTY_MANA_BONUS,
    MODIFIER_PROPERTY_COOLDOWN_PERCENTAGE,
    MODIFIER_PROPERTY_MANA_REGEN_PERCENTAGE,
    MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT
  }
end

function modifier_octarine_vampirism_applier:GetModifierConstantHealthRegen()
  return self:GetAbility():GetSpecialValueFor('bonus_health_regen')
end

function modifier_octarine_vampirism_applier:GetModifierPercentageManaRegen()
  return self:GetAbility():GetSpecialValueFor('bonus_mana_regen')
end

function modifier_octarine_vampirism_applier:GetModifierBonusStats_Intellect()
  return self:GetAbility():GetSpecialValueFor('bonus_intelligence')
end

function modifier_octarine_vampirism_applier:GetModifierHealthBonus()
  return self:GetAbility():GetSpecialValueFor('bonus_health')
end

function modifier_octarine_vampirism_applier:GetModifierManaBonus()
  return self:GetAbility():GetSpecialValueFor('bonus_mana')
end

function modifier_octarine_vampirism_applier:GetModifierPercentageCooldown()
  return self:GetAbility():GetSpecialValueFor('bonus_cooldown')
end

--------------------------------------------------------------------------------

function modifier_octarine_vampirism_applier:IsHidden()
  return true
end

--------------------------------------------------------------------------------

function modifier_octarine_vampirism_applier:IsAura()
  return true
end

--------------------------------------------------------------------------------

function modifier_octarine_vampirism_applier:GetModifierAura()
  return "modifier_octarine_vampirism_buff"
end

--------------------------------------------------------------------------------

function modifier_octarine_vampirism_applier:GetAuraSearchTeam()
  return DOTA_UNIT_TARGET_TEAM_FRIENDLY
end

function modifier_octarine_vampirism_applier:IsPurgable()
  return false
end

--------------------------------------------------------------------------------

function modifier_octarine_vampirism_applier:GetAuraSearchType()
  return DOTA_UNIT_TARGET_HERO
end

--------------------------------------------------------------------------------

function modifier_octarine_vampirism_applier:GetAuraSearchFlags()
  return DOTA_UNIT_TARGET_FLAG_INVULNERABLE
end

--------------------------------------------------------------------------------

function modifier_octarine_vampirism_applier:GetAuraRadius()
  return self.aura_radius
end

--------------------------------------------------------------------------------

function modifier_octarine_vampirism_applier:OnCreated( kv )
  self.aura_radius = self:GetAbility():GetSpecialValueFor( "radius" )
end

--------------------------------------------------------------------------------

function modifier_octarine_vampirism_applier:OnRefresh( kv )
  self.aura_radius = self:GetAbility():GetSpecialValueFor( "radius" )
end

--------------------------------------------------------------------------------
