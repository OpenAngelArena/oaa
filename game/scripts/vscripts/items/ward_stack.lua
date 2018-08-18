LinkLuaModifier( "modifier_item_ward_stack", "items/ward_stack.lua", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_item_ward_stack_aura", "items/ward_stack.lua", LUA_MODIFIER_MOTION_NONE )

item_ward_stack = class(ItemBaseClass)

-- active effect!
function item_ward_stack:OnSpellCast (keys)
  Debug:EnableDebugging()
  DebugPrintTable(keys)
  DebugPrint('ward stack things')
end

function item_ward_stack:GetIntrinsicModifierName ()
  return "modifier_item_ward_stack"
end

item_ward_stack_2 = item_ward_stack
item_ward_stack_3 = item_ward_stack
item_ward_stack_4 = item_ward_stack

--------------------------------------------------------------------------
-- modifier_item_ward_stack
--------------------------------------------------------------------------

modifier_item_ward_stack = class(AuraProviderBaseClass)

function modifier_item_ward_stack:IsHidden()
  return true
end

-- aura stuff
function modifier_item_ward_stack:GetAuraStackingType()
  return AURA_TYPE_NON_STACKING
end

function modifier_item_ward_stack:IsAuraActiveOnDeath()
  return true
end

function modifier_item_ward_stack:GetAuraRadius()
  return self:GetAbility():GetSpecialValueFor('aura_radius')
end

function modifier_item_ward_stack:GetAttributes()
  return MODIFIER_ATTRIBUTE_MULTIPLE
end

function modifier_item_ward_stack:GetAuraDuration()
  return 1
end

function modifier_item_ward_stack:GetModifierAura()
  return "modifier_item_ward_stack_aura"
end

-- passive stats
function modifier_item_ward_stack:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT
    MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS
    MODIFIER_PROPERTY_HEALTH_BONUS
    MODIFIER_PROPERTY_MANA_BONUS
  }
end

function modifier_item_ward_stack:GetModifierConstantHealthRegen()
  return self:GetAbility():GetSpecialValueFor('bonus_health_regen')
end
function modifier_item_ward_stack:GetModifierPhysicalArmorBonus()
  return self:GetAbility():GetSpecialValueFor('bonus_armor')
end
function modifier_item_ward_stack:GetModifierHealthBonus()
  return self:GetAbility():GetSpecialValueFor('bonus_health')
end
function modifier_item_ward_stack:GetModifierManaBonus()
  return self:GetAbility():GetSpecialValueFor('bonus_mana')
end

--------------------------------------------------------------------------
-- modifier_item_ward_stack_aura
--------------------------------------------------------------------------

modifier_item_ward_stack_aura = class(AuraEffectBaseClass)

function modifier_item_ward_stack_aura:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_MANA_REGEN_CONSTANT
  }
end

function modifier_item_ward_stack_aura:GetModifierConstantManaRegen()
  return self:GetAbility():GetSpecialValueFor('aura_mana_regen')
end
