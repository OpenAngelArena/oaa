-- thanks darklord

LinkLuaModifier( "modifier_octarine_vampirism_buff", "modifiers/modifier_octarine_vampirism_buff.lua", LUA_MODIFIER_MOTION_NONE )

modifier_octarine_vampirism_applier = class(ModifierBaseClass)

function modifier_octarine_vampirism_applier:IsHidden()
  return true
end

function modifier_octarine_vampirism_applier:GetAttributes()
  return MODIFIER_ATTRIBUTE_MULTIPLE
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
  return 0
end

--------------------------------------------------------------------------------

function modifier_octarine_vampirism_applier:OnCreated( kv )
  --self.aura_radius = self:GetAbility():GetSpecialValueFor( "radius" )
  local parent = self:GetParent()
  parent:RemoveModifierByName(self:GetModifierAura())
end

function modifier_octarine_vampirism_applier:OnDestroy()
  local parent = self:GetParent()
  parent:RemoveModifierByName(self:GetModifierAura())
end

--------------------------------------------------------------------------------

function modifier_octarine_vampirism_applier:OnRefresh( kv )
  --self.aura_radius = self:GetAbility():GetSpecialValueFor( "radius" )
end

--------------------------------------------------------------------------------
