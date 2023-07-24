local AI_STATE_IDLE = 0
local AI_STATE_AGGRO = 1
local AI_STATE_LEASH = 2

local CARAPACE_BOSS_LEASH_SIZE = BOSS_LEASH_SIZE or 1200

function Spawn( entityKeyValues )
	if not thisEntity or not IsServer() then
    return
  end

	thisEntity.hHeadbuttAbility = thisEntity:FindAbilityByName( "boss_carapace_headbutt" )
	thisEntity:SetContextThink( "CarapaceBossThink", CarapaceBossThink, 1 )
end

function CarapaceBossThink()
	if GameRules:State_Get() >= DOTA_GAMERULES_STATE_POST_GAME or not IsValidEntity(thisEntity) or not thisEntity:IsAlive() then
    return -1
  end

  if GameRules:IsGamePaused() or thisEntity.hHeadbuttAbility:IsInAbilityPhase() then
    return 1
  end

  if Duels:IsActive() then
    thisEntity.aggro_target = nil
  end

  if not thisEntity.initialized then
    thisEntity.spawn_position = thisEntity:GetAbsOrigin()
    thisEntity.state = AI_STATE_IDLE
    thisEntity.aggro_target = nil
    thisEntity.BossTier = thisEntity.BossTier or 2
    thisEntity.SiltBreakerProtection = true
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
    local nearby_enemies = FindUnitsInRadius(thisEntity:GetTeamNumber(), thisEntity.spawn_position, nil, CARAPACE_BOSS_LEASH_SIZE, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, bit.bor(DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, DOTA_UNIT_TARGET_FLAG_FOW_VISIBLE), FIND_CLOSEST, false)
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
    nearby_enemies = FindUnitsInRadius(thisEntity:GetTeamNumber(), thisEntity.spawn_position, nil, 3*CARAPACE_BOSS_LEASH_SIZE, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, FIND_CLOSEST, false)
    if #nearby_enemies ~= 0 then
      for i = 1, #nearby_enemies do
        local enemy = nearby_enemies[i]
        if enemy and not enemy:IsNull() then
          if enemy:IsAlive() and not enemy:IsAttackImmune() and not enemy:IsInvulnerable() and not enemy:IsOutOfGame() and not IsNonHostileWard(enemy) and not enemy:IsCourier() and enemy:GetAttackRange() > CARAPACE_BOSS_LEASH_SIZE and (enemy:GetAbsOrigin() - thisEntity.spawn_position):Length2D() < 2*CARAPACE_BOSS_LEASH_SIZE then
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
    thisEntity.state = AI_STATE_LEASH
    return 1
  end

  local current_hp_pct = thisEntity:GetHealth() / thisEntity:GetMaxHealth()
  local aggro_hp_pct = 1 - ((thisEntity.BossTier * BOSS_AGRO_FACTOR) / thisEntity:GetMaxHealth())

  if thisEntity.state == AI_STATE_IDLE then
    if current_hp_pct < aggro_hp_pct then
      -- Issue an attack-move command towards the nearast unit that is attackable and assign it as aggro_target.
      -- Because of attack priorities (wards have the lowest attack priority) aggro_target will not always be
      -- the same as true aggro target (unit that is boss actually attacking at the moment)
      AttackNearestTarget(thisEntity)
      thisEntity.state = AI_STATE_AGGRO
    else
      -- Check if the boss was messed around with displacing abilities (Force Staff for example)
      if (thisEntity.spawn_position - thisEntity:GetAbsOrigin()):Length2D() > 10 then
        thisEntity:MoveToPosition(thisEntity.spawn_position)
        thisEntity.state = AI_STATE_LEASH
      end
    end
  elseif thisEntity.state == AI_STATE_AGGRO then
    -- Check how far did the boss go from the spawn position
    if (thisEntity:GetAbsOrigin() - thisEntity.spawn_position):Length2D() > CARAPACE_BOSS_LEASH_SIZE then
      -- Check for actual aggro target
      if thisEntity:GetAggroTarget() and not thisEntity:GetAggroTarget():IsNull() then
        local true_aggro_target = thisEntity:GetAggroTarget()
        -- Prevent bosses chasing Snipers all over the map (its funny though)
        if (true_aggro_target:GetAbsOrigin() - thisEntity.spawn_position):Length2D() > 2*CARAPACE_BOSS_LEASH_SIZE then
          return StartLeashing(thisEntity)
        elseif (true_aggro_target:GetAbsOrigin() - thisEntity.spawn_position):Length2D() > CARAPACE_BOSS_LEASH_SIZE then
          -- Check attack range of true aggro target, if its less than leash/aggro range, start leashing
          if true_aggro_target:GetAttackRange() <= CARAPACE_BOSS_LEASH_SIZE then
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
      if (aggro_target:GetAbsOrigin() - thisEntity.spawn_position):Length2D() > 2*CARAPACE_BOSS_LEASH_SIZE then
        thisEntity.aggro_target = nil
      elseif (aggro_target:GetAbsOrigin() - thisEntity.spawn_position):Length2D() > CARAPACE_BOSS_LEASH_SIZE then
        -- Check aggro_target attack range, if its less than leash/aggro range
        if aggro_target:GetAttackRange() <= CARAPACE_BOSS_LEASH_SIZE then
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
        thisEntity.state = AI_STATE_LEASH
      end
    end

    if thisEntity.hHeadbuttAbility and thisEntity.hHeadbuttAbility:IsCooldownReady() then
      local headbuttEnemies = thisEntity.hHeadbuttAbility:GetEnemies()

      if #headbuttEnemies > 0 then
        return CastHeadbutt()
      end
    end
  elseif thisEntity.state == AI_STATE_LEASH then
    -- Actual leashing
    thisEntity:MoveToPosition(thisEntity.spawn_position)
    -- Check if boss reached the spawn_position
    if (thisEntity.spawn_position - thisEntity:GetAbsOrigin()):Length2D() < 10 then
      -- Go into the idle state if the boss is back to the spawn position
      thisEntity:SetIdleAcquire(false)
      thisEntity:SetAcquisitionRange(0)
      thisEntity.state = AI_STATE_IDLE
    end
  end

  return 1
end

function CastHeadbutt()
	thisEntity:Stop()
	ExecuteOrderFromTable({
		UnitIndex = thisEntity:entindex(),
		OrderType = DOTA_UNIT_ORDER_CAST_NO_TARGET,
		AbilityIndex = thisEntity.hHeadbuttAbility:entindex(),
	})

	return 4.0
end
