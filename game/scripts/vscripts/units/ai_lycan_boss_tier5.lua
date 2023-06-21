
function Spawn( entityKeyValues )
	if thisEntity == nil then
		return
	end

	if IsServer() == false then
		return
	end

	thisEntity.LYCAN_BOSS_SUMMONED_UNITS = {}
	thisEntity.LYCAN_BOSS_MAX_SUMMONS = 50
	thisEntity.nCAST_SUMMON_WOLVES_COUNT = 0

	thisEntity.hSummonWolvesAbility = thisEntity:FindAbilityByName( "lycan_boss_summon_wolves_tier5" )
	thisEntity.hShapeshiftAbility = thisEntity:FindAbilityByName( "lycan_boss_shapeshift_tier5" )
	thisEntity.hClawLungeAbility = thisEntity:FindAbilityByName( "lycan_boss_claw_lunge_tier5" )
	thisEntity.hClawAttackAbility = thisEntity:FindAbilityByName( "lycan_boss_claw_attack_tier5" )
	thisEntity.hRuptureBallAbility = thisEntity:FindAbilityByName( "lycan_boss_rupture_ball_tier5" )

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
    thisEntity.BossTier = thisEntity.BossTier or 5
    thisEntity.fAgroRange = thisEntity:GetAcquisitionRange()
    thisEntity:SetIdleAcquire(false)
    thisEntity:SetAcquisitionRange(0)
    thisEntity.bInitialized = true
  end

  local aggro_hp_pct = 1 - ((thisEntity.BossTier * BOSS_AGRO_FACTOR) / thisEntity:GetMaxHealth())
  local hasDamageThreshold = thisEntity:GetHealth() / thisEntity:GetMaxHealth() < aggro_hp_pct
  local fDistanceToOrigin = ( thisEntity:GetOrigin() - thisEntity.vInitialSpawnPos ):Length2D()

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

  -- Tier 5 Lycan boss is slightly smarter than normal Lycan boss (ignores attack-immune units)
  local function FindNearestValidUnit(entity, unit_group)
    for i = 1, #unit_group do
      local enemy = unit_group[i]
      if enemy and not enemy:IsNull() then
        if enemy:IsAlive() and not enemy:IsAttackImmune() and not enemy:IsInvulnerable() and not enemy:IsOutOfGame() and not enemy:IsCourier() and (enemy:GetAbsOrigin() - entity.vInitialSpawnPos):Length2D() < 2*BOSS_LEASH_SIZE then
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
    if thisEntity.hClawLungeAbility and thisEntity.hClawLungeAbility:IsFullyCastable() and thisEntity.hClawLungeAbility:IsOwnersManaEnough() and not thisEntity:IsRooted() then
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
	ExecuteOrderFromTable({
		UnitIndex = thisEntity:entindex(),
		OrderType = DOTA_UNIT_ORDER_MOVE_TO_POSITION,
		Position = thisEntity.vInitialSpawnPos
  })
  return 6
end

function CastClawAttack( enemy )
  if enemy and not enemy:IsNull() then
    thisEntity:CastAbilityOnTarget( enemy, thisEntity.hClawAttackAbility, thisEntity:entindex() )
  end

  return 2
end

function CastClawLunge( enemy )
  if enemy and not enemy:IsNull() then
    ExecuteOrderFromTable({
      UnitIndex = thisEntity:entindex(),
      OrderType = DOTA_UNIT_ORDER_CAST_POSITION,
      AbilityIndex = thisEntity.hClawLungeAbility:entindex(),
      Position = enemy:GetOrigin(),
    })
  end

  return 0.5
end

function CastSummonWolves()
	ExecuteOrderFromTable({
		UnitIndex = thisEntity:entindex(),
		OrderType = DOTA_UNIT_ORDER_CAST_NO_TARGET,
		AbilityIndex = thisEntity.hSummonWolvesAbility:entindex(),
	})

	return 0.6
end

function CastShapeshift()
	ExecuteOrderFromTable({
		UnitIndex = thisEntity:entindex(),
		OrderType = DOTA_UNIT_ORDER_CAST_NO_TARGET,
		AbilityIndex = thisEntity.hShapeshiftAbility:entindex(),
	})

	return 1
end

function CastRuptureBall( unit )
  if unit and not unit:IsNull() then
    ExecuteOrderFromTable({
      UnitIndex = thisEntity:entindex(),
      OrderType = DOTA_UNIT_ORDER_CAST_POSITION,
      AbilityIndex = thisEntity.hRuptureBallAbility:entindex(),
      Position = unit:GetOrigin(),
      Queue = false,
    })
  end

  return 1
end
