local SIMPLE_AI_STATE_IDLE = 0
local SIMPLE_AI_STATE_AGGRO = 1
local SIMPLE_AI_STATE_TEMP = 2

function Spawn( entityKeyValues )
  if not thisEntity or not IsServer() then
    return
  end

  thisEntity.DIRE_TOWER_BOSS_SUMMONED_UNITS = {}
  thisEntity.DIRE_TOWER_BOSS_MAX_SUMMONS = 20
  thisEntity.nCAST_SUMMON_WAVE_ROUND = 1

  thisEntity.hSummonWaveAbility = thisEntity:FindAbilityByName( "dire_tower_boss_summon_wave" )
  thisEntity.hGlyphAbility = thisEntity:FindAbilityByName( "dire_tower_boss_glyph" )

  thisEntity:SetContextThink( "DireTowerBossThink", DireTowerBossThink, 1 )
end

function DireTowerBossThink()
  if GameRules:State_Get() >= DOTA_GAMERULES_STATE_POST_GAME or not IsValidEntity(thisEntity) or not thisEntity:IsAlive() then
    return -1
  end

  if GameRules:IsGamePaused() then
    return 1
  end

  if Duels:IsActive() then
    thisEntity.aggro_target = nil
  end

  if not thisEntity.initialized then
    thisEntity.spawn_position = thisEntity:GetAbsOrigin()
    thisEntity.BossTier = thisEntity.BossTier or 3
    thisEntity.SiltBreakerProtection = true
    thisEntity.state = SIMPLE_AI_STATE_IDLE
    thisEntity.aggro_target = nil
    thisEntity.minion_target = nil
    thisEntity.attack_range = thisEntity:GetAttackRange() -- aggro range of the boss because the boss cannot move
    thisEntity:SetIdleAcquire(false)
    thisEntity:SetAcquisitionRange(0)
    thisEntity.initialized = true
  end

  -- Check if the boss was messed around with displacing abilities (Force Staff for example)
  if (thisEntity.spawn_position - thisEntity:GetAbsOrigin()):Length2D() > 10 then
    thisEntity:SetAbsOrigin(thisEntity.spawn_position)
    thisEntity:AddNewModifier(thisEntity, nil, "modifier_phased", {duration = FrameTime()})
  end

  local function IsNonHostileWard(entity)
    if entity.HasModifier then
      return entity:HasModifier("modifier_item_buff_ward") or entity:HasModifier("modifier_ward_invisibility")
    end
    return false
  end

  local function FindNearestAttackableUnit(thisEntity)
    local nearby_enemies = FindUnitsInRadius(thisEntity:GetTeamNumber(), thisEntity.spawn_position, nil, thisEntity.attack_range, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, bit.bor(DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, DOTA_UNIT_TARGET_FLAG_FOW_VISIBLE), FIND_CLOSEST, false)
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
    return nil
  end

  local function AttackNearestTarget(thisEntity)
    local nearest_enemy = FindNearestAttackableUnit(thisEntity)
    if nearest_enemy then
      ExecuteOrderFromTable({
        UnitIndex = thisEntity:entindex(),
        OrderType = DOTA_UNIT_ORDER_ATTACK_MOVE, --DOTA_UNIT_ORDER_ATTACK_TARGET,
        --TargetIndex = nearest_enemy:entindex(),
        Position = nearest_enemy:GetAbsOrigin(),
        Queue = false,
      })
    end
    thisEntity.aggro_target = nearest_enemy
  end

  local current_hp_pct = thisEntity:GetHealth() / thisEntity:GetMaxHealth()
  local aggro_hp_pct = 1 - ((thisEntity.BossTier * BOSS_AGRO_FACTOR) / thisEntity:GetMaxHealth())

  if thisEntity.state == SIMPLE_AI_STATE_IDLE then
    if current_hp_pct < aggro_hp_pct then
      -- Issue an attack command on the nearast unit that is attackable and assign it as aggro_target.
      AttackNearestTarget(thisEntity)
      thisEntity.state = SIMPLE_AI_STATE_AGGRO
    end
  elseif thisEntity.state == SIMPLE_AI_STATE_AGGRO then
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
      -- Check HP of the boss
      if current_hp_pct > aggro_hp_pct then
        thisEntity.aggro_target = nil
      end

      -- Check if actual aggro target exists
      local actual_aggro_target = thisEntity:GetAggroTarget()
      if not actual_aggro_target or actual_aggro_target:IsNull() then
        thisEntity.aggro_target = nil
      elseif not actual_aggro_target:IsAlive() then
        thisEntity.aggro_target = nil
      end

      -- Check if boss is idle
      if thisEntity:IsIdle() then
        thisEntity.aggro_target = nil
      end
    else
      -- Check HP of the boss
      if current_hp_pct < aggro_hp_pct then
        AttackNearestTarget(thisEntity)
      end

      if not thisEntity.aggro_target then
        thisEntity.state = SIMPLE_AI_STATE_TEMP
      end
    end

    -- Find the target for the minions if there is no attackable unit within tower attack range
    -- this is to make minions less idle
    if not thisEntity.minion_target then
      thisEntity.minion_target = FindNearestAttackableUnit(thisEntity) -- inital and fallback value
      local snipers = FindUnitsInRadius(thisEntity:GetTeamNumber(), thisEntity.spawn_position, nil, 2.5*thisEntity.attack_range, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, FIND_CLOSEST, false)
      if #snipers ~= 0 then
        for i = 1, #snipers do
          local enemy = snipers[i]
          if enemy and not enemy:IsNull() then
            -- Check if enemy is attackable
            if enemy:IsAlive() and not enemy:IsAttackImmune() and not enemy:IsInvulnerable() and not enemy:IsOutOfGame() and not IsNonHostileWard(enemy) and not enemy:IsCourier() then
              -- Check enemy location
              local loc = enemy:GetAbsOrigin()
              local distance = (loc - thisEntity.spawn_position):Length2D()
              if distance >= thisEntity.attack_range and distance < 2*thisEntity.attack_range then
                thisEntity.minion_target = enemy
                break
              end
            end
          end
        end
      end
    end

    -- Sound
    if not thisEntity.emitedsound then
      local sound_source
      if thisEntity.aggro_target and not thisEntity.aggro_target:IsNull() then
        sound_source = thisEntity.aggro_target
      elseif thisEntity:GetAggroTarget() and not thisEntity:GetAggroTarget():IsNull() then
        sound_source = thisEntity:GetAggroTarget()
      elseif thisEntity.minion_target and not thisEntity.minion_target:IsNull() then
        sound_source = thisEntity.minion_target
      else
        sound_source = thisEntity
      end
      if sound_source and not sound_source:IsNull() then
        sound_source:EmitSound("Dire_Tower_Boss.Aggro")
      end
      thisEntity.emitedsound = true
    end

    -- Phases
    if current_hp_pct <= 1/3 then
      thisEntity.nCAST_SUMMON_WAVE_ROUND = 3
    elseif current_hp_pct > 1/3 and current_hp_pct <= 2/3 then
      thisEntity.nCAST_SUMMON_WAVE_ROUND = 2
    else
      thisEntity.nCAST_SUMMON_WAVE_ROUND = 1
    end

    -- Glyph if less than 2/3 of HP
    if thisEntity.nCAST_SUMMON_WAVE_ROUND ~= 1 and thisEntity.hGlyphAbility and thisEntity.hGlyphAbility:IsFullyCastable() then
      return CastGlyph()
    end

    for i, hSummonedUnit in ipairs( thisEntity.DIRE_TOWER_BOSS_SUMMONED_UNITS ) do
      if hSummonedUnit:IsNull() or (not hSummonedUnit:IsAlive()) then
        table.remove( thisEntity.DIRE_TOWER_BOSS_SUMMONED_UNITS, i )
      end
    end

    -- Check how many of the summoned units are actually alive
    local count = 0
    for _, v in pairs( thisEntity.DIRE_TOWER_BOSS_SUMMONED_UNITS ) do
      if v and not v:IsNull() then
        if v:IsAlive() then
          count = count + 1
        end
      end
    end

    -- Have we hit our minion limit?
    if count < thisEntity.DIRE_TOWER_BOSS_MAX_SUMMONS and (thisEntity.aggro_target or thisEntity.minion_target) then
      if thisEntity.hSummonWaveAbility and thisEntity.hSummonWaveAbility:IsFullyCastable() then
        return CastSummonWave()
      end
    end
  elseif thisEntity.state == SIMPLE_AI_STATE_TEMP then
    -- Go into the idle state
    thisEntity:SetIdleAcquire(false)
    thisEntity:SetAcquisitionRange(0)
    thisEntity:Interrupt()
    thisEntity:Stop()
    thisEntity:Hold()
    thisEntity.state = SIMPLE_AI_STATE_IDLE
    thisEntity.emitedsound = false
    -- Check HP of the boss
    if current_hp_pct > aggro_hp_pct then
      thisEntity.minion_target = nil
      thisEntity.emitedsound = false
    end
  end

  return 1
end

function CastSummonWave()
  thisEntity:DispelWeirdDebuffs()

  local ability = thisEntity.hSummonWaveAbility
  ExecuteOrderFromTable({
    UnitIndex = thisEntity:entindex(),
    OrderType = DOTA_UNIT_ORDER_CAST_NO_TARGET,
    AbilityIndex = ability:entindex(),
    Queue = false,
  })
  return ability:GetCastPoint() + 0.1
end

function CastGlyph()
  -- Dispel all debuffs (99.99% at least)
  thisEntity:Purge(false, true, false, true, true)
  thisEntity:DispelUndispellableDebuffs()

  local ability = thisEntity.hGlyphAbility
  ExecuteOrderFromTable({
    UnitIndex = thisEntity:entindex(),
    OrderType = DOTA_UNIT_ORDER_CAST_NO_TARGET,
    AbilityIndex = ability:entindex(),
    Queue = false,
  })
  return ability:GetCastPoint() + 0.1
end
