
function SpawnDumbTwin()
  local twin = CreateUnitByName("npc_dota_boss_twin_dumb", thisEntity.twin_dumb_position, true, thisEntity, thisEntity:GetOwner(), thisEntity:GetTeam())
  twin:AddNewModifier(thisEntity, thisEntity.ABILITY_empathy, "modifier_boss_twin_twin_empathy_buff", {})
end

function Spawn (entityKeyValues) --luacheck: ignore Spawn
  if not thisEntity or not IsServer() then
    return
  end

  thisEntity.ABILITY_empathy = thisEntity:FindAbilityByName("boss_twin_twin_empathy")

  thisEntity:SetContextThink( "TwinThink", TwinThink , 1)
  --print("Starting AI for " .. thisEntity:GetUnitName() .. " " .. thisEntity:GetEntityIndex())
end

function TwinThink()
  if GameRules:State_Get() >= DOTA_GAMERULES_STATE_POST_GAME or not IsValidEntity(thisEntity) or not thisEntity:IsAlive() then
    return -1
  end

  if GameRules:IsGamePaused() then
    return 1
  end

  if not thisEntity.initialized then
    thisEntity.BossTier = thisEntity.BossTier or 2
    thisEntity.spawn_position = thisEntity:GetAbsOrigin()
    thisEntity.twin_position = thisEntity.spawn_position + Vector(-150, 0, 0)
    thisEntity.twin_dumb_position = thisEntity.spawn_position + Vector(150, 0, 0)
    thisEntity:SetAbsOrigin(thisEntity.twin_position)
    thisEntity:AddNewModifier(thisEntity, nil, "modifier_phased", {duration = FrameTime()})
    SpawnDumbTwin()
    local phaseController = thisEntity:AddNewModifier(thisEntity, thisEntity.ABILITY_empathy, "modifier_boss_phase_controller", {})
      phaseController:SetPhases({ 75, 50 })
      phaseController:SetAbilities({
        "boss_twin_twin_empathy"
      })
    thisEntity.initialized = true
  end
end
