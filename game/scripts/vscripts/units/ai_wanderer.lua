LinkLuaModifier("modifier_wanderer_boss_buff", "modifiers/modifier_wanderer_boss_buff.lua", LUA_MODIFIER_MOTION_NONE)

-- the range at which we consider outselves basically attacking them
local CLOSE_FOLLOW_RANGE = 300
-- range to follow (visible) enemies, targetting the closest first
-- a-walks towards them
local LONG_FOLLOW_RANGE = 1200
-- the max range away from the spot they were aggroed from where they should walk
-- when this leash limit is hit, the boss walks back to where they were aggroed originalls
-- then follows long follow range
-- should be pretty high for stuff like sniper juggling
local MAX_LEASH_DISTANCE = 2000
-- the distance at which a returning boss will double back and keep attacking (unleash)
local MIN_LEASH_DISTANCE = 500

function Spawn( entityKeyValues )
  if not thisEntity or not IsServer() then
    return
  end

  thisEntity.retreatDelay = 6.0
  thisEntity.damageThreshold = 6.0
  thisEntity.hasSpawned = false

  thisEntity:SetContextThink("WandererThink", WandererThink, 1)

end

function WandererThink ()
  if GameRules:IsGamePaused() == true or GameRules:State_Get() == DOTA_GAMERULES_STATE_POST_GAME or thisEntity:IsAlive() == false then
    return 1
  end

  if Duels:IsActive() then
    thisEntity:Stop()
    return 1
  end

  if not thisEntity.hasSpawned then
    thisEntity.hasSpawned = true
    StartWandering()
  end

  if thisEntity.walking then
    CheckPathBlocking()
  else
    ResetPathBlocking()
  end

  local hpPercent = thisEntity:GetHealth() / thisEntity:GetMaxHealth()

  if thisEntity.wandering then
    Wander()
  else
    if thisEntity:IsIdle() then
      thisEntity.wanderCountdown = thisEntity.wanderCountdown - 1
    end
    if thisEntity.wanderCountdown < 0 then
      StartWandering()
    end
  end

  local shouldAggro = hpPercent < 0.95
  -- if not thisEntity.isAggro and shouldAggro then
    -- is aggroing now from a non-aggro state
  -- end
  if thisEntity.isAggro and not shouldAggro then
    -- giving up on aggro
    thisEntity.aggroOrigin = nil
    thisEntity.isLeashing = false
    thisEntity:RemoveModifierByName("modifier_batrider_firefly")
    thisEntity:RemoveModifierByName("modifier_wanderer_boss_buff")
  end
  if not thisEntity.isAggro and shouldAggro then
      thisEntity:Stop()
      thisEntity.aggroOrigin = thisEntity:GetAbsOrigin()
  end

  -- end pre assign stuff

  thisEntity.isAggro = shouldAggro

  -- start post assign stuff

  if thisEntity.isAggro and not thisEntity.aggroOrigin then
      thisEntity.aggroOrigin = thisEntity:GetAbsOrigin()
  end

  if thisEntity.isAggro and not thisEntity:HasModifier("modifier_batrider_firefly") then
    thisEntity:AddNewModifier(thisEntity, nil, "modifier_batrider_firefly", {
      duration = 99
    })
  end
  if thisEntity.isAggro and not thisEntity:HasModifier("modifier_wanderer_boss_buff") then
    thisEntity:AddNewModifier(thisEntity, nil, "modifier_wanderer_boss_buff", {
      duration = 99
    })
  end

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
    -- less going on so we do non-aggro case first....
    -- don't degen if we're not aggrod yet
    thisEntity:RemoveModifierByName("modifier_boss_regen_degen")
    thisEntity:SetIdleAcquire(false)
    thisEntity:SetAcquisitionRange(0)
  else
    local nearbyEnemies = FindUnitsInRadius(
      thisEntity:GetTeamNumber(),
      thisEntity:GetOrigin(), nil,
      CLOSE_FOLLOW_RANGE,
      DOTA_UNIT_TARGET_TEAM_ENEMY,
      DOTA_UNIT_TARGET_HERO,
      DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES + DOTA_UNIT_TARGET_FLAG_FOW_VISIBLE,
      FIND_CLOSEST,
      false
    )
    local enemies = FindUnitsInRadius(
      thisEntity:GetTeamNumber(),
      thisEntity:GetOrigin(), nil,
      LONG_FOLLOW_RANGE,
      DOTA_UNIT_TARGET_TEAM_ENEMY,
      DOTA_UNIT_TARGET_HERO,
      DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES + DOTA_UNIT_TARGET_FLAG_FOW_VISIBLE,
      FIND_CLOSEST,
      false
    )

    local nearestEnemy = nearbyEnemies[1]
    if #nearbyEnemies == 0 and #enemies > 0 then
      thisEntity.walking = true
      nearestEnemy = enemies[1]
    end

    thisEntity:SetIdleAcquire(true)
    thisEntity:SetAcquisitionRange(128)

    if thisEntity:IsIdle() then
      if nearestEnemy then
        ExecuteOrderFromTable({
          UnitIndex = thisEntity:entindex(),
          -- OrderType = DOTA_UNIT_ORDER_ATTACK_TARGET,
          OrderType = DOTA_UNIT_ORDER_ATTACK_MOVE,
          Position = nearestEnemy:GetAbsOrigin(),
          Queue = 0,
        })
        ExecuteOrderFromTable({
          UnitIndex = thisEntity:entindex(),
          -- OrderType = DOTA_UNIT_ORDER_ATTACK_TARGET,
          OrderType = DOTA_UNIT_ORDER_ATTACK_MOVE,
          Position = thisEntity.aggroOrigin,
          Queue = 1,
        })
      else
        ExecuteOrderFromTable({
          UnitIndex = thisEntity:entindex(),
          -- OrderType = DOTA_UNIT_ORDER_ATTACK_TARGET,
          OrderType = DOTA_UNIT_ORDER_ATTACK_MOVE,
          Position = thisEntity.aggroOrigin,
          Queue = 0,
        })
      end
    end
  end

  return 1
