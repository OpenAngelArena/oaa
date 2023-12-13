local ABILITY_empathy = nil

function SpawnDumbTwin()
  local twin = CreateUnitByName("npc_dota_boss_twin_dumb_tier5", thisEntity:GetAbsOrigin(), true, thisEntity, thisEntity:GetOwner(), thisEntity:GetTeam())
  twin:AddNewModifier(thisEntity, ABILITY_empathy, "modifier_boss_twin_twin_empathy_buff", {})
end

function Spawn (entityKeyValues) --luacheck: ignore Spawn
  if not thisEntity or not IsServer() then
    return
  end

  ABILITY_empathy = thisEntity:FindAbilityByName("boss_twin_twin_empathy")

  thisEntity:SetContextThink( "TwinThink", TwinThink , 1)
  print("Starting AI for " .. thisEntity:GetUnitName() .. " " .. thisEntity:GetEntityIndex())
end

function TwinThink()
	if GameRules:State_Get() >= DOTA_GAMERULES_STATE_POST_GAME or not IsValidEntity(thisEntity) or not thisEntity:IsAlive() then
		return -1
	end

	if GameRules:IsGamePaused() then
		return 1
	end

  if not thisEntity.initialized then
    thisEntity.BossTier = thisEntity.BossTier or 5
    SpawnDumbTwin()
    local phaseController = thisEntity:AddNewModifier(thisEntity, ABILITY_empathy, "modifier_boss_phase_controller", {})
      phaseController:SetPhases({ 75, 50 })
      phaseController:SetAbilities({
        "boss_twin_twin_empathy"
      })
    thisEntity.initialized = true
  end
end
