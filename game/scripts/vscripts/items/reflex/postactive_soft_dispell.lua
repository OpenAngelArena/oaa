
item_postactive_2b = class({})

function item_postactive_2b:OnSpellStart()
  local caster = self:GetCaster()

  -- void Purge(bool bRemovePositiveBuffs, bool bRemoveDebuffs, bool bFrameOnly, bool bRemoveStuns, bool bRemoveExceptions)
  caster:Purge(false, true, false, true, true)
  return true
end
