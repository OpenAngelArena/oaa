LinkLuaModifier("modifier_generic_bonus", "modifiers/modifier_generic_bonus.lua", LUA_MODIFIER_MOTION_NONE)

item_enrage_crystal_1 = class(ItemBaseClass)

item_enrage_crystal_2 = class(ItemBaseClass)

item_enrage_crystal_3 = class(ItemBaseClass)

function item_enrage_crystal_1:GetIntrinsicModifierName()
  return "modifier_generic_bonus"
end

function item_enrage_crystal_1:OnSpellStart()
  local caster = self:GetCaster()

  -- void Purge(bool bRemovePositiveBuffs, bool bRemoveDebuffs, bool bFrameOnly, bool bRemoveStuns, bool bRemoveExceptions)
  caster:Purge(false, true, false, true, true)
end
