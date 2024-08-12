function Spawn( entityKeyValues )
	if not IsServer() then
		return
	end

	if thisEntity == nil then
		return
	end

	thisEntity.HowlAbility = thisEntity:FindAbilityByName("werewolf_howl")
	thisEntity:SetContextThink( "WerewolfThink", WerewolfThink, 1 )
end

function WerewolfThink()
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

  local fDistanceToOrigin = ( thisEntity:GetOrigin() - thisEntity.vInitialSpawnPos ):Length2D()

  if fDistanceToOrigin > 2000 then
    if fDistanceToOrigin > 10 then
      return RetreatHome()
    end
    return 1
  end

	if thisEntity.HowlAbility and thisEntity.HowlAbility:IsFullyCastable() then
    local ability = thisEntity.HowlAbility
    local radius = ability:GetSpecialValueFor("radius")
    local friendlies = FindUnitsInRadius(
      thisEntity:GetTeamNumber(),
      thisEntity:GetAbsOrigin(),
      nil,
      radius,
      DOTA_UNIT_TARGET_TEAM_FRIENDLY,
      DOTA_UNIT_TARGET_ALL,
      DOTA_UNIT_TARGET_FLAG_NONE,
      FIND_ANY_ORDER,
      false
    )
    if #friendlies > 1 then
      return Howl()
    end
	end

	return 0.5
end


function Howl()
  local ability = thisEntity.HowlAbility
  local cast_point = ability:GetCastPoint()

  ExecuteOrderFromTable({
    UnitIndex = thisEntity:entindex(),
    OrderType = DOTA_UNIT_ORDER_CAST_NO_TARGET,
    AbilityIndex = ability:entindex(),
    Queue = false,
  })

  return cast_point + 0.5
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
