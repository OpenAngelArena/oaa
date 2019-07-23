local SIMPLE_AI_STATE_IDLE = 0
local SIMPLE_AI_STATE_AGGRO = 1
local SIMPLE_AI_STATE_LEASH = 2

local SIMPLE_BOSS_LEASH_SIZE = BOSS_LEASH_SIZE or 1200
local SIMPLE_BOSS_AGGRO_HP_PERCENT = 98

function Spawn( entityKeyValues )
  if not thisEntity or not IsServer() then
    return
  end
  thisEntity:SetContextThink("SimpleBossThink", SimpleBossThink, 1)
end

function SimpleBossThink()
  if GameRules:IsGamePaused() == true or GameRules:State_Get() == DOTA_GAMERULES_STATE_POST_GAME or thisEntity:IsAlive() == false then
    return 1
  end

  if Duels:IsActive() then
    thisEntity:Stop()
    return 1
  end

  if not thisEntity.initialized then
    thisEntity.spawn_position = thisEntity:GetAbsOrigin()
    thisEntity.state = SIMPLE_AI_STATE_IDLE
    thisEntity.aggro_target = nil
    thisEntity:SetIdleAcquire(false)
    thisEntity:SetAcquisitionRange(0)
    thisEntity.initialized = true
  end

  if thisEntity.state == SIMPLE_AI_STATE_IDLE then
    local current_hp_pct = thisEntity:GetHealth()/thisEntity:GetMaxHealth()
    local aggro_hp_pct = SIMPLE_BOSS_AGGRO_HP_PERCENT/100
    if current_hp_pct < aggro_hp_pct then
      --thisEntity:SetIdleAcquire(true)     -- It seems this is not helping
      --thisEntity:SetAcquisitionRange(128) -- It seems this is not helping
      local nearby_enemies = FindUnitsInRadius(thisEntity:GetTeamNumber(), thisEntity.spawn_position, nil, SIMPLE_BOSS_LEASH_SIZE, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, bit.bor(DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, DOTA_UNIT_TARGET_FLAG_FOW_VISIBLE), FIND_CLOSEST, false)
      if #nearby_enemies == 0 then
        nearby_enemies = FindUnitsInRadius(thisEntity:GetTeamNumber(), thisEntity.spawn_position, nil, 3*SIMPLE_BOSS_LEASH_SIZE, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, bit.bor(DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, DOTA_UNIT_TARGET_FLAG_FOW_VISIBLE), FIND_CLOSEST, false)
      end
      -- Filter out couriers and invisible units
      if #nearby_enemies ~= 0 then
        for i=1,#nearby_enemies do
          if nearby_enemies[i] then
            if nearby_enemies[i]:IsCourier() or nearby_enemies[i]:IsInvisible() then
              table.remove(nearby_enemies,i)
            end
          end
        end
      end
      -- Find nearest enemy that a boss can attack and assign it as aggro_target
      local nearest_enemy
      if #nearby_enemies ~= 0 then
        nearest_enemy = nearby_enemies[1]
      end
      if nearest_enemy then
        ExecuteOrderFromTable({
          UnitIndex = thisEntity:entindex(),
          OrderType = DOTA_UNIT_ORDER_ATTACK_MOVE,
          Position = nearest_enemy:GetAbsOrigin(),
          Queue = 0,
        })
      end
      thisEntity.aggro_target = nearest_enemy
      thisEntity.state = SIMPLE_AI_STATE_AGGRO
    else
      -- Check if the boss was messed around with displacing abilities (Force Staff for example)
      if (thisEntity.spawn_position - thisEntity:GetAbsOrigin()):Length2D() > 10 then
        thisEntity:MoveToPosition(thisEntity.spawn_position)
        thisEntity.state = SIMPLE_AI_STATE_LEASH
      end
    end
  elseif thisEntity.state == SIMPLE_AI_STATE_AGGRO then
    --print("AGGRO STATE")
    -- Check how far did the boss go from the spawn position
    if (thisEntity:GetAbsOrigin() - thisEntity.spawn_position):Length2D() > SIMPLE_BOSS_LEASH_SIZE then
      -- Remove aggro_target if boss goes outside of leash range
      if thisEntity.aggro_target then
        thisEntity.aggro_target = nil
      end
      -- Find units that attacked the boss outside of leash range (Sniper and other high attack range units)
      local enemies = FindUnitsInRadius(thisEntity:GetTeamNumber(), thisEntity.spawn_position, nil, 3*SIMPLE_BOSS_LEASH_SIZE, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, bit.bor(DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, DOTA_UNIT_TARGET_FLAG_FOW_VISIBLE), FIND_CLOSEST, false)
      if #enemies ~=0 then
        for i=1,#enemies do
          local enemy = enemies[i]
          if enemy:IsAttackingEntity(thisEntity) and enemy:GetAttackRange() > SIMPLE_BOSS_LEASH_SIZE then
            thisEntity.aggro_target = enemy
            break
          end
        end
      else
        -- No enemies so no need for aggro_target
        thisEntity.aggro_target = nil
      end
    end

    -- Check if aggro_target exists
    if thisEntity.aggro_target then
      -- Check if aggro_target is getting deleted soon from c++
      if thisEntity.aggro_target:IsNull() then
        thisEntity.aggro_target = nil
        return 1
      end
      -- Check if aggro_target is dead or attack immune (ethereal) or a courier or invisible
      if thisEntity.aggro_target:IsAlive() and not thisEntity.aggro_target:IsAttackImmune() and not thisEntity.aggro_target:IsCourier() and not thisEntity.aggro_target:IsInvisible() then
        thisEntity:MoveToTargetToAttack(thisEntity.aggro_target)
      else
        -- Don't try to attack dead units, attack-immune units, invisible units or couriers
        thisEntity.aggro_target = nil
      end
    else
      -- Boss goes back angry (attack-moving to the spawn position) because he can't attack
      ExecuteOrderFromTable({
        UnitIndex = thisEntity:entindex(),
        OrderType = DOTA_UNIT_ORDER_ATTACK_MOVE,
        Position = thisEntity.spawn_position,
        Queue = 0,
      })

      thisEntity.state = SIMPLE_AI_STATE_LEASH
    end
  elseif thisEntity.state == SIMPLE_AI_STATE_LEASH then
    --print("LEASHING STATE")
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
