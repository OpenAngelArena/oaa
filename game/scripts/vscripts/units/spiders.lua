
LinkLuaModifier( "modifier_boss_phase_controller", "modifiers/modifier_boss_phase_controller", LUA_MODIFIER_MOTION_NONE )

function FindCannonshotLocations()
  local flags = DOTA_UNIT_TARGET_FLAG_FOW_VISIBLE + DOTA_UNIT_TARGET_FLAG_NO_INVIS
  local enemies = FindUnitsInRadius( thisEntity:GetTeamNumber(), thisEntity:GetAbsOrigin(), nil, 1000, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO, flags, FIND_FARTHEST, false )
  
  local target1, target2
  local count = 0
  local closest
  local closest2

  for k,v in pairs(enemies) do
    for k2,v2 in pairs(enemies) do
      if v2 ~= v then
        local distance = (v:GetAbsOrigin() - v2:GetAbsOrigin()):Length2D()

        if distance > count and distance > 200 then
          count = distance
          closest = v2
          closest2 = v
        end
      end
    end
  end

  if closest and closest2 then
    local direction = (closest:GetAbsOrigin() - closest2:GetAbsOrigin()):Normalized()
    local distance = (closest:GetAbsOrigin() - closest2:GetAbsOrigin()):Length2D()

    local pushDistance = 400 - (distance/2)

    target1 = closest:GetAbsOrigin() + (pushDistance * direction)
    target2 = closest2:GetAbsOrigin() - (pushDistance * direction)
  end

  return target1, target2
end

function FindSpidershotLocations()
  local flags = DOTA_UNIT_TARGET_FLAG_FOW_VISIBLE + DOTA_UNIT_TARGET_FLAG_NO_INVIS
  local enemies = FindUnitsInRadius( thisEntity:GetTeamNumber(), thisEntity:GetAbsOrigin(), nil, 1000, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO, flags, FIND_FARTHEST, false )
  
  local target1, target2
  local count = 0

  for k,v in pairs(enemies) do
    local closeEnemies = FindUnitsInRadius( thisEntity:GetTeamNumber(), v:GetAbsOrigin(), nil, 350, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO, flags, FIND_FARTHEST, false )

    if #closeEnemies > count then
      count = #closeEnemies
      target2 = target1
      target1 = v:GetAbsOrigin()
    end
  end

  if target1 and not target2 then
    target2 = target1 + RandomVector(256)
  end

  return target1, target2
end

function Spawn( entityKeyValues )
  if not IsServer() then
    return
  end

  if thisEntity == nil then
    return
  end

  thisEntity.CannonshotAbility = thisEntity:FindAbilityByName( "boss_spiders_cannonshot" )
  thisEntity.SpidershotAbility = thisEntity:FindAbilityByName( "boss_spiders_spidershot" )

  thisEntity:SetContextThink( "SpidersThink", SpidersThink, 1 )
end

function SpidersThink()
  if ( not thisEntity:IsAlive() ) then
    return -1
  end

  if GameRules:IsGamePaused() == true then
    return 1
  end

  if not thisEntity.bInitialized then
    thisEntity.vInitialSpawnPos = thisEntity:GetOrigin()
    thisEntity.bInitialized = true
    thisEntity.vPath = {}
    for i=1,13 do
      table.insert(thisEntity.vPath, thisEntity:GetOrigin() + PointOnCircle(300, 360 / 12 * i))
    end
    thisEntity.vPathPoint = 0
    thisEntity.bHasAgro = false
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
    local target1, target2
    if math.random(0, 1) == 0 then
      ability = thisEntity.SpidershotAbility
      target1, target2 = FindSpidershotLocations()
    else
      ability = thisEntity.CannonshotAbility
      target1, target2 = FindCannonshotLocations()
    end

    if thisEntity.CannonshotAbility:IsCooldownReady() and thisEntity.SpidershotAbility:IsCooldownReady() then
      if target1 then
        ability.target_points = { target1 = target1, target2 = target2 }
        Cast(ability, target)
      end
    end
  elseif thisEntity:GetHealth() / thisEntity:GetMaxHealth() > 0.5 then -- phase 2
    local ability
    local target1, target2
    if math.random(0, 1) == 0 then
      ability = thisEntity.SpidershotAbility
      target1, target2 = FindSpidershotLocations()
    else
      ability = thisEntity.CannonshotAbility
      target1, target2 = FindCannonshotLocations()
    end

    if thisEntity.CannonshotAbility:IsCooldownReady() and thisEntity.SpidershotAbility:IsCooldownReady() or thisEntity.bDouble then
      if target1 then
        thisEntity.SpidershotAbility:EndCooldown()
        thisEntity.CannonshotAbility:EndCooldown()

        ability.target_points = { target1 = target1, target2 = target2 }
        Cast(ability, target2)

        thisEntity.bDouble = not thisEntity.bDouble
      end
    end
  else -- phase 3
    if thisEntity.CannonshotAbility:IsCooldownReady() and thisEntity.SpidershotAbility:IsCooldownReady() then
      local cannonshots = math.random(1,4)
      local spidershots = 4 - cannonshots

      local ability = thisEntity.CannonshotAbility
      local target1, target2 = FindCannonshotLocations()

      if target1 then
        Timers:CreateTimer(0.3, function (  )
          local spiderTarget1, spiderTarget2 = FindSpidershotLocations()
          for i=1,spidershots do
            thisEntity.SpidershotAbility.target_points = { target1 = spiderTarget1 + RandomVector(128) }
            thisEntity.SpidershotAbility:OnSpellStart()
          end
          thisEntity.SpidershotAbility:StartCooldown(thisEntity.SpidershotAbility:GetCooldownTime())
        end)

        if cannonshots == 1 then
          ability.target_points = { target1 = target1 }
        elseif cannonshots == 2 then
          ability.target_points = { target1 = target1, target2 = target2 }
        elseif cannonshots == 3 then
          ability.target_points = { target1 = target1, target2 = target2, target3 = target2 + RandomVector(128) }
        else
          ability.target_points = { target1 = target1, target2 = target2, target3 = target2 + RandomVector(128), target4 = target2 + RandomVector(128) }
        end
        Cast(ability, target1)
      end
    end
  end

  return 0.1
end

function Cast(ability, target)
  ExecuteOrderFromTable({
    UnitIndex = thisEntity:entindex(),
    OrderType = DOTA_UNIT_ORDER_CAST_POSITION,
    AbilityIndex = ability:entindex(),
    Position = target,
  })
end

function PointOnCircle(radius, angle)
  local x = radius * math.cos(angle * math.pi / 180)
  local y = radius * math.sin(angle * math.pi / 180)
  return Vector(x,y,0) 
end