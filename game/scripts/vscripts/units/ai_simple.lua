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
    local current_hp_pct = thisEntity:GetHealth() / thisEntity:GetMaxHealth()
    local aggro_hp_pct = SIMPLE_BOSS_AGGRO_HP_PERCENT/100
    if current_hp_pct < aggro_hp_pct then
      thisEntity:SetIdleAcquire(true)
      thisEntity:SetAcquisitionRange(128)
      local nearby_enemies = FindUnitsInRadius(thisEntity:GetTeamNumber(), thisEntity.spawn_position, nil, SIMPLE_BOSS_LEASH_SIZE, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, bit.bor(DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, DOTA_UNIT_TARGET_FLAG_FOW_VISIBLE), FIND_CLOSEST, false)
      if #nearby_enemies == 0 then
        nearby_enemies = FindUnitsInRadius(thisEntity:GetTeamNumber(), thisEntity.spawn_position, nil, 3*SIMPLE_BOSS_LEASH_SIZE, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, bit.bor(DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, DOTA_UNIT_TARGET_FLAG_FOW_VISIBLE), FIND_CLOSEST, false)
      end
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
      -- Check if the boss was messed around with displacing abilities (Force staff)
      if (thisEntity.spawn_position - thisEntity:GetAbsOrigin()):Length2D() > 10 then
        thisEntity:MoveToPosition(thisEntity.spawn_position)
        thisEntity.state = SIMPLE_AI_STATE_LEASH
      end
    end
  elseif thisEntity.state == SIMPLE_AI_STATE_AGGRO then
    local current_position = thisEntity:GetAbsOrigin()
    -- Check how far did the boss go from the spawn position
    if (current_position - thisEntity.spawn_position):Length2D() > SIMPLE_BOSS_LEASH_SIZE then
      -- Find the hero that aggroed the boss outside of leash range (Sniper and other high attack range heroes)
      local enemies = FindUnitsInRadius(thisEntity:GetTeamNumber(), thisEntity.spawn_position, nil, 3*SIMPLE_BOSS_LEASH_SIZE, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, bit.bor(DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, DOTA_UNIT_TARGET_FLAG_FOW_VISIBLE), FIND_CLOSEST, false)
      if #enemies ~=0 then
        for i=1,#enemies do
          local enemy = enemies[i]
          if enemy:IsAttackingEntity(thisEntity) and enemy:GetAttackRange() > SIMPLE_BOSS_LEASH_SIZE then
            thisEntity.aggro_target = enemy
            break
          end
        end
        if thisEntity.aggro_target then
          if thisEntity.aggro_target:IsAlive() and not thisEntity.aggro_target:IsAttackImmune() then
            thisEntity:MoveToTargetToAttack(thisEntity.aggro_target)
            --ExecuteOrderFromTable({
              --UnitIndex = thisEntity:entindex(),
              --OrderType = DOTA_UNIT_ORDER_ATTACK_MOVE,
              --Position = ,
              --Queue = 0,
            --})
          end
        else
          -- There are no aggresive enemies, go back to spawn location
          thisEntity:MoveToPosition(thisEntity.spawn_position)
          thisEntity.state = SIMPLE_AI_STATE_LEASH
        end
      else
        -- There are no enemies, go back to spawn location
        thisEntity:MoveToPosition(thisEntity.spawn_position)
        --ExecuteOrderFromTable({
          --UnitIndex = thisEntity:entindex(),
          --OrderType = DOTA_UNIT_ORDER_ATTACK_MOVE, DOTA_UNIT_ORDER_MOVE_TO_POSITION
          --Position = thisEntity.spawn_position,
          --Queue = 0,
        --})
        thisEntity.state = SIMPLE_AI_STATE_LEASH
      end
    else
      -- Boss is still within leash range and aggroed
      -- Check if aggro_target is dead or attack immune
      if thisEntity.aggro_target then
        if thisEntity.aggro_target:IsAlive() and not thisEntity.aggro_target:IsAttackImmune() then
          thisEntity:MoveToTargetToAttack(thisEntity.aggro_target)
        else
          thisEntity:MoveToPosition(thisEntity.spawn_position)
          thisEntity.state = SIMPLE_AI_STATE_LEASH
        end
      else
        thisEntity:MoveToPosition(thisEntity.spawn_position)
        thisEntity.state = SIMPLE_AI_STATE_LEASH
      end
    end

  elseif thisEntity.state == SIMPLE_AI_STATE_LEASH then
    if (thisEntity.spawn_position - thisEntity:GetAbsOrigin()):Length2D() < 10 then
      -- Go into the idle state if the boss is back to the spawn position
      thisEntity:SetIdleAcquire(false)
      thisEntity:SetAcquisitionRange(0)
      thisEntity.state = SIMPLE_AI_STATE_IDLE
    end
  end

  return 1
end
