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
	end

	if (thisEntity.vInitialSpawnPos - thisEntity:GetAbsOrigin()):Length() >= BOSS_LEASH_SIZE then
		return RetreatHome()
	end

	-- local enemies = FindUnitsInRadius(
	-- 	thisEntity:GetTeamNumber(),
	-- 	thisEntity:GetOrigin(), nil,
	-- 	1000,
	-- 	DOTA_UNIT_TARGET_TEAM_ENEMY,
	-- 	DOTA_UNIT_TARGET_HERO,
	-- 	DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES + DOTA_UNIT_TARGET_FLAG_FOW_VISIBLE,
	-- 	FIND_CLOSEST,
	-- 	false
	-- )

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