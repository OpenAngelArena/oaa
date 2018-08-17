LinkLuaModifier( "modifier_item_ward_stack", "items/ward_stack.lua", LUA_MODIFIER_MOTION_NONE )

item_ward_stack = class(ItemBaseClass)

function item_ward_stack:OnSpellCast (keys)
  Debug:EnableDebugging()
  DebugPrintTable(keys)
  DebugPrint('ward stack things')
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

function modifier_item_ward_stack:GetAuraStackingType()
  return AURA_TYPE_NON_STACKING
end

function modifier_item_ward_stack:IsAuraActiveOnDeath()
  return true
end

function modifier_item_ward_stack:GetAttributes()
  return MODIFIER_ATTRIBUTE_MULTIPLE
end

function modifier_item_ward_stack:GetAuraDuration()
  return 10
end

function modifier_item_ward_stack:GetModifierAura()
  return "modifier_item_ward_stack_aura"
end
