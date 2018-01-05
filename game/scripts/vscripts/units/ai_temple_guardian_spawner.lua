function Spawn( kv )
	if not IsServer() then
		return
	end

	if thisEntity == nil then
		return
  end
  thisEntity.bForceKill = false

	thisEntity:SetContextThink( "TempleGuardianSpawnerThink", TempleGuardianSpawnerThink, 1 )
end

function TempleGuardianSpawnerThink()
  if not thisEntity.bInitialized then
		thisEntity.vInitialSpawnPos = thisEntity:GetOrigin()
    thisEntity.bInitialized = true
  end

  if thisEntity.bForceKill then
    -- Triggers boss reward
    local hAttackerHero = EntIndexToHScript( thisEntity.KillValues.entindex_attacker )
    thisEntity:Kill(nil, hAttackerHero)
    return -1
  end

  thisEntity.bossHandle1 = CreateUnitByName('npc_dota_creature_temple_guardian', thisEntity:GetAbsOrigin() +  Vector( 300, 0, 0 ), true, nil, nil, DOTA_TEAM_NEUTRALS)
  thisEntity.bossHandle2 = CreateUnitByName('npc_dota_creature_temple_guardian', thisEntity:GetAbsOrigin() -  Vector( 300, 0, 0 ), true, nil, nil, DOTA_TEAM_NEUTRALS)

  local heart = CreateItem("item_heart", thisEntity.bossHandle1, thisEntity.bossHandle1)
  thisEntity.bossHandle1:AddItem(thisEntity.bossHandle1)

  heart = CreateItem("item_heart", thisEntity.bossHandle2, thisEntity.bossHandle2)
  thisEntity.bossHandle2:AddItem(heart)

  thisEntity.bossHandle1.hBrother = thisEntity.bossHandle2
  thisEntity.bossHandle2.hBrother = thisEntity.bossHandle1

  thisEntity.bossHandle1:OnDeath(OnBossKill)
  thisEntity.bossHandle2:OnDeath(OnBossKill)

  return -1
end

function OnBossKill(kv)
  if (not IsValidEntity(thisEntity.bossHandle1) or not thisEntity.bossHandle1:IsAlive()) and
     (not IsValidEntity(thisEntity.bossHandle2) or not thisEntity.bossHandle2:IsAlive()) then

      -- Calling Kill or ForceKill from this handler does not work
      thisEntity.KillValues = kv
      thisEntity.bForceKill = true
	    thisEntity:SetContextThink( "TempleGuardianSpawnerThink", TempleGuardianSpawnerThink, 0.1 )
  end
end
