LinkLuaModifier( "modifier_boss_phase_controller", "modifiers/modifier_boss_phase_controller", LUA_MODIFIER_MOTION_NONE )

local ABILITY_empathy = nil

local function SpawnDumbTwin()
  local twin = CreateUnitByName("npc_dota_boss_twin_dumb_tier5", thisEntity:GetAbsOrigin(), true, thisEntity, thisEntity:GetOwner(), thisEntity:GetTeam())
  twin:AddNewModifier(thisEntity, ABILITY_empathy, "modifier_boss_twin_twin_empathy_buff", {})
end

function Spawn (entityKeyValues) --luacheck: ignore Spawn
  thisEntity:SetContextThink( "SpawnDumbTwin", partial(SpawnDumbTwin, thisEntity) , 1)
  print("Starting AI for tier 5 " .. thisEntity:GetUnitName() .. " " .. thisEntity:GetEntityIndex())

  ABILITY_empathy = thisEntity:FindAbilityByName("boss_twin_twin_empathy")

  local phaseController = thisEntity:AddNewModifier(thisEntity, ABILITY_empathy, "modifier_boss_phase_controller", {})
  phaseController:SetPhases({ 75, 50 })
  phaseController:SetAbilities({
    "boss_twin_twin_empathy"
  })
end
