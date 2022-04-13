
function Spawn( entityKeyValues )
	if not thisEntity or not IsServer() then
		return
	end

	thisEntity.QuillAttack = thisEntity:FindAbilityByName( "ranged_quill_attack" )
	thisEntity:SetContextThink( "DireHoundBossThink", DireHoundBossThink, 1 )
end

function DireHoundBossThink()
  if not IsValidEntity(thisEntity) or not thisEntity:IsAlive() or thisEntity:IsDominated() then
		return -1
  end

	if GameRules:IsGamePaused() then
		return 1
  end

  if not thisEntity.bInitialized then
		thisEntity.vInitialSpawnPos = thisEntity:GetOrigin()
    thisEntity.bInitialized = true
  end

  local function IsNonHostileWard(entity)
    if entity.HasModifier then
      return entity:HasModifier("modifier_item_buff_ward") or entity:HasModifier("modifier_ward_invisibility")
    end
    return false
  end

  local function IsAttackable(entity)
    if entity:IsBaseNPC() then
      return entity:IsAlive() and not entity:IsAttackImmune() and not entity:IsInvulnerable() and not entity:IsOutOfGame() and not IsNonHostileWard(entity) and not entity:IsCourier()
    end
    return false
  end

  local fDistanceToOrigin = ( thisEntity:GetOrigin() - thisEntity.vInitialSpawnPos ):Length2D()

  if fDistanceToOrigin > 2000 then
    if fDistanceToOrigin > 10 then
      return RetreatHome()
    end
    return 1
	end

	local enemies = FindUnitsInRadius( thisEntity:GetTeamNumber(), thisEntity:GetOrigin(), nil, 1250, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES + DOTA_UNIT_TARGET_FLAG_FOW_VISIBLE, FIND_CLOSEST, false )
	if #enemies == 0 then
		return 1
	end

	local hAttackTarget = nil
	local hApproachTarget = nil
	for _, enemy in pairs( enemies ) do
		if enemy ~= nil and enemy:IsAlive() and IsAttackable(enemy) then
			local flDist = ( enemy:GetOrigin() - thisEntity:GetOrigin() ):Length2D()
			if flDist < 400 then
				return Retreat( enemy )
			end
			if flDist <= 800 then
				hAttackTarget = enemy
			end
			if flDist > 800 then
				hApproachTarget = enemy
			end
		end
	end

	if not hAttackTarget and hApproachTarget then
		return Approach( hApproachTarget )
	end

	if thisEntity.QuillAttack:IsCooldownReady() and IsAttackable(hAttackTarget) then
		return Attack( hAttackTarget )
	end

	if hAttackTarget then
    thisEntity:FaceTowards( hAttackTarget:GetOrigin() )
  end

	return 0.5
end

function Attack(unit)
	thisEntity.bMoving = false

	thisEntity:AddNewModifier( thisEntity, nil, "modifier_provide_vision", { duration = 1.1 } )

	ExecuteOrderFromTable({
		UnitIndex = thisEntity:entindex(),
		OrderType = DOTA_UNIT_ORDER_CAST_POSITION,
		AbilityIndex = thisEntity.QuillAttack:entindex(),
		Position = unit:GetOrigin(),
		Queue = false,
	})
	return 1
end

function Approach(unit)
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

function Retreat(unit)
	thisEntity.bMoving = true

	local vAwayFromEnemy = thisEntity:GetOrigin() - unit:GetOrigin()
	vAwayFromEnemy = vAwayFromEnemy:Normalized()

	ExecuteOrderFromTable({
		UnitIndex = thisEntity:entindex(),
		OrderType = DOTA_UNIT_ORDER_MOVE_TO_POSITION,
		Position = thisEntity:GetOrigin() + vAwayFromEnemy * thisEntity:GetIdealSpeed()
	})
	return 1.25
end

function RetreatHome()
  ExecuteOrderFromTable({
    UnitIndex = thisEntity:entindex(),
    OrderType = DOTA_UNIT_ORDER_MOVE_TO_POSITION,
    Position = thisEntity.vInitialSpawnPos
  })
  return 6
end
