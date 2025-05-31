-- the range at which we consider outselves basically attacking them
local CLOSE_FOLLOW_RANGE = 300
-- range to follow (visible) enemies, targetting the closest first
-- a-walks towards them
local LONG_FOLLOW_RANGE = 1200
-- the max range away from the spot they were aggroed from where they should walk
-- when this leash limit is hit, the boss walks back to where they were aggroed originally
-- then follows long follow range
-- should be pretty high for stuff like sniper juggling
local MAX_LEASH_DISTANCE = 2000
-- the distance at which a returning boss will double back and keep attacking (unleash)
local MIN_LEASH_DISTANCE = 500

function Spawn( entityKeyValues )
  if not thisEntity or not IsServer() then
    return
  end

  thisEntity.hasSpawned = false
  thisEntity.BossTier = thisEntity.BossTier or 2

  thisEntity:SetContextThink("GrendelThink", GrendelThink, 1)
end

function GrendelThink ()
  if GameRules:State_Get() >= DOTA_GAMERULES_STATE_POST_GAME or not IsValidEntity(thisEntity) or not thisEntity:IsAlive() then
    return -1
  end

  if GameRules:IsGamePaused() then
    return 1
  end

  if Duels:IsActive() then
    thisEntity:Stop()
    return 1
  end

  if not thisEntity.hasSpawned then
    thisEntity.hasSpawned = true
    StartWandering()
    return 1
  end

  if Grendel.to_location ~= nil then
    -- Reset Grendel caller when Grendel reaches the location he was called from
    if (thisEntity:GetAbsOrigin() - Grendel.to_location):Length2D() < 200 then
      Grendel:GoNearTeam(nil)
    end
  end

  local hpPercent = thisEntity:GetHealth() / thisEntity:GetMaxHealth()

  if thisEntity.wandering then
    Wander()
  else
    if thisEntity:IsIdle() then
      thisEntity.wanderCountdown = thisEntity.wanderCountdown - 1
      -- Decrease wander cooldown if Grendel was called
      if Grendel.was_called then
        thisEntity.wanderCountdown = math.min(thisEntity.wanderCountdown, 5)
      end
    end
    if thisEntity.wanderCountdown < 0 then
      StartWandering()
    end
  end

  -- Aggroed if its health is below 95%
  local shouldAggro = hpPercent < 0.95

  -- Check if it is aggroed but it shouldn't be aggroed
  if thisEntity.isAggro and not shouldAggro then
    -- giving up on aggro
    thisEntity:Stop()
    WalkTowardsSpot(thisEntity.aggroOrigin)
    thisEntity.aggroOrigin = nil
    thisEntity.isLeashing = false
  end

  -- Check if it is not aggroed but it should be aggroed
  if not thisEntity.isAggro and shouldAggro then
    thisEntity:Stop()
    thisEntity.aggroOrigin = thisEntity:GetAbsOrigin()
  end

  -- end pre assign stuff

  thisEntity.isAggro = shouldAggro

  -- start post assign stuff

  -- Set aggro origin
  if thisEntity.isAggro and not thisEntity.aggroOrigin then
    thisEntity.aggroOrigin = thisEntity:GetAbsOrigin()
  end

  -- Leashing
  if thisEntity.aggroOrigin then
    local distanceFromOrigin = (thisEntity:GetAbsOrigin() - thisEntity.aggroOrigin):Length2D()
    local shouldLeash = distanceFromOrigin > MAX_LEASH_DISTANCE

    if thisEntity.isLeashing and distanceFromOrigin < MIN_LEASH_DISTANCE then
      thisEntity.isLeashing = false
    end

    if thisEntity.isLeashing or shouldLeash then
      if not thisEntity.isLeashing or thisEntity:IsIdle() then
        thisEntity:Stop()
        thisEntity.isLeashing = true
        WalkTowardsSpot(thisEntity.aggroOrigin)
      end
      return 1
    end
  end

  if not thisEntity.isAggro then
    --thisEntity:RemoveModifierByName("modifier_boss_regen_degen")
    thisEntity:SetIdleAcquire(false)
    thisEntity:SetAcquisitionRange(0)
  else
    local nearbyEnemies = FindUnitsInRadius(
      thisEntity:GetTeamNumber(),
      thisEntity:GetOrigin(),
      nil,
      CLOSE_FOLLOW_RANGE,
      DOTA_UNIT_TARGET_TEAM_ENEMY,
      DOTA_UNIT_TARGET_HERO,
      DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES + DOTA_UNIT_TARGET_FLAG_FOW_VISIBLE,
      FIND_CLOSEST,
      false
    )
    local enemies = FindUnitsInRadius(
      thisEntity:GetTeamNumber(),
      thisEntity:GetOrigin(),
      nil,
      LONG_FOLLOW_RANGE,
      DOTA_UNIT_TARGET_TEAM_ENEMY,
      DOTA_UNIT_TARGET_HERO,
      DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES + DOTA_UNIT_TARGET_FLAG_FOW_VISIBLE,
      FIND_CLOSEST,
      false
    )

    local nearestEnemy = nearbyEnemies[1]
    if #nearbyEnemies == 0 and #enemies > 0 then
      nearestEnemy = enemies[1]
    end

    --thisEntity:SetIdleAcquire(true)
    thisEntity:SetAcquisitionRange(128)

    if thisEntity:IsIdle() then
      if nearestEnemy then
        ExecuteOrderFromTable({
          UnitIndex = thisEntity:entindex(),
          -- OrderType = DOTA_UNIT_ORDER_ATTACK_TARGET,
          OrderType = DOTA_UNIT_ORDER_ATTACK_MOVE,
          Position = nearestEnemy:GetAbsOrigin(),
          Queue = false,
        })
        ExecuteOrderFromTable({
          UnitIndex = thisEntity:entindex(),
          -- OrderType = DOTA_UNIT_ORDER_ATTACK_TARGET,
          OrderType = DOTA_UNIT_ORDER_ATTACK_MOVE,
          Position = thisEntity.aggroOrigin,
          Queue = true,
        })
      else
        ExecuteOrderFromTable({
          UnitIndex = thisEntity:entindex(),
          -- OrderType = DOTA_UNIT_ORDER_ATTACK_TARGET,
          OrderType = DOTA_UNIT_ORDER_ATTACK_MOVE,
          Position = thisEntity.aggroOrigin,
          Queue = false,
        })
      end
    end
  end

  return 1
