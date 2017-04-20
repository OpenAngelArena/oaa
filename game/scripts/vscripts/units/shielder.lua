
LinkLuaModifier( "modifier_boss_phase_controller", "modifiers/modifier_boss_phase_controller", LUA_MODIFIER_MOTION_NONE )

function Spawn (entityKeyValues)
  thisEntity:FindAbilityByName("boss_shielder_shield")

  thisEntity:SetContextThink( "ShielderThink", partial(ShielderThink, thisEntity) , 1)
  print("Starting AI for " .. thisEntity:GetUnitName() .. " " .. thisEntity:GetEntityIndex())
  Timers:CreateTimer(1, thisEntity:OnHurt(HurtHandler(keys)))
  
  ABILITY_shield = thisEntity:FindAbilityByName("boss_shielder_shield")

  local phaseController = thisEntity:AddNewModifier(thisEntity, ABILITY_shield, "modifier_boss_phase_controller", {})
  phaseController:SetPhases({ 66, 33 })
  phaseController:SetAbilities({
    "boss_shielder_shield"
  })

  thisEntity:OnHurt(function (keys)
    HurtHandler(keys)
  end)
end

function ShielderThink (thisEntity)

end

function HurtHandler (keys)
  print("Ow that hurt")
end