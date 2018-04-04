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
	end

	local enemies = FindUnitsInRadius(
		thisEntity:GetTeamNumber(),
		thisEntity:GetOrigin(), nil,
		1000,
		DOTA_UNIT_TARGET_TEAM_ENEMY,
		DOTA_UNIT_TARGET_HERO,
		DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES + DOTA_UNIT_TARGET_FLAG_FOW_VISIBLE,
		FIND_CLOSEST,
		false
	)

	if #enemies == 0 then
		return RetreatHome()
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
	local frontSwipeEnemies = FindUnitsInCone(
		thisEntity:GetAbsOrigin(),
		thisEntity:GetForwardVector(),
		swipeRange,
		swipeRange*2,
		thisEntity:GetTeamNumber(),
		DOTA_UNIT_TARGET_TEAM_ENEMY,
		DOTA_UNIT_TARGET_ALL,
		DOTA_UNIT_TARGET_FLAG_NONE,
		FIND_CLOSEST)

	if thisEntity.hFrontswipeAbility:IsCooldownReady() and #frontSwipeEnemies > 0 then
		return CastFrontswipe()
	end

	-- Thrust

	local thrustRange = thisEntity.hThrustAbility:GetSpecialValueFor("range")
	local thrustWidth = thisEntity.hThrustAbility:GetSpecialValueFor("width")
	local thrustMinRange = thisEntity.hThrustAbility:GetSpecialValueFor("target_min_range")
	local thrustTarget
	local thrustCount = 0
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

	if thisEntity.hThrustAbility:IsCooldownReady() and thrustTarget then
		return CastThrust( thrustTarget )
	end

	-- Reaper's Rush

	local reapersMinRange = thisEntity.hReapersRushAbility:GetSpecialValueFor("min_range")
	local reapersMaxRange = thisEntity.hReapersRushAbility:GetSpecialValueFor("max_range")
	local reapersRushRadius = thisEntity.hReapersRushAbility:GetSpecialValueFor("radius")
	local reapersRushTarget
	local reapersRushCount = 0
	for k,v in pairs(enemies) do
		local d = (v:GetAbsOrigin() - thisEntity:GetAbsOrigin()):Length2D()
		if d < reapersMaxRange and d > reapersMinRange then
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
				reapersRushCount = #closeEnemies
				reapersRushTarget = v
			end
		end
	end

	if thisEntity.hReapersRushAbility:IsCooldownReady() and reapersRushCount > 0 and reapersRushTarget and canUseRush then
		return CastReapersRush( reapersRushTarget:GetAbsOrigin() )
	end

	if reapersRushTarget and thisEntity:IsIdle() then
		ExecuteOrderFromTable({
			UnitIndex = thisEntity:entindex(),
			OrderType = DOTA_UNIT_ORDER_MOVE_TO_TARGET,
			TargetIndex = reapersRushTarget:entindex()
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

	return 6
end

function CastFrontswipe( )
	ExecuteOrderFromTable({
		UnitIndex = thisEntity:entindex(),
		OrderType = DOTA_UNIT_ORDER_CAST_NO_TARGET,
		AbilityIndex = thisEntity.hFrontswipeAbility:entindex(),
	})

	local delay = thisEntity.hFrontswipeAbility:GetCastPoint() + 1.0

	if math.random(1,4) == 1 then
		-- thisEntity.hFrontswipeAbility:StartCooldown(8.0)

		Timers:CreateTimer(delay + 1.0, function (  )
			thisEntity.hFrontswipeAbility:StartCooldown(8.0)
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