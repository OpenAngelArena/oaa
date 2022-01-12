local function FindCannonshotLocations(thisEntity)
  local flags = bit.bor(DOTA_UNIT_TARGET_FLAG_FOW_VISIBLE, DOTA_UNIT_TARGET_FLAG_NO_INVIS)
  local entityOrigin = thisEntity:GetAbsOrigin()
  local enemies = FindUnitsInRadius( thisEntity:GetTeamNumber(), entityOrigin, nil, 1000, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO, flags, FIND_FARTHEST, false )

  local target1, target2
  local count = 0
  local closest
  local closest2

  for k,v in pairs(enemies) do
    local distance = (v:GetAbsOrigin() - entityOrigin):Length2D()

    if distance > count then
      count = distance
      closest2 = closest
      closest = v
    elseif not closest2 then
      closest2 = v
    end
  end

  if closest then
    target1 = closest:GetAbsOrigin()

    if closest2 then
      target2 = closest:GetAbsOrigin()
    else
      target2 = target1 + RandomVector(256)
    end
  end
  if target1 and target2 then
    local direction = (target1 - entityOrigin):Normalized()
    local direction2 = (target2 - entityOrigin):Normalized()

    local pushDistance = 100

    target1 = target1 + (pushDistance * direction)
    target2 = target2 + (pushDistance * direction2)
  end

  return target1, target2
end

local function Cast(ability, target)
  ExecuteOrderFromTable({
    UnitIndex = thisEntity:entindex(),
    OrderType = DOTA_UNIT_ORDER_CAST_POSITION,
    AbilityIndex = ability:entindex(),
    Position = target,
  })
end

local function PointOnCircle(radius, angle)
  local x = radius * math.cos(angle * math.pi / 180)
  local y = radius * math.sin(angle * math.pi / 180)
  return Vector(x,y,0)
end

function Spawn( entityKeyValues )
  if not IsServer() then
    return
  end

  if thisEntity == nil then
    return
  end

  thisEntity.CannonshotAbility = thisEntity:FindAbilityByName( "boss_alchemist_cannonshot" )
  thisEntity.AcidSprayAbility = thisEntity:FindAbilityByName( "boss_alchemist_acid_spray" )
  thisEntity.ChemicalRageAbility = thisEntity:FindAbilityByName( "boss_alchemist_chemical_rage" )

  thisEntity.roamRadius = 250

  thisEntity:SetContextThink( "AlchemistThink", AlchemistThink, 1 )
end

