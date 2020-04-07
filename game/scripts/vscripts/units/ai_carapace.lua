function Spawn( entityKeyValues )
	if thisEntity == nil then
		return
	end

	if IsServer() == false then
		return
	end

	thisEntity.hHeadbuttAbility = thisEntity:FindAbilityByName( "boss_carapace_headbutt" )

	thisEntity:SetContextThink( "CarapaceBossThink", CarapaceBossThink, 1 )
end

function CarapaceBossThink()
	if GameRules:IsGamePaused() == true or GameRules:State_Get() == DOTA_GAMERULES_STATE_POST_GAME or thisEntity:IsAlive() == false then
		return 1
	end

	if thisEntity.hHeadbuttAbility:IsInAbilityPhase() then
		return 1
	end

	if not thisEntity.bInitialized then
		thisEntity.vInitialSpawnPos = thisEntity:GetOrigin()
		thisEntity.bInitialized = true
		thisEntity.bHasAgro = false
		thisEntity.fAgroRange = thisEntity:GetAcquisitionRange()
		thisEntity:SetIdleAcquire(false)
		thisEntity:SetAcquisitionRange(0)
	end

	local enemies = FindUnitsInRadius(
		thisEntity:GetTeamNumber(),
		thisEntity:GetOrigin(), nil,
		1000,
		DOTA_UNIT_TARGET_TEAM_ENEMY,
		bit.bor(DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_BASIC),
		DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES,
		FIND_CLOSEST,
		false
	)

	local hasDamageThreshold = thisEntity:GetMaxHealth() - thisEntity:GetHealth() > (thisEntity.BossTier or 1) * BOSS_AGRO_FACTOR
	local fDistanceToOrigin = ( thisEntity:GetOrigin() - thisEntity.vInitialSpawnPos ):Length2D()

	if (fDistanceToOrigin < 10 and thisEntity.bHasAgro and #enemies == 0) then
		thisEntity.bHasAgro = false
		thisEntity:SetIdleAcquire(false)
		thisEntity:SetAcquisitionRange(0)
		return 2
	elseif (hasDamageThreshold and #enemies > 0) then
		if not thisEntity.bHasAgro then
			thisEntity.bHasAgro = true
			thisEntity:SetIdleAcquire(true)
			thisEntity:SetAcquisitionRange(thisEntity.fAgroRange)
		end
	end

	if not thisEntity.bHasAgro or #enemies == 0 or fDistanceToOrigin > BOSS_LEASH_SIZE then
		if fDistanceToOrigin > 10 then
			return RetreatHome()
		end
		return 1
	end

	if thisEntity.hHeadbuttAbility and thisEntity.hHeadbuttAbility:IsCooldownReady() then
		local headbuttEnemies = thisEntity.hHeadbuttAbility:GetEnemies()

		if #headbuttEnemies > 0 then
			return CastHeadbutt()
		end
	end

	ExecuteOrderFromTable({
		UnitIndex = thisEntity:entindex(),
		OrderType = DOTA_UNIT_ORDER_ATTACK_MOVE,
		Position = thisEntity.vInitialSpawnPos + RandomVector(300),
		Queue = 0
	})

	return 2
end

function RetreatHome()
	ExecuteOrderFromTable({
		UnitIndex = thisEntity:entindex(),
		OrderType = DOTA_UNIT_ORDER_MOVE_TO_POSITION,
		Position = thisEntity.vInitialSpawnPos
	})

	return 5.0
end

function CastHeadbutt()
	thisEntity:Stop()
	ExecuteOrderFromTable({
		UnitIndex = thisEntity:entindex(),
		OrderType = DOTA_UNIT_ORDER_CAST_NO_TARGET,
		AbilityIndex = thisEntity.hHeadbuttAbility:entindex(),
	})

	return 4.0
end
