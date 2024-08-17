
function Spawn( entityKeyValues )
  if not thisEntity or not IsServer() then
    return
  end

  thisEntity.LYCAN_BOSS_SUMMONED_UNITS = {}
  thisEntity.LYCAN_BOSS_MAX_SUMMONS = 50
  thisEntity.nCAST_SUMMON_WOLVES_COUNT = 0

  thisEntity.hSummonWolvesAbility = thisEntity:FindAbilityByName( "lycan_boss_summon_wolves" ) or thisEntity:FindAbilityByName( "lycan_boss_summon_wolves_tier5" )
  thisEntity.hShapeshiftAbility = thisEntity:FindAbilityByName( "lycan_boss_shapeshift" ) or thisEntity:FindAbilityByName( "lycan_boss_shapeshift_tier5" )
  thisEntity.hClawLungeAbility = thisEntity:FindAbilityByName( "lycan_boss_claw_lunge" ) or thisEntity:FindAbilityByName( "lycan_boss_claw_lunge_tier5" )
  thisEntity.hClawAttackAbility = thisEntity:FindAbilityByName( "lycan_boss_claw_attack" ) or thisEntity:FindAbilityByName( "lycan_boss_claw_attack_tier5" )
  thisEntity.hRuptureBallAbility = thisEntity:FindAbilityByName( "lycan_boss_rupture_ball" ) or thisEntity:FindAbilityByName( "lycan_boss_rupture_ball_tier5" )

  thisEntity:SetContextThink( "LycanBossThink", LycanBossThink, 1 )
end

