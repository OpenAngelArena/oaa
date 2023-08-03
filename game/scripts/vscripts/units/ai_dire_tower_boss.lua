
function Spawn( entityKeyValues )
  if thisEntity == nil then
    return
  end

  if IsServer() == false then
    return
  end

  thisEntity.DIRE_TOWER_BOSS_SUMMONED_UNITS = {}
  thisEntity.DIRE_TOWER_BOSS_MAX_SUMMONS = 50
  thisEntity.nCAST_SUMMON_WAVE_ROUND = 1

  thisEntity.hSummonWaveAbility = thisEntity:FindAbilityByName( "dire_tower_boss_summon_wave" )

  thisEntity:SetContextThink( "DireTowerBossThink", DireTowerBossThink, 1 )
end


function DireTowerBossThink()
  if GameRules:State_Get() >= DOTA_GAMERULES_STATE_POST_GAME or not IsValidEntity(thisEntity) or not thisEntity:IsAlive() then
    return -1
  end

  if GameRules:IsGamePaused() then
    return 1
  end

  if not thisEntity.bInitialized then
    thisEntity.vInitialSpawnPos = thisEntity:GetOrigin()
    thisEntity.bHasAgro = false
    thisEntity.BossTier = thisEntity.BossTier or 4
    thisEntity.SiltBreakerProtection = true
    thisEntity.fAgroRange = thisEntity:GetAcquisitionRange()
    thisEntity:SetIdleAcquire(false)
    thisEntity:SetAcquisitionRange(0)
    thisEntity.bInitialized = true
  end

  local aggro_hp_pct = 1 - ((thisEntity.BossTier * BOSS_AGRO_FACTOR) / thisEntity:GetMaxHealth())
  local hasDamageThreshold = thisEntity:GetHealth() / thisEntity:GetMaxHealth() < aggro_hp_pct
  local fDistanceToOrigin = ( thisEntity:GetOrigin() - thisEntity.vInitialSpawnPos ):Length2D()
  local boss_hp_pct = thisEntity:GetHealth() / thisEntity:GetMaxHealth()

  if boss_hp_pct <= 1/3 then
      thisEntity.nCAST_SUMMON_WAVE_ROUND = 3
  elseif boss_hp_pct > 1/3 and boss_hp_pct <= 2/3 then
      thisEntity.nCAST_SUMMON_WAVE_ROUND = 2
  else
      thisEntity.nCAST_SUMMON_WAVE_ROUND = 1
  end


  if hasDamageThreshold then
    if not thisEntity.bHasAgro then
      DebugPrint("DIRE TOWER HAS AGGROED UH OH")
      thisEntity.bHasAgro = true
      thisEntity:SetIdleAcquire(true)
      thisEntity:SetAcquisitionRange(thisEntity.fAgroRange)
    end
  else
    if fDistanceToOrigin > 10 then
      return RetreatHome()
    end
    return 1
  end

  local hEnemies = {}
  local snipers = {}
  -- Agro
  if thisEntity.bHasAgro then
    hEnemies = FindUnitsInRadius(
      thisEntity:GetTeamNumber(),
      thisEntity.vInitialSpawnPos,
      nil,
      thisEntity:GetCurrentVisionRange(),
      DOTA_UNIT_TARGET_TEAM_ENEMY,
      DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_HERO,
      DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES + DOTA_UNIT_TARGET_FLAG_FOW_VISIBLE,
      FIND_CLOSEST,
      false
    )
    if #hEnemies == 0 then
      -- Check for snipers out of vision
      snipers = FindUnitsInRadius(
        thisEntity:GetTeamNumber(),
        thisEntity.vInitialSpawnPos,
        nil,
        3*BOSS_LEASH_SIZE,
        DOTA_UNIT_TARGET_TEAM_ENEMY,
        DOTA_UNIT_TARGET_ALL,
        DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES + DOTA_UNIT_TARGET_FLAG_NO_INVIS,
        FIND_CLOSEST,
        false
      )
      if #snipers == 0 then
        DebugPrint("DIRE TOWER HAS CHILLED")
        thisEntity.bHasAgro = false
        thisEntity:SetIdleAcquire(false)
        thisEntity:SetAcquisitionRange(0)
    end
    end
  end

  -- Leash
  if not thisEntity.bHasAgro or fDistanceToOrigin > 2000 then
    if fDistanceToOrigin > 10 then
      return RetreatHome()
    end
    return 1
  end

  -- Check that the children we have in our list are still valid
  for i, hSummonedUnit in ipairs( thisEntity.DIRE_TOWER_BOSS_SUMMONED_UNITS ) do
    if hSummonedUnit:IsNull() or (not hSummonedUnit:IsAlive()) then
      table.remove( thisEntity.DIRE_TOWER_BOSS_SUMMONED_UNITS, i )
    end
  end

  -- Have all minions died?
  if #thisEntity.DIRE_TOWER_BOSS_SUMMONED_UNITS == 0 and thisEntity.hSummonWaveAbility and thisEntity.hSummonWaveAbility:IsFullyCastable() then
    return CastSummonWave()
  end

  local function FindNearestValidUnit(entity, unit_group)
    for i = 1, #unit_group do
      local enemy = unit_group[i]
      if enemy and not enemy:IsNull() then
        if enemy:IsAlive() and not enemy:IsInvulnerable() and not enemy:IsOutOfGame() and not enemy:IsOther() and not enemy:IsCourier() and (enemy:GetAbsOrigin() - entity.vInitialSpawnPos):Length2D() < 2*BOSS_LEASH_SIZE then
          return enemy
        end
      end
    end
    return nil
  end

  local valid_enemy
  if #hEnemies == 0 then
    valid_enemy = FindNearestValidUnit(thisEntity, snipers)
  else
    valid_enemy = hEnemies[RandomInt(1, #hEnemies)]
  end

  if not valid_enemy then
    if fDistanceToOrigin > 10 then
      return RetreatHome()
    end
  end

  if #hEnemies == 0 then
    if fDistanceToOrigin > 10 then
      return RetreatHome()
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
  return 6
end

function CastSummonWave()
  ExecuteOrderFromTable({
    UnitIndex = thisEntity:entindex(),
    OrderType = DOTA_UNIT_ORDER_CAST_NO_TARGET,
    AbilityIndex = thisEntity.hSummonWaveAbility:entindex(),
  })
  return 0.6
end