end

 -- -createhero npc_dota_boss_wanderer
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
  ResetPathBlocking()
  thisEntity.walking = false
  thisEntity:Stop()
end

function WalkTowardsSpot (spot)
  if not thisEntity.walking then
    ResetPathBlocking()
  end
  thisEntity.walking = true
  ExecuteOrderFromTable({
    UnitIndex = thisEntity:entindex(),
    OrderType = DOTA_UNIT_ORDER_MOVE_TO_POSITION,
    Position = spot
  })
end

local FIRST_MIN_X = 1600
local FIRST_MIN_Y = 1900

function GetNextWanderLocation (startPosition)
  local maxY = FIRST_MIN_Y
  local maxX = FIRST_MIN_X
  local minY = 0
  local minX = 0
  local scoreDiff = math.abs(PointsManager:GetPoints(DOTA_TEAM_GOODGUYS) - PointsManager:GetPoints(DOTA_TEAM_BADGUYS))
  local isGoodLead = PointsManager:GetPoints(DOTA_TEAM_GOODGUYS) > PointsManager:GetPoints(DOTA_TEAM_BADGUYS)
  if scoreDiff < 10 then
    isGoodLead = RandomInt(0, 1) == 0
  end
  if scoreDiff > 10 then
    maxY = 4000
    maxX = 3100
    minX = 500
  end
  if scoreDiff > 20 then
    maxX = 5500
    minX = 2900
  end
  local nextPosition = nil
  local isValidPosition = false

  while not isValidPosition do
    if nextPosition then
      print('Got a bad position option ' .. tostring(nextPosition))
    end
    nextPosition = Vector(RandomInt(minX, maxX), RandomInt(minY, maxY), startPosition.z)
    if RandomInt(0, 1) == 0 then
      nextPosition.y = 0 - nextPosition.y
    end
    if not isGoodLead then
      nextPosition.x = 0 - nextPosition.x
    end
    isValidPosition = true
    if (nextPosition - startPosition):Length2D() < 2000 then
      isValidPosition = false
    elseif IsNearWell(nextPosition) then
      isValidPosition = false
    end
  end

  return nextPosition
end

function IsNearWell (pos)
  return math.abs(pos.x) > 4800 and math.abs(pos.y) < 1400
end

function CheckPathBlocking ()
  local currentPosition = thisEntity:GetAbsOrigin()
  if not thisEntity.lastSpotCheck then
    ResetPathBlocking()
    thisEntity.lastSpotCheck = currentPosition
  end
  if (currentPosition - thisEntity.lastSpotCheck):Length2D() > 200 then
    ResetPathBlocking()
    thisEntity.lastSpotCheck = nil
  end

  thisEntity.pathBlocking = thisEntity.pathBlocking - 1
  if thisEntity.pathBlocking < 0 then
    thisEntity:AddNewModifier(thisEntity, nil, "modifier_batrider_firefly", {
      duration = 3
    })
    ResetPathBlocking()
  end
end

function StartWandering ()
  thisEntity:Stop()
  thisEntity.startPosition = thisEntity:GetAbsOrigin()
  thisEntity.destination = nil
  thisEntity.wandering = true
  thisEntity.walking = true
  thisEntity.isAggro = false
  ResetPathBlocking()
end

function ResetPathBlocking ()
  thisEntity.pathBlocking = 6
end
