function Spawn( kv )
	if not IsServer() then
		return
	end

	if thisEntity == nil then
		return
	end
	thisEntity.bForceKill = false
  print("npc_dota_creature_slime_spawner thinker STARTED!")
	thisEntity:SetContextThink( "SlimeSpawnerThink", SlimeSpawnerThink, 1 )
end

function SlimeSpawnerThink()
	if not thisEntity.bInitialized then
		thisEntity.vInitialSpawnPos = thisEntity:GetOrigin()
		thisEntity.bInitialized = true
	end

	if thisEntity.bForceKill then
    print("npc_dota_creature_slime_spawner bForceKill")
		-- Triggers boss reward
		local hAttackerHero = EntIndexToHScript( thisEntity.KillValues.entindex_attacker )
		thisEntity:Kill(nil, hAttackerHero)
		return -1
	end

	local function SetClones(clone1, clone2)
    print("npc_dota_creature_slime_spawner SetClones Called")
    print("clone1 = " .. clone1:entindex())
    print("clone2 = " .. clone2:entindex())
    print("parent = " .. thisEntity:entindex())
    print("bossHandle1 = " .. thisEntity.bossHandle1:entindex())
		thisEntity.clone1 = clone1
		thisEntity.clone2 = clone2
		clone1:OnDeath(OnBossKill)
		clone2:OnDeath(OnBossKill)
    print("npc_dota_creature_slime_spawner SetClones FINISH")
	end

	thisEntity.bossHandle1 = CreateUnitByName('npc_dota_boss_slime', thisEntity:GetAbsOrigin(), true, nil, nil, DOTA_TEAM_NEUTRALS)
	thisEntity.bossHandle1.BossTier = thisEntity.BossTier
	thisEntity.bossHandle1.SetClones = SetClones

	for i = DOTA_ITEM_SLOT_1, DOTA_ITEM_SLOT_6 do
		local item = thisEntity:GetItemInSlot(i)
		if item ~= nil then
			thisEntity.bossHandle1:AddItemByName( item:GetName() )
		end
	end

	return -1
end

function OnBossKill(kv)
  print("npc_dota_creature_slime_spawner OnBossKill Called")
  if not IsValidEntity(thisEntity.clone1) then print("not IsValidEntity(thisEntity.clone1)") end
  if not thisEntity.clone1:IsNull() and not thisEntity.clone1:IsAlive() then print("not thisEntity.clone1:IsAlive()") end
  if not IsValidEntity(thisEntity.clone2) then print("not IsValidEntity(thisEntity.clone2)") end
  if not thisEntity.clone2:IsNull() and not thisEntity.clone2:IsAlive() then print("not thisEntity.clone2:IsAlive()") end


	if (not IsValidEntity(thisEntity.clone1) or not thisEntity.clone1:IsAlive()) and
		(not IsValidEntity(thisEntity.clone2) or not thisEntity.clone2:IsAlive()) then
		-- Calling Kill or ForceKill from this handler does not work
		thisEntity.KillValues = kv
		thisEntity.bForceKill = true
		thisEntity:SetContextThink( "SlimeSpawnerThink", SlimeSpawnerThink, 0.1 )
	end
end
