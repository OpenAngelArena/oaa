LinkLuaModifier( "modifier_item_postactive_regen", "items/reflex/postactive_regen.lua", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier("modifier_generic_bonus", "modifiers/modifier_generic_bonus.lua", LUA_MODIFIER_MOTION_NONE)

item_regen_crystal_1 = class(ItemBaseClass)
item_regen_crystal_2 = item_regen_crystal_1
item_regen_crystal_3 = item_regen_crystal_1

function item_regen_crystal_1:GetIntrinsicModifierName()
  return "modifier_generic_bonus"
end

function item_regen_crystal_1:OnSpellStart()
  local caster = self:GetCaster()
  caster:AddNewModifier(caster, self, 'modifier_item_postactive_regen', {
    duration = self:GetSpecialValueFor( "duration" )
  })
end

modifier_item_postactive_regen = class(ModifierBaseClass)

function modifier_item_postactive_regen:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT
  }
end

function modifier_item_postactive_regen:GetModifierConstantHealthRegen()
  return self:GetAbility():GetSpecialValueFor( "active_health_regen" )
end