end

function Wander ()
  if not thisEntity.startPosition then
    thisEntity.startPosition = thisEntity:GetAbsOrigin()
  end
  if not thisEntity.destination then
    thisEntity.destination = GetNextWanderLocation(thisEntity.startPosition)
  end
  if (thisEntity:GetAbsOrigin() - thisEntity.destination):Length2D() < 100 then
    thisEntity.wandering = false
    thisEntity.wanderCountdown = 30
    Stop()
    return
  end
  if thisEntity.destination and thisEntity:IsIdle() then
    WalkTowardsSpot(thisEntity.destination)
  end
end

function Stop ()
  thisEntity:Stop()
end

function WalkTowardsSpot (spot)
  ExecuteOrderFromTable({
    UnitIndex = thisEntity:entindex(),
    OrderType = DOTA_UNIT_ORDER_MOVE_TO_POSITION,
    Position = spot,
    Queue = false,
  })
end

function GetNextWanderLocation (startPosition)
  -- Change Grendel's destination if he was called by some team
  if Grendel.was_called then
    if Grendel.to_location ~= nil then
      return Grendel.to_location
    end
  end

  local position = Grendel:FindWhereToSpawn()

  return position
end

function StartWandering ()
  thisEntity:Stop()
  thisEntity.startPosition = thisEntity:GetAbsOrigin()
  thisEntity.destination = nil
  thisEntity.wandering = true
  thisEntity.isAggro = false
end
