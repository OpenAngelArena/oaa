function Spawn( entityKeyValues )
	if thisEntity == nil then
		return
	end

	if IsServer() == false then
		return
	end

	thisEntity.hJumpAbility = thisEntity:FindAbilityByName( "boss_slime_jump" )
	thisEntity.hSlamAbility = thisEntity:FindAbilityByName( "boss_slime_slam" )
	thisEntity.hShakeAbility = thisEntity:FindAbilityByName( "boss_slime_shake" )

	thisEntity:SetContextThink( "SlimeBossThink", SlimeBossThink, 1 )
end

function SlimeBossThink()
	if GameRules:IsGamePaused() == true or GameRules:State_Get() == DOTA_GAMERULES_STATE_POST_GAME or thisEntity:IsAlive() == false then
		return 1
	end

	if thisEntity:IsChanneling() then
		return 2.0
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
		800,
		DOTA_UNIT_TARGET_TEAM_ENEMY,
		DOTA_UNIT_TARGET_HERO,
		DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES + DOTA_UNIT_TARGET_FLAG_FOW_VISIBLE,
		FIND_CLOSEST,
		false
	)

	local hasDamageThreshold = not thisEntity:HasAbility("boss_slime_split") or thisEntity:GetMaxHealth() - thisEntity:GetHealth() > (thisEntity.BossTier or 1) * BOSS_AGRO_FACTOR
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

	-- Slam

	if thisEntity.hSlamAbility and thisEntity.hSlamAbility:IsCooldownReady() then
		local target
		local count = 0
		for k,v in pairs(enemies) do
			local slamEnemies = thisEntity.hSlamAbility:FindTargets(v:GetAbsOrigin())
			if #slamEnemies > count and (thisEntity:GetAbsOrigin() - v:GetAbsOrigin()):Length2D() < BOSS_LEASH_SIZE then
				count = #slamEnemies
				target = v:GetAbsOrigin()
			end
		end

		if count > 0 and target then
			return CastSlam(target)
		end
	end

	-- Jump

	if thisEntity.hJumpAbility and thisEntity.hJumpAbility:IsCooldownReady() then
		local target
		local count = 0
		local targetMinRange = thisEntity.hJumpAbility:GetSpecialValueFor("target_min_range")
		for k,v in pairs(enemies) do
			local jumpEnemies = thisEntity.hJumpAbility:FindTargets(v:GetAbsOrigin())
			if #jumpEnemies > count
				and (thisEntity.vInitialSpawnPos - v:GetAbsOrigin()):Length2D() < BOSS_LEASH_SIZE
				and (thisEntity:GetAbsOrigin() - v:GetAbsOrigin()):Length2D() > targetMinRange then
				count = #jumpEnemies
				target = v:GetAbsOrigin()
			end
		end

		if count > 0 and target then
			return CastJump(target)
		end
	end

	return 0.5
end

function RetreatHome()
	ExecuteOrderFromTable({
		UnitIndex = thisEntity:entindex(),
		OrderType = DOTA_UNIT_ORDER_MOVE_TO_POSITION,
		Position = thisEntity.vInitialSpawnPos
	})

	return 1.0
end

function CastJump(position)
	ExecuteOrderFromTable({
		UnitIndex = thisEntity:entindex(),
		OrderType = DOTA_UNIT_ORDER_CAST_POSITION,
		AbilityIndex = thisEntity.hJumpAbility:entindex(),
		Position = position,
	})

	return thisEntity.hJumpAbility:GetCastPoint() + 5.0
end

function CastSlam( position )
	ExecuteOrderFromTable({
		UnitIndex = thisEntity:entindex(),
		OrderType = DOTA_UNIT_ORDER_CAST_POSITION,
		AbilityIndex = thisEntity.hSlamAbility:entindex(),
		Position = position,
	})

	return thisEntity.hSlamAbility:GetCastPoint() + thisEntity.hSlamAbility:GetSpecialValueFor("self_stun")
end