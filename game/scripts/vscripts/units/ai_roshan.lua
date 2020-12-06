local SIMPLE_AI_STATE_IDLE = 0
local SIMPLE_AI_STATE_AGGRO = 1
local SIMPLE_AI_STATE_LEASH = 2

local SIMPLE_BOSS_LEASH_SIZE = BOSS_LEASH_SIZE or 1200
local SIMPLE_BOSS_AGGRO_HP_PERCENT = 99

function Spawn( entityKeyValues )
  if not thisEntity or not IsServer() then
    return
  end
  thisEntity.slam_ability = thisEntity:FindAbilityByName("roshan_slam")
  thisEntity:SetContextThink("RoshanThink", RoshanThink, 1)
end

function RoshanThink()
  if GameRules:IsGamePaused() == true or GameRules:State_Get() == DOTA_GAMERULES_STATE_POST_GAME or thisEntity:IsAlive() == false then
    return 1
  end

  if Duels:IsActive() then
    thisEntity.aggro_target = nil
  end

  if not thisEntity.initialized then
    thisEntity.spawn_position = thisEntity:GetAbsOrigin()
    thisEntity.state = SIMPLE_AI_STATE_IDLE
    thisEntity.aggro_target = nil
    thisEntity:SetIdleAcquire(false)
    thisEntity:SetAcquisitionRange(0)
    thisEntity.initialized = true
  end

  local function FindNearestAttackableUnit(thisEntity)
    local nearby_enemies = FindUnitsInRadius(thisEntity:GetTeamNumber(), thisEntity.spawn_position, nil, SIMPLE_BOSS_LEASH_SIZE, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, bit.bor(DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, DOTA_UNIT_TARGET_FLAG_FOW_VISIBLE), FIND_CLOSEST, false)
    if #nearby_enemies ~= 0 then
      for i = 1, #nearby_enemies do
        local enemy = nearby_enemies[i]
        if enemy and not enemy:IsNull() then
          if enemy:IsAlive() and not enemy:IsAttackImmune() and not enemy:IsInvulnerable() and not enemy:IsOutOfGame() and not enemy:HasModifier("modifier_item_buff_ward") and not enemy:IsCourier() then
            return enemy
          end
        end
      end
    end
    nearby_enemies = FindUnitsInRadius(thisEntity:GetTeamNumber(), thisEntity.spawn_position, nil, 3*SIMPLE_BOSS_LEASH_SIZE, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, FIND_CLOSEST, false)
    if #nearby_enemies ~= 0 then
      for i = 1, #nearby_enemies do
        local enemy = nearby_enemies[i]
        if enemy and not enemy:IsNull() then
          if enemy:IsAlive() and not enemy:IsAttackImmune() and not enemy:IsInvulnerable() and not enemy:IsOutOfGame() and not enemy:HasModifier("modifier_item_buff_ward") and not enemy:IsCourier() and enemy:GetAttackRange() > SIMPLE_BOSS_LEASH_SIZE and (enemy:GetAbsOrigin() - thisEntity.spawn_position):Length2D() < 2*SIMPLE_BOSS_LEASH_SIZE then
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
        Queue = false,
      })
    end
    thisEntity.aggro_target = nearest_enemy
  end

  local function StartLeashing(thisEntity)
    thisEntity.aggro_target = nil
    thisEntity.state = SIMPLE_AI_STATE_LEASH
    return 1
  end

  if thisEntity.state == SIMPLE_AI_STATE_IDLE then
    local current_hp_pct = thisEntity:GetHealth()/thisEntity:GetMaxHealth()
    local aggro_hp_pct = SIMPLE_BOSS_AGGRO_HP_PERCENT/100
    if current_hp_pct < aggro_hp_pct then
      -- Issue an attack-move command towards the nearast unit that is attackable and assign it as aggro_target.
      -- Because of attack priorities (wards have the lowest attack priority) aggro_target will not always be
      -- the same as true aggro target (unit that is boss actually attacking at the moment)
      AttackNearestTarget(thisEntity)
      thisEntity.state = SIMPLE_AI_STATE_AGGRO
    else
      -- Check if the boss was messed around with displacing abilities (Force Staff for example)
      if (thisEntity.spawn_position - thisEntity:GetAbsOrigin()):Length2D() > 10 then
        thisEntity:MoveToPosition(thisEntity.spawn_position)
        thisEntity.state = SIMPLE_AI_STATE_LEASH
      end
    end
  elseif thisEntity.state == SIMPLE_AI_STATE_AGGRO then
    -- Check how far did the boss go from the spawn position
    if (thisEntity:GetAbsOrigin() - thisEntity.spawn_position):Length2D() > SIMPLE_BOSS_LEASH_SIZE then
      -- Check for actual aggro target
      if thisEntity:GetAggroTarget() and not thisEntity:GetAggroTarget():IsNull() then
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

    -- Check if aggro_target exists
    if thisEntity.aggro_target then
      --print(thisEntity.aggro_target:GetUnitName())
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
      local current_hp_pct = thisEntity:GetHealth()/thisEntity:GetMaxHealth()
      local aggro_hp_pct = SIMPLE_BOSS_AGGRO_HP_PERCENT/100
      if current_hp_pct > aggro_hp_pct then
        thisEntity.aggro_target = nil
      end
      -- Check if boss is stuck or idle because actual aggro target doesn't exist.
      if not thisEntity:GetAggroTarget() or thisEntity:IsIdle() then
        thisEntity.aggro_target = nil
      end
    else
      -- Check HP of the boss and if its able to attack
      local current_hp_pct = thisEntity:GetHealth()/thisEntity:GetMaxHealth()
      local aggro_hp_pct = SIMPLE_BOSS_AGGRO_HP_PERCENT/100
      if current_hp_pct < aggro_hp_pct then
        AttackNearestTarget(thisEntity)
      end

      if not thisEntity.aggro_target then
        thisEntity.state = SIMPLE_AI_STATE_LEASH
      end
    end

    local enemies = FindUnitsInRadius(thisEntity:GetTeamNumber(), thisEntity:GetAbsOrigin(), nil, 350, DOTA_UNIT_TARGET_TEAM_ENEMY, bit.bor(DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_BASIC), DOTA_UNIT_TARGET_FLAG_NONE, FIND_ANY_ORDER, false)
    if thisEntity.slam_ability and thisEntity.slam_ability:IsFullyCastable() and #enemies > 2 then
      ExecuteOrderFromTable({
        UnitIndex = thisEntity:entindex(),
        OrderType = DOTA_UNIT_ORDER_CAST_NO_TARGET,
        AbilityIndex = thisEntity.slam_ability:entindex(),
        Queue = false,
      })
    end
  elseif thisEntity.state == SIMPLE_AI_STATE_LEASH then
    -- Actual leashing
    thisEntity:MoveToPosition(thisEntity.spawn_position)
    -- Check if boss reached the spawn_position
    if (thisEntity.spawn_position - thisEntity:GetAbsOrigin()):Length2D() < 10 then
      -- Go into the idle state if the boss is back to the spawn position
      thisEntity:SetIdleAcquire(false)
      thisEntity:SetAcquisitionRange(0)
      thisEntity.state = SIMPLE_AI_STATE_IDLE
    end
  end
  return 1
end
