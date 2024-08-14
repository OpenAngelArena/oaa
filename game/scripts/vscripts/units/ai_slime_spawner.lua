function Spawn( entityKeyValues )
  if not thisEntity or not IsServer() then
    return
  end

  thisEntity:SetContextThink( "SlimeSpawnerThink", SlimeSpawnerThink, 1 )
end

function SlimeSpawnerThink()
  if GameRules:State_Get() >= DOTA_GAMERULES_STATE_POST_GAME or not IsValidEntity(thisEntity) or not thisEntity:IsAlive() then
    return -1
  end

  if GameRules:IsGamePaused() then
    return 1
  end

  if not thisEntity.bInitialized then
    thisEntity.vInitialSpawnPos = thisEntity:GetAbsOrigin()
    thisEntity.BossTier = thisEntity.BossTier or 2
    local actualBoss = CreateUnitByName('npc_dota_boss_slime', thisEntity:GetAbsOrigin(), true, thisEntity, thisEntity, thisEntity:GetTeamNumber())
    actualBoss.BossTier = thisEntity.BossTier or 2
    actualBoss.Spawner = thisEntity
    for i = DOTA_ITEM_SLOT_1, DOTA_ITEM_SLOT_6 do
      local item = thisEntity:GetItemInSlot(i)
      if item then
        actualBoss:AddItemByName(item:GetName())
      end
    end
    thisEntity.bInitialized = true
  else
    -- Stop thinking
    return -1
  end
end

