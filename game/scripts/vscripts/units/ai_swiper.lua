require('abilities/swiper/boss_swiper_swipe')

function Spawn( entityKeyValues )
	if thisEntity == nil then
		return
	end

	if IsServer() == false then
		return
	end

	thisEntity.hThrustAbility = thisEntity:FindAbilityByName( "boss_swiper_thrust" )
	thisEntity.hFrontswipeAbility = thisEntity:FindAbilityByName( "boss_swiper_frontswipe" )
	thisEntity.hBackswipeAbility = thisEntity:FindAbilityByName( "boss_swiper_backswipe" )
	thisEntity.hReapersRushAbility = thisEntity:FindAbilityByName( "boss_swiper_reapers_rush" )

	thisEntity.retreatDelay = 6.0

	thisEntity:SetContextThink( "SwiperBossThink", SwiperBossThink, 1 )
end

function SwiperBossThink()
	if GameRules:IsGamePaused() == true or GameRules:State_Get() == DOTA_GAMERULES_STATE_POST_GAME or thisEntity:IsAlive() == false then
		return 1
	end

	-- if not thisEntity:IsIdle() then
	-- 	return 1.0
	-- end

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
		DOTA_UNIT_TARGET_HERO,
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

	local canUseRush = true
	local canUseTeleport = false

	if thisEntity:GetHealth() / thisEntity:GetMaxHealth() > 0.75 then -- phase 1
		canUseRush = false
	elseif thisEntity:GetHealth() / thisEntity:GetMaxHealth() > 0.5 then -- phase 2
		canUseRush = true
	else
		canUseTeleport = true
	end

	-- canUseRush = true

	-- Swipe

	local swipeRange = thisEntity.hFrontswipeAbility:GetCastRange(thisEntity:GetAbsOrigin(), thisEntity)

	if thisEntity.hFrontswipeAbility:IsCooldownReady() then
		local frontSwipeEnemies = FindUnitsInRadius(
			thisEntity:GetTeamNumber(),
			thisEntity:GetOrigin(), nil,
			swipeRange,
			DOTA_UNIT_TARGET_TEAM_ENEMY,
			DOTA_UNIT_TARGET_HERO,
			DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES,
			FIND_CLOSEST,
			false
		)

		if #frontSwipeEnemies >= thisEntity.hFrontswipeAbility:GetSpecialValueFor("min_targets") then
			thisEntity:SetForwardVector((frontSwipeEnemies[1]:GetAbsOrigin() - thisEntity:GetAbsOrigin()):Normalized())
			return CastFrontswipe(frontSwipeEnemies[1]:GetAbsOrigin())
		end
	end

	-- Thrust

	local thrustRange = thisEntity.hThrustAbility:GetSpecialValueFor("range")
	local thrustWidth = thisEntity.hThrustAbility:GetSpecialValueFor("width")
	local thrustMinRange = thisEntity.hThrustAbility:GetSpecialValueFor("target_min_range")
	local thrustTarget
	local thrustCount = 0

	if thisEntity.hThrustAbility:IsCooldownReady() then
		for k,v in pairs(enemies) do
			local d = (v:GetAbsOrigin() - thisEntity:GetAbsOrigin()):Length2D()
			if d < thrustRange and d > thrustMinRange then
				local thrustEnemies = FindUnitsInLine(
					thisEntity:GetTeamNumber(),
					thisEntity:GetAbsOrigin(),
					v:GetAbsOrigin(),
					nil,
					thrustWidth,
					DOTA_UNIT_TARGET_TEAM_ENEMY,
					DOTA_UNIT_TARGET_ALL,
					DOTA_UNIT_TARGET_FLAG_NONE)

				if #thrustEnemies > thrustCount then
					thrustCount = #thrustEnemies
					thrustTarget = v:GetAbsOrigin()
				end
			end
		end

		if thrustTarget then
			return CastThrust( thrustTarget )
		end
	end

	-- Reaper's Rush

	local reapersMinRange = thisEntity.hReapersRushAbility:GetSpecialValueFor("min_range")
	local reapersMaxRange = thisEntity.hReapersRushAbility:GetSpecialValueFor("max_range")
	local reapersRushRadius = thisEntity.hReapersRushAbility:GetSpecialValueFor("radius")
	local reapersRushTarget
	local moveToTarget
	local reapersRushCount = 0
	for k,v in pairs(enemies) do
		local d = (v:GetAbsOrigin() - thisEntity:GetAbsOrigin()):Length2D()
		local closeEnemies = FindUnitsInRadius(
			thisEntity:GetTeamNumber(),
			v:GetOrigin(), nil,
			reapersRushRadius,
			DOTA_UNIT_TARGET_TEAM_ENEMY,
			DOTA_UNIT_TARGET_HERO,
			DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES + DOTA_UNIT_TARGET_FLAG_FOW_VISIBLE,
			FIND_CLOSEST,
			false)

		if #closeEnemies > reapersRushCount then
			if d < reapersMaxRange and d > reapersMinRange then
				reapersRushCount = #closeEnemies
				reapersRushTarget = v
			end
			moveToTarget = v
		end
	end

	if thisEntity.hReapersRushAbility:IsCooldownReady() and reapersRushCount > 0 and reapersRushTarget and canUseRush then
		return CastReapersRush( reapersRushTarget:GetAbsOrigin() )
	end

	if moveToTarget and thisEntity:IsIdle() then
		ExecuteOrderFromTable({
			UnitIndex = thisEntity:entindex(),
			OrderType = DOTA_UNIT_ORDER_MOVE_TO_TARGET,
			TargetIndex = moveToTarget:entindex()
		})
	end

	return 0.5
