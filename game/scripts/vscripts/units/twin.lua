LinkLuaModifier( "modifier_boss_phase_controller", "modifiers/modifier_boss_phase_controller", LUA_MODIFIER_MOTION_NONE )

function Spawn (entityKeyValues)
  thisEntity:FindAbilityByName("boss_twin_twin_empathy")
  thisEntity:FindAbilityByName("boss_twin_spawn_twin")

  thisEntity:SetContextThink( "TwinThink", partial(TwinThink, thisEntity) , 1)
  print("Starting AI for " .. thisEntity:GetUnitName() .. " " .. thisEntity:GetEntityIndex())

  ABILITY_spawn_twin = thisEntity:FindAbilityByName("boss_twin_spawn_twin")
  ABILITY_empathy = thisEntity:FindAbilityByName("boss_twin_twin_empathy")

  local phaseController = thisEntity:AddNewModifier(thisEntity, ABILITY_empathy, "modifier_boss_phase_controller", {})
  phaseController:SetPhases({ 75, 50 })
  phaseController:SetAbilities({
    "boss_twin_twin_empathy"
  })
end

function TwinThink()
  ExecuteOrderFromTable({
    UnitIndex = thisEntity:entindex(),
    OrderType = DOTA_UNIT_ORDER_CAST_POSITION,
    AbilityIndex = ABILITY_spawn_twin:entindex(), --Optional.  Only used when casting abilities
    Position = self:GetAbsOrigin(), --Optional.  Only used when targeting the ground
    Queue = 0 --Optional.  Used for queueing up abilities
  })
end

