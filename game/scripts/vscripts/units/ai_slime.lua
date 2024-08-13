function Spawn( entityKeyValues )
  if not thisEntity or not IsServer() then
    return
  end

  thisEntity.hJumpAbility = thisEntity:FindAbilityByName( "boss_slime_jump" )
  thisEntity.hSlamAbility = thisEntity:FindAbilityByName( "boss_slime_slam" )
  thisEntity.hShakeAbility = thisEntity:FindAbilityByName( "boss_slime_shake" )

  thisEntity:SetContextThink( "SlimeBossThink", SlimeBossThink, 1 )
end

function SlimeBossThink()
  if GameRules:State_Get() >= DOTA_GAMERULES_STATE_POST_GAME or not IsValidEntity(thisEntity) or not thisEntity:IsAlive() then
    return -1
  end

  if GameRules:IsGamePaused() then
    return 1
  end

  if thisEntity:IsChanneling() or thisEntity:IsInvulnerable() or thisEntity:IsOutOfGame() then
    return 1
  end

  if not thisEntity.bInitialized then
    thisEntity.vInitialSpawnPos = thisEntity:GetAbsOrigin()
    thisEntity.bHasAgro = false
    thisEntity.BossTier = thisEntity.BossTier or 2
    thisEntity.SiltBreakerProtection = true
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
    DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
    DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES + DOTA_UNIT_TARGET_FLAG_FOW_VISIBLE,
    FIND_ANY_ORDER,
    false
  )

  local hasDamageThreshold = not thisEntity:HasAbility("boss_slime_split") or thisEntity:GetMaxHealth() - thisEntity:GetHealth() > thisEntity.BossTier * BOSS_AGRO_FACTOR
  local fDistanceToOrigin = ( thisEntity:GetOrigin() - thisEntity.vInitialSpawnPos ):Length2D()

  -- Remove debuff protection that was added during retreat
  thisEntity:RemoveModifierByName("modifier_anti_stun_oaa")

  -- Aggro
  if fDistanceToOrigin < 10 and thisEntity.bHasAgro and #enemies == 0 then
    thisEntity.bHasAgro = false
    thisEntity:SetIdleAcquire(false)
    thisEntity:SetAcquisitionRange(0)
    return 1
  elseif hasDamageThreshold and #enemies > 0 then
    if not thisEntity.bHasAgro then
      thisEntity.bHasAgro = true
      thisEntity:SetIdleAcquire(true)
      thisEntity:SetAcquisitionRange(thisEntity.fAgroRange)
    end
  end

  -- Leash
  if not thisEntity.bHasAgro or #enemies == 0 or fDistanceToOrigin > BOSS_LEASH_SIZE then
    if fDistanceToOrigin > 10 then
      return RetreatHome()
    end
    return 1
  end

  -- Slam
  if thisEntity.hSlamAbility and thisEntity.hSlamAbility:IsCooldownReady() then
    local target
    local count = 0
    for k,v in pairs(enemies) do
      local slamEnemies = thisEntity.hSlamAbility:FindTargets(v:GetAbsOrigin())
      if #slamEnemies > count and (thisEntity:GetAbsOrigin() - v:GetAbsOrigin()):Length2D() < BOSS_LEASH_SIZE then
        count = #slamEnemies
        target = v:GetAbsOrigin()
      end
    end

    if count > 0 and target then
      return CastSlam(target)
    end
  end

  -- Jump
  if thisEntity.hJumpAbility and thisEntity.hJumpAbility:IsCooldownReady() then
    local target
    local count = 0
    local targetMinRange = thisEntity.hJumpAbility:GetSpecialValueFor("target_min_range")
    for k,v in pairs(enemies) do
      local enemyLocation = v:GetAbsOrigin()
      local jumpEnemies = thisEntity.hJumpAbility:FindTargets(enemyLocation)
      local condition1 = #jumpEnemies > count
      local condition2 = (thisEntity.vInitialSpawnPos - enemyLocation):Length2D() <= BOSS_LEASH_SIZE
      local condition3 = (thisEntity:GetAbsOrigin() - enemyLocation):Length2D() > targetMinRange
      if condition1 and condition2 and condition3 then
        count = #jumpEnemies
        target = enemyLocation
      end
    end

    if count > 0 and target then
      return CastJump(target)
    end
  end

  return 0.5
end

function RetreatHome()
  -- Add Debuff Protection when leashing
  thisEntity:AddNewModifier(thisEntity, nil, "modifier_anti_stun_oaa", {})

  -- Leash
  ExecuteOrderFromTable({
    UnitIndex = thisEntity:entindex(),
    OrderType = DOTA_UNIT_ORDER_MOVE_TO_POSITION,
    Position = thisEntity.vInitialSpawnPos,
    Queue = false,
  })

  local speed = thisEntity:GetIdealSpeed()
  local location = thisEntity:GetAbsOrigin()
  local distance = (location - thisEntity.vInitialSpawnPos):Length2D()
  local retreat_time = distance / speed

  return retreat_time + 0.1
end

function CastJump(position)
  thisEntity:DispelWeirdDebuffs()

  local ability = thisEntity.hJumpAbility
  local cast_point = ability:GetCastPoint()
  local jump_distance_per_interval = ability:GetSpecialValueFor("movement_speed")
  local interval = 0.03

  local position = position or thisEntity:GetAbsOrigin()
  local jump_duration = interval / jump_distance_per_interval
  local think_time = cast_point + jump_duration

  ExecuteOrderFromTable({
    UnitIndex = thisEntity:entindex(),
    OrderType = DOTA_UNIT_ORDER_CAST_POSITION,
    AbilityIndex = ability:entindex(),
    Position = position,
    Queue = false,
  })

  return think_time + 1
end

function CastSlam(position)
  thisEntity:DispelWeirdDebuffs()

  local ability = thisEntity.hSlamAbility
  local cast_point = ability:GetCastPoint()
  local self_stun = ability:GetSpecialValueFor("self_stun")
  local max_range = ability:GetSpecialValueFor("target_max_range")
  local position = position or thisEntity:GetAbsOrigin() * thisEntity:GetForwardVector() * max_range
  local think_time = cast_point + self_stun

  ExecuteOrderFromTable({
    UnitIndex = thisEntity:entindex(),
    OrderType = DOTA_UNIT_ORDER_CAST_POSITION,
    AbilityIndex = ability:entindex(),
    Position = position,
    Queue = false,
  })

  return think_time + 0.1
end