function LycanBossThink()
  if GameRules:State_Get() >= DOTA_GAMERULES_STATE_POST_GAME or not IsValidEntity(thisEntity) or not thisEntity:IsAlive() then
    return -1
  end

  if GameRules:IsGamePaused() then
    return 1
  end

  if not thisEntity.bInitialized then
    thisEntity.vInitialSpawnPos = thisEntity:GetOrigin()
    thisEntity.bHasAgro = false
    thisEntity.BossTier = thisEntity.BossTier or 3
    thisEntity.SiltBreakerProtection = true
    thisEntity.fAgroRange = thisEntity:GetAcquisitionRange()
    thisEntity:SetIdleAcquire(false)
    thisEntity:SetAcquisitionRange(0)
    thisEntity.bInitialized = true
  end

  local aggro_hp_pct = 1 - ((thisEntity.BossTier * BOSS_AGRO_FACTOR) / thisEntity:GetMaxHealth())
  local hasDamageThreshold = thisEntity:GetHealth() / thisEntity:GetMaxHealth() < aggro_hp_pct
  local fDistanceToOrigin = ( thisEntity:GetOrigin() - thisEntity.vInitialSpawnPos ):Length2D()

  -- Remove debuff protection that was added during retreat
  thisEntity:RemoveModifierByName("modifier_anti_stun_oaa")

  if hasDamageThreshold then
    if not thisEntity.bHasAgro then
      DebugPrint("Lycan Boss Agro")
      thisEntity.bHasAgro = true
      thisEntity:SetIdleAcquire(true)
      thisEntity:SetAcquisitionRange(thisEntity.fAgroRange)
    end
  else
    if fDistanceToOrigin > 10 then
      return RetreatHome()
    end
    return 1
  end

  local hEnemies = {}
  local snipers = {}
	-- Agro
  if thisEntity.bHasAgro then
    hEnemies = FindUnitsInRadius(
      thisEntity:GetTeamNumber(),
      thisEntity.vInitialSpawnPos,
      nil,
      thisEntity:GetCurrentVisionRange(),
      DOTA_UNIT_TARGET_TEAM_ENEMY,
      DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_HERO,
      DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES + DOTA_UNIT_TARGET_FLAG_FOW_VISIBLE,
      FIND_CLOSEST,
      false
    )
    if #hEnemies == 0 then
      -- Check for snipers out of vision
      snipers = FindUnitsInRadius(
        thisEntity:GetTeamNumber(),
        thisEntity.vInitialSpawnPos,
        nil,
        3*BOSS_LEASH_SIZE,
        DOTA_UNIT_TARGET_TEAM_ENEMY,
        DOTA_UNIT_TARGET_ALL,
        DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES + DOTA_UNIT_TARGET_FLAG_NO_INVIS,
        FIND_CLOSEST,
        false
      )
      if #snipers == 0 then
        DebugPrint("Lycan Boss Deagro")
        thisEntity.bHasAgro = false
        thisEntity:SetIdleAcquire(false)
        thisEntity:SetAcquisitionRange(0)
	  end
    end
  end

  -- Leash (lycan needs more leash because his abilities)
  if not thisEntity.bHasAgro or fDistanceToOrigin > 2000 then
    if fDistanceToOrigin > 10 then
      return RetreatHome()
    end
    return 1
  end

  -- Check that the children we have in our list are still valid
  for i, hSummonedUnit in ipairs( thisEntity.LYCAN_BOSS_SUMMONED_UNITS ) do
    if hSummonedUnit:IsNull() or (not hSummonedUnit:IsAlive()) then
      table.remove( thisEntity.LYCAN_BOSS_SUMMONED_UNITS, i )
    end
  end

  -- Have we hit our minion limit?
  if #thisEntity.LYCAN_BOSS_SUMMONED_UNITS < thisEntity.LYCAN_BOSS_MAX_SUMMONS then
    if thisEntity.hSummonWolvesAbility and thisEntity.hSummonWolvesAbility:IsFullyCastable() and thisEntity.hSummonWolvesAbility:IsOwnersManaEnough() then
      return CastSummonWolves()
    end
  end

  local function FindNearestValidUnit(entity, unit_group)
    for i = 1, #unit_group do
      local enemy = unit_group[i]
      if enemy and not enemy:IsNull() then
        if enemy:IsAlive() and not enemy:IsAttackImmune() and not enemy:IsInvulnerable() and not enemy:IsOutOfGame() and not enemy:IsOther() and not enemy:IsCourier() and (enemy:GetAbsOrigin() - entity.vInitialSpawnPos):Length2D() < 2*BOSS_LEASH_SIZE then
          return enemy
        end
      end
    end
    return nil
  end

  local valid_enemy
  if #hEnemies == 0 then
    valid_enemy = FindNearestValidUnit(thisEntity, snipers)
  else
    valid_enemy = hEnemies[RandomInt(1, #hEnemies)]
  end

  if not valid_enemy then
    if fDistanceToOrigin > 10 then
      return RetreatHome()
    end
  end

  thisEntity.bShapeshift = thisEntity:HasModifier("modifier_lycan_boss_shapeshift")
  if thisEntity.bShapeshift then
    if thisEntity.hClawLungeAbility and thisEntity.hClawLungeAbility:IsFullyCastable() and thisEntity.hClawLungeAbility:IsOwnersManaEnough() then
      return CastClawLunge(valid_enemy)
    end
  else
    if thisEntity:GetHealthPercent() < 50 then
      if thisEntity.hShapeshiftAbility and thisEntity.hShapeshiftAbility:IsFullyCastable() and thisEntity.hShapeshiftAbility:IsOwnersManaEnough() then
        return CastShapeshift()
      end
    end
  end

  if #hEnemies == 0 then
    if fDistanceToOrigin > 10 then
      return RetreatHome()
    end
  end

	local hRuptureTargets = { }
	for _, hEnemy in pairs( hEnemies ) do
		if hEnemy and hEnemy:IsAlive() then
			local flDist = ( hEnemy:GetOrigin() - thisEntity:GetOrigin() ):Length2D()
			if flDist > 500 then
				table.insert( hRuptureTargets, hEnemy )
			end
		end
	end

	-- Cast Rupture Ball on someone far away
	if thisEntity.hRuptureBallAbility and thisEntity.hRuptureBallAbility:IsFullyCastable() then
		if #hRuptureTargets > 0 then
			return CastRuptureBall( hRuptureTargets[ RandomInt( 1, #hRuptureTargets ) ] )
		end
	end

	if thisEntity.hClawAttackAbility and thisEntity.hClawAttackAbility:IsFullyCastable() then
		return CastClawAttack( hEnemies[ 1 ] )
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

function CastClawAttack( enemy )
  if enemy and not enemy:IsNull() then
    thisEntity:DispelWeirdDebuffs()

    local ability = thisEntity.hClawAttackAbility
    local cast_point = ability:GetCastPoint()
    local cooldown = ability:GetCooldown(-1)
    local stun_duration = ability:GetSpecialValueFor("stun_duration")

    thisEntity:CastAbilityOnTarget( enemy, ability, thisEntity:entindex() ) -- maybe wrong third argument, replace with ExecuteOrderFromTable?

    return math.max(cast_point + cooldown, stun_duration) + 0.1 -- old: 2, new: 1.92
  end

  return 0.5
end

function CastClawLunge( enemy )
  if enemy and not enemy:IsNull() then
    thisEntity:DispelWeirdDebuffs()

    local ability = thisEntity.hClawLungeAbility
    local cast_point = ability:GetCastPoint()
    local speed = ability:GetSpecialValueFor("lunge_speed")
    local distance = ability:GetSpecialValueFor("lunge_distance")

    ExecuteOrderFromTable({
      UnitIndex = thisEntity:entindex(),
      OrderType = DOTA_UNIT_ORDER_CAST_POSITION,
      AbilityIndex = ability:entindex(),
      Position = enemy:GetOrigin(),
      Queue = false,
    })

    if speed ~= 0 then
      return cast_point + distance / speed + 0.1
    else
      print("DIVISION BY 0: "..ability:GetAbilityName().." ABILITY HAS 0 for SPEED, check kv name")
      return cast_point + 0.1
    end
  end

  return 0.5
end

function CastSummonWolves()
  thisEntity:DispelWeirdDebuffs()

  local ability = thisEntity.hSummonWolvesAbility
  local cast_point = ability:GetCastPoint()

  ExecuteOrderFromTable({
    UnitIndex = thisEntity:entindex(),
    OrderType = DOTA_UNIT_ORDER_CAST_NO_TARGET,
    AbilityIndex = ability:entindex(),
    Queue = false,
  })

  return cast_point + 0.1
end

function CastShapeshift()
  thisEntity:DispelWeirdDebuffs()

  local ability = thisEntity.hShapeshiftAbility
  local cast_point = ability:GetCastPoint()
  local transformation_time = ability:GetSpecialValueFor("transformation_time")

  ExecuteOrderFromTable({
    UnitIndex = thisEntity:entindex(),
    OrderType = DOTA_UNIT_ORDER_CAST_NO_TARGET,
    AbilityIndex = ability:entindex(),
    Queue = false,
  })

  return cast_point + transformation_time + 0.1
end

function CastRuptureBall( unit )
  if unit and not unit:IsNull() then
    thisEntity:DispelWeirdDebuffs()

    local ability = thisEntity.hRuptureBallAbility
    local cast_point = ability:GetCastPoint()

    ExecuteOrderFromTable({
      UnitIndex = thisEntity:entindex(),
      OrderType = DOTA_UNIT_ORDER_CAST_POSITION,
      AbilityIndex = ability:entindex(),
      Position = unit:GetOrigin(),
      Queue = false,
    })

    return cast_point + 0.1
  end

  return 0.5
end
