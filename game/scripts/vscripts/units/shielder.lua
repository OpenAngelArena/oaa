local ABILITY_shield = nil

function Spawn (entityKeyValues) --luacheck: ignore Spawn
  if not thisEntity or not IsServer() then
    return
  end

  ABILITY_shield = thisEntity:FindAbilityByName("boss_shielder_shield")

  local phaseController = thisEntity:AddNewModifier(thisEntity, ABILITY_shield, "modifier_boss_phase_controller", {})
  phaseController:SetPhases({ 66, 33 })
  phaseController:SetAbilities({
    "boss_shielder_shield"
  })
end
