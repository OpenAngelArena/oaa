--[[ Extension functions for CDOTA_BaseNPC

-HasLearnedAbility(abilityName)
  Checks if the unit has at least one point in ability abilityName.
  Primarily for checking if talents have been learned.
--]]

-- This file is also loaded on client (currently just for GetAttackRange)
-- but client doesn't have FindAbilityByName
if IsServer() then
  function CDOTA_BaseNPC:HasLearnedAbility(abilityName)
    local ability = self:FindAbilityByName(abilityName)
    if ability then
      return ability:GetLevel() > 0
    end
    return false
  end
end

if CDOTA_BaseNPC then
  function CDOTA_BaseNPC:GetAttackRange()
    return self:Script_GetAttackRange()
  end
end