function AlchemistThink()
  if GameRules:State_Get() >= DOTA_GAMERULES_STATE_POST_GAME or not IsValidEntity(thisEntity) or not thisEntity:IsAlive() then
    return -1
  end

  if GameRules:IsGamePaused() then
    return 1
  end

  if not thisEntity.bInitialized then
    thisEntity.vInitialSpawnPos = thisEntity:GetOrigin()
    thisEntity.vPath = {}
    for i=1,13 do
      table.insert(thisEntity.vPath, thisEntity:GetOrigin() + PointOnCircle(thisEntity.roamRadius, 360 / 12 * i))
    end
    thisEntity.vPathPoint = 0
    thisEntity.bHasAgro = false
    thisEntity.BossTier = thisEntity.BossTier or 3
    thisEntity.fAgroRange = thisEntity:GetAcquisitionRange()
    thisEntity:SetIdleAcquire(false)
    thisEntity:SetAcquisitionRange(0)
    thisEntity.bInitialized = true
  end

  local enemies = FindUnitsInRadius(
    thisEntity:GetTeamNumber(),
    thisEntity:GetOrigin(), nil,
    800,
    DOTA_UNIT_TARGET_TEAM_ENEMY,
    DOTA_UNIT_TARGET_HERO,
    DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES + DOTA_UNIT_TARGET_FLAG_FOW_VISIBLE,
    FIND_CLOSEST,
    false
  )

  local hasDamageThreshold = thisEntity:GetMaxHealth() - thisEntity:GetHealth() > thisEntity.BossTier * BOSS_AGRO_FACTOR
  local fDistanceToOrigin = ( thisEntity:GetOrigin() - thisEntity.vInitialSpawnPos ):Length2D()

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

  if not thisEntity:IsIdle() then
    return 0.03
  else
    thisEntity.vPathPoint = thisEntity.vPathPoint + 1
    if thisEntity.vPathPoint == 13 then
      thisEntity.vPathPoint = 1
    end
    ExecuteOrderFromTable({
      UnitIndex = thisEntity:entindex(),
      OrderType = DOTA_UNIT_ORDER_MOVE_TO_POSITION,
      Position = thisEntity.vPath[thisEntity.vPathPoint]
    })
  end

  if thisEntity:GetHealth() / thisEntity:GetMaxHealth() > 0.75 then -- phase 1
    local ability
    local target1, target2 = FindCannonshotLocations(thisEntity)
    if math.random(0, 1) == 0 then
      ability = thisEntity.AcidSprayAbility
      DebugPrint('Trying to cast acid spray')
    else
      ability = thisEntity.CannonshotAbility
      DebugPrint('Trying to cast cannon')
    end

    if ability:IsCooldownReady() then
      if target1 then
        ability.target_points = { target1 = target1, target2 = target2 }
        Cast(ability, target1)
      end
    end
  elseif thisEntity:GetHealth() / thisEntity:GetMaxHealth() > 0.5 then -- phase 2
    local ability
    local target1, target2 = FindCannonshotLocations(thisEntity)
    if math.random(0, 1) == 0 then
      ability = thisEntity.AcidSprayAbility
    else
      ability = thisEntity.CannonshotAbility
    end

    if thisEntity.CannonshotAbility:IsCooldownReady() and thisEntity.AcidSprayAbility:IsCooldownReady() or thisEntity.bDouble then
      if target1 then
        thisEntity.AcidSprayAbility:EndCooldown()
        thisEntity.CannonshotAbility:EndCooldown()

        ability.target_points = { target1 = target1, target2 = target2 }
        Cast(ability, target2)

        thisEntity.bDouble = not thisEntity.bDouble
      end
    end
  else -- phase 3
    if thisEntity.CannonshotAbility:IsCooldownReady() then
      local cannonshots = RandomInt(1,3)
      thisEntity.lastCannonShots = cannonshots
      local ability = thisEntity.CannonshotAbility
      local target1, target2 = FindCannonshotLocations(thisEntity)

      -- end acid spray CD whenever we shoot a cannon
      thisEntity.AcidSprayAbility:EndCooldown()

      if cannonshots == 1 then
        ability.target_points = { target1 = target1 }
      elseif cannonshots == 2 then
        ability.target_points = { target1 = target1, target2 = target2 }
      elseif cannonshots == 3 then
        ability.target_points = { target1 = target1, target2 = target2, target3 = target2 + RandomVector(200) }
      end
      if ability.target_points then
        Cast(ability, target1)
      end
    elseif thisEntity.AcidSprayAbility:IsCooldownReady() then
      local acidshots = 4 - (thisEntity.lastCannonShots or 0)
      local ability = thisEntity.AcidSprayAbility
      local target1, target2 = FindCannonshotLocations(thisEntity)
      local acidpoints = {}
      table.insert(acidpoints, target1)
      table.insert(acidpoints, target2)
      if #acidpoints < acidshots then
        for i = #acidpoints, acidshots-1 do
          table.insert(acidpoints, target1 + RandomVector(200))
        end
      elseif #acidpoints > acidshots then
        local i = #acidpoints
        repeat
          table.remove(acidpoints, i)
          i = i - 1
        until
          #acidpoints == acidshots
      end

      ability.target_points = acidpoints
      Cast(ability, target1)
    end
  end

  return 0.5
end

function RetreatHome()
  ExecuteOrderFromTable({
    UnitIndex = thisEntity:entindex(),
    OrderType = DOTA_UNIT_ORDER_MOVE_TO_POSITION,
    Position = thisEntity.vInitialSpawnPos
  })

  return 1.0
end
