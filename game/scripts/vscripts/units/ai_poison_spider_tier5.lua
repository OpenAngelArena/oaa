function Spawn( entityKeyValues )
	if thisEntity == nil then
		return
	end

	thisEntity.hPoisonSpit = thisEntity:FindAbilityByName( "spider_poison_spit_tier5" )
	thisEntity:SetContextThink( "PoisonSpiderThink", PoisonSpiderThink, 1 )
end

function PoisonSpiderThink()

	if ( not IsValidEntity(thisEntity) ) or ( not thisEntity:IsAlive()) or (thisEntity:IsDominated()) then
		return -1
	end

	if GameRules:IsGamePaused() == true then
		return 1
  end

  if not thisEntity.bInitialized then
		thisEntity.vInitialSpawnPos = thisEntity:GetOrigin()
    thisEntity.bInitialized = true
  end

  local fDistanceToOrigin = ( thisEntity:GetOrigin() - thisEntity.vInitialSpawnPos ):Length2D()

  if fDistanceToOrigin > 2000 then
    if fDistanceToOrigin > 10 then
      return RetreatHome()
    end
    return 1
  end

	local enemies = FindUnitsInRadius( thisEntity:GetTeamNumber(), thisEntity:GetOrigin(), nil, 1250, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES + DOTA_UNIT_TARGET_FLAG_FOW_VISIBLE, FIND_CLOSEST, false )
	if #enemies == 0 then
		return 1
  end


	local hPoisonSpitTarget = nil
	local hApproachTarget = nil
  for _,enemy in pairs( enemies ) do
		if enemy ~= nil and enemy:IsAlive() then
			local flDist = ( enemy:GetOrigin() - thisEntity:GetOrigin() ):Length2D()
			if flDist > 0 and flDist <= 600 then
				hPoisonSpitTarget = enemy
			end
			if flDist > 600 then
				hApproachTarget = enemy
			end
		end
	end

	if hPoisonSpitTarget == nil and hApproachTarget ~= nil then
		return Approach( hApproachTarget )
	end

	if hPoisonSpitTarget then
		if thisEntity.hPoisonSpit:IsFullyCastable() then
			return CastPoisonSpit( hPoisonSpitTarget )
		end

		thisEntity:FaceTowards( hPoisonSpitTarget:GetOrigin() )
	end

	return 0.5
end

function CastPoisonSpit( unit )
	thisEntity.bMoving = false

	ExecuteOrderFromTable({
		UnitIndex = thisEntity:entindex(),
		OrderType = DOTA_UNIT_ORDER_CAST_POSITION,
		AbilityIndex = thisEntity.hPoisonSpit:entindex(),
		Position = unit:GetOrigin(),
		Queue = false,
	})
	return 1
end

function Approach( unit )
	thisEntity.bMoving = true

	local vToEnemy = unit:GetOrigin() - thisEntity:GetOrigin()
	vToEnemy = vToEnemy:Normalized()

	ExecuteOrderFromTable({
		UnitIndex = thisEntity:entindex(),
		OrderType = DOTA_UNIT_ORDER_MOVE_TO_POSITION,
		Position = thisEntity:GetOrigin() + vToEnemy * thisEntity:GetIdealSpeed()
	})
	return 1
end

function RetreatHome()
	ExecuteOrderFromTable({
		UnitIndex = thisEntity:entindex(),
		OrderType = DOTA_UNIT_ORDER_MOVE_TO_POSITION,
		Position = thisEntity.vInitialSpawnPos
  })
  return 2
end



