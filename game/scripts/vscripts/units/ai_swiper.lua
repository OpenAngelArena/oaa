require('abilities/boss/swiper/boss_swiper_swipe')

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
	if GameRules:State_Get() >= DOTA_GAMERULES_STATE_POST_GAME or not IsValidEntity(thisEntity) or not thisEntity:IsAlive() then
    return -1
  end

  if GameRules:IsGamePaused() then
    return 1
  end

  if not thisEntity.bInitialized then
    thisEntity.vInitialSpawnPos = thisEntity:GetOrigin()
    thisEntity.bHasAgro = false
    thisEntity.BossTier = thisEntity.BossTier or 2
    thisEntity.SiltBreakerProtection = true
    thisEntity.fAgroRange = thisEntity:GetAcquisitionRange()
    thisEntity:SetIdleAcquire(false)
    thisEntity:SetAcquisitionRange(0)
    thisEntity.bInitialized = true
  end

	local enemies = FindUnitsInRadius(
		thisEntity:GetTeamNumber(),
		thisEntity:GetOrigin(), nil,
		1000,
		DOTA_UNIT_TARGET_TEAM_ENEMY,
		DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
		DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES,
		FIND_CLOSEST,
		false
	)

	local hasDamageThreshold = thisEntity:GetMaxHealth() - thisEntity:GetHealth() > thisEntity.BossTier * BOSS_AGRO_FACTOR
	local fDistanceToOrigin = ( thisEntity:GetOrigin() - thisEntity.vInitialSpawnPos ):Length2D()

  -- Remove debuff protection that was added during retreat
  thisEntity:RemoveModifierByName("modifier_anti_stun_oaa")

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

	if thisEntity:GetHealth() / thisEntity:GetMaxHealth() > 0.75 then -- phase 1
		canUseRush = false
	elseif thisEntity:GetHealth() / thisEntity:GetMaxHealth() > 0.5 then -- phase 2
		canUseRush = true
	end

	-- Swipe
	local swipeRange = thisEntity.hFrontswipeAbility:GetCastRange(thisEntity:GetAbsOrigin(), thisEntity)

	if thisEntity.hFrontswipeAbility:IsCooldownReady() then
		local frontSwipeEnemies = FindUnitsInRadius(
			thisEntity:GetTeamNumber(),
			thisEntity:GetOrigin(), nil,
			swipeRange,
			DOTA_UNIT_TARGET_TEAM_ENEMY,
			DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
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
          DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES
        )

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
      v:GetOrigin(),
      nil,
      reapersRushRadius,
      DOTA_UNIT_TARGET_TEAM_ENEMY,
      DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
      DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES + DOTA_UNIT_TARGET_FLAG_FOW_VISIBLE,
      FIND_CLOSEST,
      false
    )

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
      TargetIndex = moveToTarget:entindex(),
      Queue = false,
    })
  end

  return 0.5
end

function RetreatHome()
  -- Add Debuff Protection when leashing
  thisEntity:AddNewModifier(thisEntity, nil, "modifier_anti_stun_oaa", {})

  -- Leash
  ExecuteOrderFromTable({
    UnitIndex = thisEntity:entindex(),
    OrderType = DOTA_UNIT_ORDER_MOVE_TO_POSITION,
    Position = thisEntity.vInitialSpawnPos,
    Queue = false,
  })

  local speed = thisEntity:GetIdealSpeed()
  local location = thisEntity:GetAbsOrigin()
  local distance = (location - thisEntity.vInitialSpawnPos):Length2D()
  local retreat_time = distance / speed

  return retreat_time + 0.1
end

function CastFrontswipe( position )
  thisEntity:DispelWeirdDebuffs()

  local ability = thisEntity.hFrontswipeAbility
  local cast_point = ability:GetCastPoint()

  ExecuteOrderFromTable({
    UnitIndex = thisEntity:entindex(),
    OrderType = DOTA_UNIT_ORDER_CAST_POSITION,
    AbilityIndex = ability:entindex(),
    Position = position,
    Queue = false,
  })

  local delay = cast_point + 1.0

  -- Chance for backswipe: Why is this a thing?
  if RandomInt(1,4) == 1 then
    Timers:CreateTimer(delay - 0.9, function (  )
      if not IsValidEntity(thisEntity) or not thisEntity:IsAlive() then return end
      ability:StartCooldown(ability:GetCooldownTime() * 2)
      thisEntity:Stop()
      ExecuteOrderFromTable({
        UnitIndex = thisEntity:entindex(),
        OrderType = DOTA_UNIT_ORDER_CAST_NO_TARGET,
        AbilityIndex = thisEntity.hBackswipeAbility:entindex(),
        Queue = false,
      })
    end)

    return delay * 2
  else
    return delay
  end
end

function CastThrust( position )
  thisEntity:DispelWeirdDebuffs()

  local ability = thisEntity.hThrustAbility
  local cast_point = ability:GetCastPoint()

  ExecuteOrderFromTable({
    UnitIndex = thisEntity:entindex(),
    OrderType = DOTA_UNIT_ORDER_CAST_POSITION,
    AbilityIndex = ability:entindex(),
    Position = position,
    Queue = false,
  })

  return cast_point + 1.0
end

function CastReapersRush( position )
  thisEntity:DispelWeirdDebuffs()

  local ability = thisEntity.hReapersRushAbility
  local cast_point = ability:GetCastPoint()

  ExecuteOrderFromTable({
    UnitIndex = thisEntity:entindex(),
    OrderType = DOTA_UNIT_ORDER_CAST_POSITION,
    AbilityIndex = ability:entindex(),
    Position = position,
    Queue = false,
  })

  return cast_point + 1.0
end
