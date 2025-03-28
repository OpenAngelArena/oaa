local SIMPLE_AI_STATE_IDLE = 0
local SIMPLE_AI_STATE_AGGRO = 1
local SIMPLE_AI_STATE_LEASH = 2

local SIMPLE_BOSS_LEASH_SIZE = 400
local SIMPLE_BOSS_AGGRO_HP_PERCENT = 99

local rune_modifiers = {
  "modifier_rune_invis",
  "modifier_rune_doubledamage",
  "modifier_rune_regen",
  "modifier_rune_arcane",
  "modifier_rune_haste",
  "modifier_rune_shield",
}

function Spawn( entityKeyValues )
  if not thisEntity or not IsServer() then
    return
  end
  thisEntity:SetContextThink("RuneProtectorThink", RuneProtectorThink, 1)
end

function RuneProtectorThink()
  if GameRules:State_Get() >= DOTA_GAMERULES_STATE_POST_GAME or not IsValidEntity(thisEntity) or not thisEntity:IsAlive() then
    return -1
  end

  if thisEntity:IsDominated() or thisEntity:IsIllusion() then
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
    thisEntity.state = SIMPLE_AI_STATE_IDLE
    thisEntity.aggro_target = nil
    thisEntity:SetIdleAcquire(false)
    thisEntity:SetAcquisitionRange(0)
    thisEntity:AddNewModifier(thisEntity, nil, "modifier_phased", {duration = FrameTime()}) -- for unstucking
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
    nearby_enemies = FindUnitsInRadius(thisEntity:GetTeamNumber(), thisEntity.spawn_position, nil, 6*SIMPLE_BOSS_LEASH_SIZE, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, FIND_CLOSEST, false)
    if #nearby_enemies ~= 0 then
      for i = 1, #nearby_enemies do
        local enemy = nearby_enemies[i]
        if enemy and not enemy:IsNull() then
          if enemy:IsAlive() and not enemy:IsAttackImmune() and not enemy:IsInvulnerable() and not enemy:IsOutOfGame() and not IsNonHostileWard(enemy) and not enemy:IsCourier() and enemy:GetAttackRange() > SIMPLE_BOSS_LEASH_SIZE and (enemy:GetAbsOrigin() - thisEntity.spawn_position):Length2D() < 4*SIMPLE_BOSS_LEASH_SIZE then
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

  local heroes = FindUnitsInRadius(
    thisEntity:GetTeamNumber(),
    thisEntity:GetAbsOrigin(),
    nil,
    SIMPLE_BOSS_LEASH_SIZE,
    DOTA_UNIT_TARGET_TEAM_ENEMY,
    DOTA_UNIT_TARGET_HERO,
    DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES,
    FIND_ANY_ORDER,
    false
  )

  local current_hp_pct = thisEntity:GetHealth() / thisEntity:GetMaxHealth()
  local aggro_hp_pct = SIMPLE_BOSS_AGGRO_HP_PERCENT / 100

  -- Trigger aggro if there are heroes nearby
  if #heroes > 0 and current_hp_pct > aggro_hp_pct then
    -- Apply damage
    local damage_table = {
      attacker = heroes[1],
      victim = thisEntity,
      damage = 1 + thisEntity:GetMaxHealth() * (1 - aggro_hp_pct),
      damage_type = DAMAGE_TYPE_PURE,
      damage_flags = DOTA_DAMAGE_FLAG_NONE,
    }

    ApplyDamage(damage_table)
  end

  -- Purge rune buffs from heroes around thisEntity no matter the state
  if #heroes > 0 then
    for _, hero in pairs(heroes) do
      if hero and not hero:IsNull() then
        for i = 1, #rune_modifiers do
          hero:RemoveModifierByName(rune_modifiers[i])
        end
      end
    end
  end

  if thisEntity.state == SIMPLE_AI_STATE_IDLE then
    -- Remove debuff protection
    thisEntity:RemoveModifierByName("modifier_anti_stun_oaa")
    -- Check boss hp
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
        if (true_aggro_target:GetAbsOrigin() - thisEntity.spawn_position):Length2D() > 4*SIMPLE_BOSS_LEASH_SIZE then
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
      if (aggro_target:GetAbsOrigin() - thisEntity.spawn_position):Length2D() > 4*SIMPLE_BOSS_LEASH_SIZE then
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
      -- OLD: if not thisEntity.aggro_target:IsAttackingEntity(thisEntity) then
      -- OLD: thisEntity:MoveToTargetToAttack(thisEntity.aggro_target)
    else
      -- Check HP of the boss and if its able to attack
      if current_hp_pct < aggro_hp_pct then -- not thisEntity:IsOutOfGame() and not thisEntity:IsDisarmed() then
        AttackNearestTarget(thisEntity)
      end

      if not thisEntity.aggro_target then
        thisEntity.state = SIMPLE_AI_STATE_LEASH
      end
    end
  elseif thisEntity.state == SIMPLE_AI_STATE_LEASH then
    -- Add Debuff Protection when leashing
    thisEntity:AddNewModifier(thisEntity, nil, "modifier_anti_stun_oaa", {})
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
