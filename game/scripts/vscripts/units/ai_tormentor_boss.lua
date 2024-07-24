
function Spawn( entityKeyValues )
  if not thisEntity or not IsServer() then
    return
  end

  thisEntity:SetContextThink( "TormentorBossThink", TormentorBossThink, 1 )
end

function TormentorBossThink()
  if GameRules:State_Get() >= DOTA_GAMERULES_STATE_POST_GAME or not IsValidEntity(thisEntity) or not thisEntity:IsAlive() then
    return -1
  end

  if GameRules:IsGamePaused() then
    return 1
  end

  if not thisEntity.initialized then
    thisEntity.spawn_position = thisEntity:GetAbsOrigin()
    thisEntity.BossTier = thisEntity.BossTier or 2
    -- Determine the team it belongs to based on distance
    local team = DOTA_TEAM_GOODGUYS
    if DistanceFromFountainOAA(thisEntity.spawn_position, DOTA_TEAM_GOODGUYS) > DistanceFromFountainOAA(thisEntity.spawn_position, DOTA_TEAM_BADGUYS) then
      team = DOTA_TEAM_BADGUYS
    end
    if team == DOTA_TEAM_BADGUYS then
      thisEntity:SetMaterialGroup("1")
    end
    thisEntity.tormentorTeam = team
    thisEntity.initialized = true
  end

  -- Check if the boss was messed around with displacing abilities (Force Staff for example)
  if (thisEntity.spawn_position - thisEntity:GetAbsOrigin()):Length2D() > 10 then
    thisEntity:SetAbsOrigin(thisEntity.spawn_position)
    thisEntity:AddNewModifier(thisEntity, nil, "modifier_phased", {duration = FrameTime()})
  end

  return 1
end
