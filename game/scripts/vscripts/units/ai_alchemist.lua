local SIMPLE_AI_STATE_IDLE = 0
local SIMPLE_AI_STATE_AGGRO = 1
local SIMPLE_AI_STATE_LEASH = 2

local SIMPLE_BOSS_LEASH_SIZE = BOSS_LEASH_SIZE or 1200
local SIMPLE_BOSS_AGGRO_HP_PERCENT = 99

function Spawn(entityKeyValues)
  if not thisEntity or not IsServer() then
    return
  end

  thisEntity.CannonshotAbility = thisEntity:FindAbilityByName( "boss_alchemist_cannonshot" )
  thisEntity.AcidSprayAbility = thisEntity:FindAbilityByName( "boss_alchemist_acid_spray" )
  thisEntity.ChemicalRageAbility = thisEntity:FindAbilityByName( "boss_alchemist_chemical_rage" )

  thisEntity:SetContextThink("AlchemistThink", AlchemistThink, 1)
end

function AlchemistThink()
  if GameRules:State_Get() >= DOTA_GAMERULES_STATE_POST_GAME or not IsValidEntity(thisEntity) or not thisEntity:IsAlive() then
    return -1
  end

  if GameRules:IsGamePaused() then
    return 1
  end

  if Duels:IsActive() then
    thisEntity.aggro_target = nil
  end

  local function PointOnCircle(radius, angle)
    local x = radius * math.cos(angle * math.pi / 180)
    local y = radius * math.sin(angle * math.pi / 180)
    return Vector(x,y,0)
  end

  if not thisEntity.initialized then
    thisEntity.spawn_position = thisEntity:GetAbsOrigin()
    thisEntity.vPath = {}
    for i = 1, 13 do
      table.insert(thisEntity.vPath, thisEntity:GetOrigin() + PointOnCircle(250, 360 / 12 * i))
    end
    thisEntity.lastRoamPoint = thisEntity.spawn_position
    thisEntity.BossTier = thisEntity.BossTier or 4
    thisEntity.SiltBreakerProtection = true
    thisEntity.state = SIMPLE_AI_STATE_IDLE
    thisEntity.aggro_target = nil
    thisEntity:SetIdleAcquire(false)
    thisEntity:SetAcquisitionRange(0)
    thisEntity.initialized = true
  end

  local function IsNonHostileWard(entity)
    if entity.HasModifier then
      return entity:HasModifier("modifier_item_buff_ward") or entity:HasModifier("modifier_ward_invisibility")
    end
    return false
  end

  local function FindNearestAttackableUnit(thisEntity)
    local nearby_enemies = FindUnitsInRadius(thisEntity:GetTeamNumber(), thisEntity.spawn_position, nil, SIMPLE_BOSS_LEASH_SIZE, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, bit.bor(DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, DOTA_UNIT_TARGET_FLAG_FOW_VISIBLE), FIND_CLOSEST, false)
    if #nearby_enemies ~= 0 then
      for i = 1, #nearby_enemies do
        local enemy = nearby_enemies[i]
        if enemy and not enemy:IsNull() then
          if enemy:IsAlive() and not enemy:IsAttackImmune() and not enemy:IsInvulnerable() and not enemy:IsOutOfGame() and not IsNonHostileWard(enemy) and not enemy:IsCourier() then
            return enemy
          end
        end
      end
    end
    -- Extend the search radius and find non-visible units too with massive attack range
    nearby_enemies = FindUnitsInRadius(thisEntity:GetTeamNumber(), thisEntity.spawn_position, nil, 3*SIMPLE_BOSS_LEASH_SIZE, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, FIND_CLOSEST, false)
    if #nearby_enemies ~= 0 then
      for i = 1, #nearby_enemies do
        local enemy = nearby_enemies[i]
        if enemy and not enemy:IsNull() then
          if enemy:IsAlive() and not enemy:IsAttackImmune() and not enemy:IsInvulnerable() and not enemy:IsOutOfGame() and not IsNonHostileWard(enemy) and not enemy:IsCourier() and enemy:GetAttackRange() > SIMPLE_BOSS_LEASH_SIZE and (enemy:GetAbsOrigin() - thisEntity.spawn_position):Length2D() < 2*SIMPLE_BOSS_LEASH_SIZE then
            return enemy
          end
        end
      end
    end
    return nil
  end

  local function AttackNearestTarget(thisEntity)
    local nearest_enemy = FindNearestAttackableUnit(thisEntity)
    if nearest_enemy then
      ExecuteOrderFromTable({
        UnitIndex = thisEntity:entindex(),
        OrderType = DOTA_UNIT_ORDER_ATTACK_MOVE,
        Position = nearest_enemy:GetAbsOrigin(),
        Queue = true,
      })
    end
    thisEntity.aggro_target = nearest_enemy
  end

  local function StartLeashing(thisEntity)
    thisEntity.aggro_target = nil
    thisEntity.state = SIMPLE_AI_STATE_LEASH
    return 1
  end

  local function FindCannonshotLocations(thisEntity)
    local closest_distance = SIMPLE_BOSS_LEASH_SIZE
    local flags = bit.bor(DOTA_UNIT_TARGET_FLAG_FOW_VISIBLE, DOTA_UNIT_TARGET_FLAG_NO_INVIS)
    local entityOrigin = thisEntity:GetAbsOrigin()
    local enemies = FindUnitsInRadius(thisEntity:GetTeamNumber(), entityOrigin, nil, closest_distance, DOTA_UNIT_TARGET_TEAM_ENEMY, bit.bor(DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_BASIC), flags, FIND_CLOSEST, false)

    local target1, target2
    local closest
    local closest2

    -- Find 2 closest units
    for _, unit in ipairs(enemies) do
      -- Calculating distance
      local distance = (unit:GetAbsOrigin() - entityOrigin):Length2D()
      if distance < closest_distance then
        closest_distance = distance
        closest2 = closest
        closest = unit
      elseif not closest2 then
        closest2 = unit
      end
    end

    if closest then
      target1 = closest:GetAbsOrigin()

      if closest2 then
        target2 = closest2:GetAbsOrigin()
      else
        target2 = target1 + RandomVector(200)
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

  local current_hp_pct = thisEntity:GetHealth() / thisEntity:GetMaxHealth()
  local aggro_hp_pct = SIMPLE_BOSS_AGGRO_HP_PERCENT / 100

  if thisEntity.state == SIMPLE_AI_STATE_IDLE then
    -- Remove debuff protection
    thisEntity:RemoveModifierByName("modifier_anti_stun_oaa")
    -- Check boss hp
    if current_hp_pct < aggro_hp_pct then
      if thisEntity:HasModifier("modifier_alchemist_chemical_rage") then
        -- Issue an attack-move command towards the nearast unit that is attackable and assign it as aggro_target.
        -- Because of attack priorities (wards have the lowest attack priority) aggro_target will not always be
        -- the same as true aggro target (unit that is boss actually attacking at the moment)
        AttackNearestTarget(thisEntity)
      else
        -- Start roaming around spawn location
        thisEntity.lastRoamPoint = thisEntity.vPath[RandomInt(1, 13)]
        ExecuteOrderFromTable({
          UnitIndex = thisEntity:entindex(),
          OrderType = DOTA_UNIT_ORDER_MOVE_TO_POSITION,
          Position = thisEntity.lastRoamPoint,
          Queue = true,
        })
      end
      thisEntity.state = SIMPLE_AI_STATE_AGGRO
    else
      -- Check if the boss was messed around with displacing abilities (Force Staff for example)
      if (thisEntity.spawn_position - thisEntity:GetAbsOrigin()):Length2D() > 10 then
        --thisEntity:MoveToPosition(thisEntity.spawn_position)
        ExecuteOrderFromTable({
          UnitIndex = thisEntity:entindex(),
          OrderType = DOTA_UNIT_ORDER_MOVE_TO_POSITION,
          Position = thisEntity.spawn_position,
          Queue = false,
        })
        thisEntity.state = SIMPLE_AI_STATE_LEASH
      end
    end
  elseif thisEntity.state == SIMPLE_AI_STATE_AGGRO then
    -- Check how far did the boss go from the spawn position
    if (thisEntity:GetAbsOrigin() - thisEntity.spawn_position):Length2D() > SIMPLE_BOSS_LEASH_SIZE then
      -- Check for actual aggro target
      if thisEntity:GetAggroTarget() and not thisEntity:GetAggroTarget():IsNull() and thisEntity:HasModifier("modifier_alchemist_chemical_rage") then
        local true_aggro_target = thisEntity:GetAggroTarget()
        -- Prevent bosses chasing Snipers all over the map (its funny though)
        if (true_aggro_target:GetAbsOrigin() - thisEntity.spawn_position):Length2D() > 2*SIMPLE_BOSS_LEASH_SIZE then
          return StartLeashing(thisEntity)
        elseif (true_aggro_target:GetAbsOrigin() - thisEntity.spawn_position):Length2D() > SIMPLE_BOSS_LEASH_SIZE then
          -- Check attack range of true aggro target, if its less than leash/aggro range, start leashing
          if true_aggro_target:GetAttackRange() <= SIMPLE_BOSS_LEASH_SIZE then
            return StartLeashing(thisEntity)
          end
        end
      else
        -- Boss is outside of leash range and the unit he was attacking doesnt exist, start leashing
        return StartLeashing(thisEntity)
      end
    end

    if thisEntity:HasModifier("modifier_alchemist_chemical_rage") then
      -- Check if aggro_target exists
      if thisEntity.aggro_target then
        -- Check if aggro_target is getting deleted soon from c++
        if thisEntity.aggro_target:IsNull() then
          thisEntity.aggro_target = nil
        end
        -- Check if state of aggro_target changed (died, became attack immune (ethereal), became invulnerable or banished)
        local aggro_target = thisEntity.aggro_target
        if not aggro_target:IsAlive() or aggro_target:IsAttackImmune() or aggro_target:IsInvulnerable() or aggro_target:IsOutOfGame() then
          thisEntity.aggro_target = nil
        end
        -- Check if aggro_target is out of aggro/leash range
        if (aggro_target:GetAbsOrigin() - thisEntity.spawn_position):Length2D() > 2*SIMPLE_BOSS_LEASH_SIZE then
          thisEntity.aggro_target = nil
        elseif (aggro_target:GetAbsOrigin() - thisEntity.spawn_position):Length2D() > SIMPLE_BOSS_LEASH_SIZE then
          -- Check aggro_target attack range, if its less than leash/aggro range
          if aggro_target:GetAttackRange() <= SIMPLE_BOSS_LEASH_SIZE then
            thisEntity.aggro_target = nil
          end
        end
        -- Check HP of the boss
        if current_hp_pct > aggro_hp_pct then
          thisEntity.aggro_target = nil
        end
        -- Check if boss is stuck or idle because actual aggro target doesn't exist.
        if not thisEntity:GetAggroTarget() or thisEntity:IsIdle() then
          thisEntity.aggro_target = nil
        end
      else
        -- Check HP of the boss
        if current_hp_pct < aggro_hp_pct then
          AttackNearestTarget(thisEntity)
        end

        if not thisEntity.aggro_target then
          thisEntity.state = SIMPLE_AI_STATE_LEASH
        end
      end
    end

    if current_hp_pct > 75/100 then -- phase 1
      -- Check if still aggroed
      if current_hp_pct > aggro_hp_pct then
        return StartLeashing(thisEntity)
      end

      local ability
      local target1, target2 = FindCannonshotLocations(thisEntity)
      if RandomInt(1, 2) == 1 then
        ability = thisEntity.AcidSprayAbility
      else
        ability = thisEntity.CannonshotAbility
      end

      if ability and ability:IsCooldownReady() then
        if target1 then
          ability.target_points = { target1 = target1, target2 = target2 }
          CastOnPoint(ability, target1)
        end
      end
    elseif current_hp_pct > 50/100 then -- phase 2
      local ability
      local other_ability
      local target1, target2 = FindCannonshotLocations(thisEntity)
      if RandomInt(1, 2) == 1 then
        ability = thisEntity.AcidSprayAbility
        other_ability = thisEntity.CannonshotAbility
      else
        ability = thisEntity.CannonshotAbility
        other_ability = thisEntity.AcidSprayAbility
      end

      if ability and ability:IsCooldownReady() and other_ability then
        if target2 then
          ability.target_points = { target1 = target1, target2 = target2 }
          CastOnPoint(ability, target2)
        end
        local chance_for_double = 15
        if RandomInt(1, 100) <= chance_for_double then
          -- End CD of the other ability
          other_ability:EndCooldown()
          if target1 then
            other_ability.target_points = { target1 = target1, target2 = target2 }
            CastOnPoint(other_ability, target1)
          end
        end
      end
    elseif current_hp_pct > 30/100 then -- phase 3
      if thisEntity.CannonshotAbility:IsCooldownReady() then
        local cannonshots = RandomInt(1, 3)
        thisEntity.lastCannonShots = cannonshots
        local ability = thisEntity.CannonshotAbility
        local target1, target2 = FindCannonshotLocations(thisEntity)

        if cannonshots == 1 then
          ability.target_points = { target1 = target1 }
        elseif cannonshots == 2 then
          ability.target_points = { target1 = target1, target2 = target2 }
        elseif cannonshots == 3 then
          if target2 then
            ability.target_points = { target1 = target1, target2 = target2, target3 = target2 + RandomVector(200) }
          end
        end
        if target1 then
          CastOnPoint(ability, target1)
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
            if target1 then
              table.insert(acidpoints, target1 + RandomVector(200))
            end
          end
        elseif #acidpoints > acidshots then
          local i = #acidpoints
          repeat
            table.remove(acidpoints, i)
            i = i - 1
          until (#acidpoints == acidshots)
        end

        if target1 then
          ability.target_points = acidpoints
          CastOnPoint(ability, target1)
        end
      end
    else -- Phase 4
      if not thisEntity:HasModifier("modifier_alchemist_chemical_rage") and thisEntity.ChemicalRageAbility and thisEntity.ChemicalRageAbility:IsFullyCastable() then
        CastRage()
        AttackNearestTarget(thisEntity)
        return 1
      elseif thisEntity.CannonshotAbility:IsCooldownReady() then
        local cannonshots = RandomInt(1, 3)
        thisEntity.lastCannonShots = cannonshots
        local ability = thisEntity.CannonshotAbility
        local target1, target2 = FindCannonshotLocations(thisEntity)

        if cannonshots == 1 then
          ability.target_points = { target1 = target1 }
        elseif cannonshots == 2 then
          ability.target_points = { target1 = target1, target2 = target2 }
        elseif cannonshots == 3 then
          if target2 then
            ability.target_points = { target1 = target1, target2 = target2, target3 = target2 + RandomVector(200) }
          end
        end
        if target1 then
          CastOnPoint(ability, target1)
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
            if target1 then
              table.insert(acidpoints, target1 + RandomVector(200))
            end
          end
        elseif #acidpoints > acidshots then
          local i = #acidpoints
          repeat
            table.remove(acidpoints, i)
            i = i - 1
          until (#acidpoints == acidshots)
        end

        if target1 then
          ability.target_points = acidpoints
          CastOnPoint(ability, target1)
        end
      end
    end

    -- Roam without Chemical Rage
    if not thisEntity:HasModifier("modifier_alchemist_chemical_rage") and current_hp_pct < aggro_hp_pct then
      if not thisEntity.bRoamed then
        local next_location = thisEntity.vPath[RandomInt(1, 13)]
        if next_location == thisEntity.lastRoamPoint then
          next_location = next_location + RandomVector(100)
        end

        thisEntity.lastRoamPoint = next_location

        ExecuteOrderFromTable({
          UnitIndex = thisEntity:entindex(),
          OrderType = DOTA_UNIT_ORDER_MOVE_TO_POSITION,
          Position = thisEntity.lastRoamPoint,
          --Queue = true,
        })
      end
      thisEntity.bRoamed = not thisEntity.bRoamed
    end
  elseif thisEntity.state == SIMPLE_AI_STATE_LEASH then
    -- Add Debuff Protection when leashing
    thisEntity:AddNewModifier(thisEntity, nil, "modifier_anti_stun_oaa", {})
    -- Actual leashing
    --thisEntity:MoveToPosition(thisEntity.spawn_position)
    ExecuteOrderFromTable({
      UnitIndex = thisEntity:entindex(),
      OrderType = DOTA_UNIT_ORDER_MOVE_TO_POSITION,
      Position = thisEntity.spawn_position,
      Queue = false,
    })
    -- Check if boss reached the spawn_position
    if (thisEntity.spawn_position - thisEntity:GetAbsOrigin()):Length2D() < 10 then
      -- Go into the idle state if the boss is back to the spawn position
      thisEntity:SetIdleAcquire(false)
      thisEntity:SetAcquisitionRange(0)
      thisEntity.state = SIMPLE_AI_STATE_IDLE
    end
  end

  return 0.5
end

function CastOnPoint(ability, target)
  thisEntity:DispelWeirdDebuffs()

  ExecuteOrderFromTable({
    UnitIndex = thisEntity:entindex(),
    OrderType = DOTA_UNIT_ORDER_CAST_POSITION,
    AbilityIndex = ability:entindex(),
    Position = target,
    Queue = false,
  })
end

function CastRage()
  ExecuteOrderFromTable({
    UnitIndex = thisEntity:entindex(),
    OrderType = DOTA_UNIT_ORDER_CAST_NO_TARGET,
    AbilityIndex = thisEntity.ChemicalRageAbility:entindex(),
    Queue = false,
  })
end
