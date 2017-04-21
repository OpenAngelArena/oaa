LinkLuaModifier("modifier_generic_bonus", "modifiers/modifier_generic_bonus.lua", LUA_MODIFIER_MOTION_NONE)

item_postactive_3b = class({})

function item_postactive_3b:GetIntrinsicModifierName()
  return "modifier_generic_bonus"
end

function item_postactive_3b:OnSpellStart()
  local caster = self:GetCaster()

  -- void Purge(bool bRemovePositiveBuffs, bool bRemoveDebuffs, bool bFrameOnly, bool bRemoveStuns, bool bRemoveExceptions)
  caster:Purge(false, true, false, true, true)
end
