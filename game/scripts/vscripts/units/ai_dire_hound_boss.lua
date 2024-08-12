
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

  local enemies = FindUnitsInRadius(
    thisEntity:GetTeamNumber(),
    thisEntity:GetOrigin(),
    nil,
    1200,
    DOTA_UNIT_TARGET_TEAM_ENEMY,
    DOTA_UNIT_TARGET_ALL,
    DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES + DOTA_UNIT_TARGET_FLAG_FOW_VISIBLE,
    FIND_CLOSEST,
    false
  )

  if #enemies == 0 or not thisEntity.QuillAttack then
    return 1
  end

  local attackDistance = thisEntity.QuillAttack:GetSpecialValueFor("attack_distance")
  local hAttackTarget
  local hApproachTarget
  for _, enemy in ipairs( enemies ) do
    if enemy and enemy:IsAlive() and IsAttackable(enemy) then
      local flDist = ( enemy:GetOrigin() - thisEntity:GetOrigin() ):Length2D()
      if flDist < attackDistance / 2 then
        return Retreat( enemy )
      elseif flDist <= attackDistance then
        hAttackTarget = enemy
      elseif flDist > attackDistance then
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

  -- Just face the enemy if not attackable or on cooldown
  if hAttackTarget then
    thisEntity:FaceTowards( hAttackTarget:GetOrigin() )
  end

  return 0.5
end

function Attack(unit)
  thisEntity.bMoving = false

  local ability = thisEntity.QuillAttack
  local cast_point = ability:GetCastPoint()
  local cooldown = ability:GetCooldown(-1)
  local think_time = math.max(cast_point, cooldown) + 0.1

  if not thisEntity:HasModifier( "modifier_provide_vision" ) then
    thisEntity:AddNewModifier( unit, nil, "modifier_provide_vision", { duration = think_time / 2 } )
  end

  ExecuteOrderFromTable({
    UnitIndex = thisEntity:entindex(),
    OrderType = DOTA_UNIT_ORDER_CAST_POSITION,
    AbilityIndex = ability:entindex(),
    Position = unit:GetOrigin(),
    Queue = false,
  })

  return think_time
end

function Approach(unit)
  thisEntity.bMoving = true

  local vToEnemy = unit:GetOrigin() - thisEntity:GetOrigin()
  vToEnemy = vToEnemy:Normalized()
  local speed = thisEntity:GetIdealSpeed()
  local think_time = 1
  local distance = speed * think_time

  ExecuteOrderFromTable({
    UnitIndex = thisEntity:entindex(),
    OrderType = DOTA_UNIT_ORDER_MOVE_TO_POSITION,
    Position = thisEntity:GetOrigin() + vToEnemy * distance,
    Queue = false,
  })

  return think_time
end

function Retreat(unit)
  thisEntity.bMoving = true

  local vAwayFromEnemy = thisEntity:GetOrigin() - unit:GetOrigin()
  vAwayFromEnemy = vAwayFromEnemy:Normalized()
  local speed = thisEntity:GetIdealSpeed()
  local travel_time = 1
  local turning_time = 0.25
  local distance = speed * travel_time

  ExecuteOrderFromTable({
    UnitIndex = thisEntity:entindex(),
    OrderType = DOTA_UNIT_ORDER_MOVE_TO_POSITION,
    Position = thisEntity:GetOrigin() + vAwayFromEnemy * distance,
    Queue = false,
  })

  return travel_time + turning_time
end

function RetreatHome()
  -- Leash
  ExecuteOrderFromTable({
    UnitIndex = thisEntity:entindex(),
    OrderType = DOTA_UNIT_ORDER_MOVE_TO_POSITION,
    Position = thisEntity.vInitialSpawnPos,
    Queue = false,
  })

  local speed = thisEntity:GetIdealSpeedNoSlows()
  local location = thisEntity:GetAbsOrigin()
  local distance = (location - thisEntity.vInitialSpawnPos):Length2D()
  local retreat_time = distance / speed

  return retreat_time + 0.1
end