end


function RetreatHome()
	ExecuteOrderFromTable({
		UnitIndex = thisEntity:entindex(),
		OrderType = DOTA_UNIT_ORDER_MOVE_TO_POSITION,
		Position = thisEntity.vInitialSpawnPos
	})

	return thisEntity.retreatDelay
end

function CastFrontswipe( position )
	ExecuteOrderFromTable({
		UnitIndex = thisEntity:entindex(),
		OrderType = DOTA_UNIT_ORDER_CAST_POSITION,
		AbilityIndex = thisEntity.hFrontswipeAbility:entindex(),
		Position = position
	})

	local delay = thisEntity.hFrontswipeAbility:GetCastPoint() + 1.0

	if RandomInt(1,4) == 1 then
		-- thisEntity.hFrontswipeAbility:StartCooldown(8.0)
		Timers:CreateTimer(delay - 0.9, function (  )
			if not IsValidEntity(thisEntity) or not thisEntity:IsAlive() then return end
			thisEntity.hFrontswipeAbility:StartCooldown(thisEntity.hFrontswipeAbility:GetCooldownTime() * 2)
			thisEntity:Stop()
			ExecuteOrderFromTable({
				UnitIndex = thisEntity:entindex(),
				OrderType = DOTA_UNIT_ORDER_CAST_NO_TARGET,
				AbilityIndex = thisEntity.hBackswipeAbility:entindex(),
			})
		end)

		return delay * 2
	else
		return delay
	end
end

function CastThrust( position )
	ExecuteOrderFromTable({
		UnitIndex = thisEntity:entindex(),
		OrderType = DOTA_UNIT_ORDER_CAST_POSITION,
		AbilityIndex = thisEntity.hThrustAbility:entindex(),
		Position = position,
	})

	return thisEntity.hThrustAbility:GetCastPoint() + 1.0
end

function CastReapersRush( position )
	ExecuteOrderFromTable({
		UnitIndex = thisEntity:entindex(),
		OrderType = DOTA_UNIT_ORDER_CAST_POSITION,
		AbilityIndex = thisEntity.hReapersRushAbility:entindex(),
		Position = position,
	})

	return thisEntity.hReapersRushAbility:GetCastPoint() + 1.0
end
