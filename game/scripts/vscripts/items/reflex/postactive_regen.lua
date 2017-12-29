LinkLuaModifier( "modifier_item_postactive_regen", "items/reflex/postactive_regen.lua", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier("modifier_generic_bonus", "modifiers/modifier_generic_bonus.lua", LUA_MODIFIER_MOTION_NONE)

item_postactive_3c = class(ItemBaseClass)
item_postactive_4c = item_postactive_3c
item_postactive_5c = item_postactive_3c

function item_postactive_3c:GetIntrinsicModifierName()
  return "modifier_generic_bonus"
end

function item_postactive_3c:OnSpellStart()
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
  return self:GetAbility():GetSpecialValueFor( "bonus_health_regen" )
end
