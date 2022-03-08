LinkLuaModifier("modifier_wanderer_boss_buff", "abilities/boss/wanderer/modifier_wanderer_boss_buff.lua", LUA_MODIFIER_MOTION_NONE)

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
  thisEntity.netAbility = thisEntity:FindAbilityByName("wanderer_net")
  thisEntity.cleanseAbility = thisEntity:FindAbilityByName("wanderer_aoe_cleanse")
  thisEntity.BossTier = thisEntity.BossTier or 3

  thisEntity:SetContextThink("WandererThink", WandererThink, 1)
end

function WandererThink ()
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

  -- Wanderer is aggroed if its health is below 95%
  local shouldAggro = hpPercent < 0.95

  -- Check if Wanderer is aggroed but it shouldn't be aggroed
  if thisEntity.isAggro and not shouldAggro then
    -- giving up on aggro
    thisEntity:Stop()
    WalkTowardsSpot(thisEntity.aggroOrigin)
    thisEntity.aggroOrigin = nil
    thisEntity.isLeashing = false
    thisEntity:RemoveModifierByName("modifier_batrider_firefly")
    thisEntity:RemoveModifierByName("modifier_wanderer_boss_buff")
  end

  -- Check if Wanderer is not aggroed but it should be aggroed
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

  -- Visual effect
  if thisEntity.isAggro and not thisEntity:HasModifier("modifier_batrider_firefly") then
    thisEntity:AddNewModifier(thisEntity, nil, "modifier_batrider_firefly", {
      duration = 99
    })
  end
  -- Wanderer's buff with absolute movement speed etc.
  if thisEntity.isAggro and not thisEntity:HasModifier("modifier_wanderer_boss_buff") then
    thisEntity:AddNewModifier(thisEntity, nil, "modifier_wanderer_boss_buff", {
      duration = 99
    })
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
    -- less going on so we do non-aggro case first....
    -- don't degen if we're not aggrod yet
    thisEntity:RemoveModifierByName("modifier_boss_regen_degen")
    thisEntity:SetIdleAcquire(false)
    thisEntity:SetAcquisitionRange(0)
    Wanderer:DisableOffside("Enable")
  else
    -- If the score difference isn't too big, disable offside if Wanderer is aggroed on it
    if math.abs(PointsManager:GetPoints(DOTA_TEAM_GOODGUYS) - PointsManager:GetPoints(DOTA_TEAM_BADGUYS)) < 25 then
      if IsLocationInRadiantOffside(thisEntity:GetAbsOrigin()) then
        Wanderer:DisableOffside("Radiant")
      elseif IsLocationInDireOffside(thisEntity:GetAbsOrigin()) then
        Wanderer:DisableOffside("Dire")
      else
        Wanderer:DisableOffside("Enable")
      end
    end

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
      thisEntity.walking = true
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

    -- Cast abilities if below 75% health
    if thisEntity:GetHealth() / thisEntity:GetMaxHealth() <= 0.75 then
      if thisEntity.netAbility and thisEntity.netAbility:IsFullyCastable() and nearestEnemy then
        thisEntity:CastAbilityOnTarget(nearestEnemy, thisEntity.netAbility, thisEntity:entindex())
      end
      if thisEntity:GetHealth() / thisEntity:GetMaxHealth() <= 0.5 then
        local enemiesToCleanse = FindUnitsInRadius(
          thisEntity:GetTeamNumber(),
          thisEntity:GetAbsOrigin(),
          nil,
          1000,
          DOTA_UNIT_TARGET_TEAM_ENEMY,
          DOTA_UNIT_TARGET_ALL,
          DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES,
          FIND_ANY_ORDER,
          false
        )
        if thisEntity.cleanseAbility and thisEntity.cleanseAbility:IsFullyCastable() and #enemiesToCleanse > 1 then
          ExecuteOrderFromTable({
            UnitIndex = thisEntity:entindex(),
            OrderType = DOTA_UNIT_ORDER_CAST_NO_TARGET,
            AbilityIndex = thisEntity.cleanseAbility:entindex(),
            Queue = false,
          })
        end
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

function GetNextWanderLocation (startPosition)
  local maxY = 4000
  local maxX = 1000
  local minY = 0
  local minX = 0
  local scoreDiff = math.abs(PointsManager:GetPoints(DOTA_TEAM_GOODGUYS) - PointsManager:GetPoints(DOTA_TEAM_BADGUYS))
  local isGoodLead = PointsManager:GetPoints(DOTA_TEAM_GOODGUYS) > PointsManager:GetPoints(DOTA_TEAM_BADGUYS)

  if scoreDiff >= 20 then
    maxX = 5600
    minX = 2600
  elseif scoreDiff >= 15 then
    maxX = 2600
    minX = 1400
  elseif scoreDiff >= 10 then
    maxX = 2100
    minX = 900
  elseif scoreDiff >= 5 then
    maxX = 1600
    minX = 400
  else
    isGoodLead = RandomInt(0, 1) == 0
  end

  local nextPosition = Vector(0, 0, 0)
  local isValidPosition = false
  local loopCount = 0

  while not isValidPosition do
    loopCount = loopCount + 1
    --if nextPosition then
      --print('Got a bad position option ' .. tostring(nextPosition))
    --end
    nextPosition = Vector(RandomInt(minX, maxX), RandomInt(minY, maxY), startPosition.z)
    if RandomInt(0, 1) == 0 then
      nextPosition.y = 0 - nextPosition.y
    end
    if not isGoodLead then
      nextPosition.x = 0 - nextPosition.x
    end
    isValidPosition = true
    if (scoreDiff > 5 and (nextPosition - startPosition):Length2D() < 800) or (IsNearRadiantFountain(nextPosition) or IsNearDireFountain(nextPosition)) then
      if loopCount < 7 then
        isValidPosition = false
      end
    end
  end

  return nextPosition
end

function IsNearRadiantFountain (pos)
  local radiant_fountain = Entities:FindByName(nil, "fountain_good_trigger")
  if not radiant_fountain then
    print("Radiant fountain trigger not found or referenced name is wrong.")
    return math.abs(pos.x) > 4800 and math.abs(pos.y) < 1400
  end
  local origin = radiant_fountain:GetAbsOrigin()
  local bounds = radiant_fountain:GetBounds()
  if pos.x < bounds.Mins.x + origin.x - 400 then
    return false
  end
  if pos.y < bounds.Mins.y + origin.y - 400 then
    return false
  end
  if pos.x > bounds.Maxs.x + origin.x + 400 then
    return false
  end
  if pos.y > bounds.Maxs.y + origin.y + 400 then
    return false
  end

  return true
end

function IsNearDireFountain (pos)
  local bad_fountain = Entities:FindByName(nil, "fountain_bad_trigger")
  if not bad_fountain then
    print("Dire fountain trigger not found or referenced name is wrong.")
    return math.abs(pos.x) > 4800 and math.abs(pos.y) < 1400
  end
  local origin = bad_fountain:GetAbsOrigin()
  local bounds = bad_fountain:GetBounds()
  if pos.x < bounds.Mins.x + origin.x - 400 then
    return false
  end
  if pos.y < bounds.Mins.y + origin.y - 400 then
    return false
  end
  if pos.x > bounds.Maxs.x + origin.x + 400 then
    return false
  end
  if pos.y > bounds.Maxs.y + origin.y + 400 then
    return false
  end

  return true
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
