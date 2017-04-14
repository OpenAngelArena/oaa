
item_postactive_3b = class({})

function item_postactive_3b:ResetToggleOnRespawn()
  return true
end

function item_postactive_3b:OnToggle(keys)
  local caster = self:GetCaster()

  -- void Purge(bool bRemovePositiveBuffs, bool bRemoveDebuffs, bool bFrameOnly, bool bRemoveStuns, bool bRemoveExceptions)
  caster:Purge(false, true, false, true, false)

  -- important else you can use while on CD every other time
  if self:GetToggleState() then
    self:ToggleAbility()
  end

  self:StartCooldown(self:GetCooldownTime())

  return false
end
