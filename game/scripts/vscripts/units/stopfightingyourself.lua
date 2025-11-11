local SIMPLE_AI_STATE_IDLE = 0
local SIMPLE_AI_STATE_AGGRO = 1
local SIMPLE_AI_STATE_LEASH = 2

local SIMPLE_BOSS_LEASH_SIZE = BOSS_LEASH_SIZE or 1200
local SIMPLE_BOSS_AGGRO_HP_PERCENT = 99

local function IllusionsCast(caster)
  local ability = caster.ABILITY_dupe_heroes
  if caster and not caster:IsNull() and ability and ability:IsFullyCastable() then
    caster:DispelWeirdDebuffs()

    local cast_point = ability:GetCastPoint()

    ExecuteOrderFromTable({
      UnitIndex = caster:entindex(),
      OrderType = DOTA_UNIT_ORDER_CAST_NO_TARGET,
      AbilityIndex = ability:entindex(),
      Queue = false,
    })

    return cast_point + 0.1
  end

  return 0.5
end

local function UseAbility(ability, caster, target, maxRange)
  if not ability then
    return
  end
  local not_good_items = {
    ["item_sphere"] = true,
    ["item_sphere_2"] = true,
    ["item_sphere_3"] = true,
    ["item_sphere_4"] = true,
    ["item_sphere_5"] = true,
  }
  if not_good_items[ability:GetName()] then
    return
  end

  local randomPosition = RandomVector(maxRange) + caster:GetAbsOrigin()
  local behavior = ability:GetBehavior()
  if type(behavior) == 'userdata' then
    behavior = tonumber(tostring(behavior))
  end

  -- Ability's behavior is
  if bit.band(behavior, DOTA_ABILITY_BEHAVIOR_PASSIVE) ~= 0 then --luacheck: ignore
    -- passive
    return
  elseif bit.band(behavior, DOTA_ABILITY_BEHAVIOR_AUTOCAST) ~= 0 and not ability:GetAutoCastState() then
    ExecuteOrderFromTable({
      UnitIndex = caster:entindex(),
      OrderType = DOTA_UNIT_ORDER_CAST_TOGGLE_AUTO,
      AbilityIndex = ability:entindex(), --Optional.  Only used when casting abilities
      Queue = false,
    })
  elseif bit.band(behavior, DOTA_ABILITY_BEHAVIOR_POINT) ~= 0 then
    -- point
    if IsValidEntity(target) then
      ExecuteOrderFromTable({
        UnitIndex = caster:entindex(),
        OrderType = DOTA_UNIT_ORDER_CAST_POSITION,
        AbilityIndex = ability:entindex(),
        Position = target:GetAbsOrigin(),
        Queue = false,
      })
    elseif randomPosition then
      ExecuteOrderFromTable({
        UnitIndex = caster:entindex(),
        OrderType = DOTA_UNIT_ORDER_CAST_POSITION,
        AbilityIndex = ability:entindex(), --Optional.  Only used when casting abilities
        Position = randomPosition,
        Queue = true
      })
    end
  elseif bit.band(behavior, DOTA_ABILITY_BEHAVIOR_NO_TARGET) ~= 0 then
    -- no target
    ExecuteOrderFromTable({
      UnitIndex = caster:entindex(),
      OrderType = DOTA_UNIT_ORDER_CAST_NO_TARGET,
      AbilityIndex = ability:entindex(), --Optional.  Only used when casting abilities
      Queue = false,
    })
  elseif bit.band(behavior, DOTA_ABILITY_BEHAVIOR_UNIT_TARGET) ~= 0 then
    -- target
    if IsValidEntity(target) then
      ExecuteOrderFromTable({
        UnitIndex = caster:entindex(),
        OrderType = DOTA_UNIT_ORDER_CAST_TARGET,
        TargetIndex = target:entindex(), --Optional.  Only used when targeting units
        AbilityIndex = ability:entindex(), --Optional.  Only used when casting abilities
        Queue = false,
      })
    end
  elseif bit.band(behavior, DOTA_ABILITY_BEHAVIOR_TOGGLE) ~= 0 and not ability:IsActivated() then
    -- toggle
    ExecuteOrderFromTable({
      UnitIndex = caster:entindex(),
      OrderType = DOTA_UNIT_ORDER_CAST_TOGGLE,
      AbilityIndex = ability:entindex(), --Optional.  Only used when casting abilities
      Queue = false,
    })
  end
end

local function ClosestHeroInRange(position, range)
  return FindUnitsInRadius(
    DOTA_TEAM_NEUTRALS,
    position,
    nil,
    range,
    DOTA_UNIT_TARGET_TEAM_ENEMY,
    DOTA_UNIT_TARGET_HERO,
    DOTA_UNIT_TARGET_FLAG_NONE,
    FIND_CLOSEST,
    false
  )[1]
end

local function UseRandomItem()
  local item = thisEntity:GetItemInSlot(RandomInt(DOTA_ITEM_SLOT_1, DOTA_ITEM_SLOT_6))

  if item ~= nil and item:IsItem() and not item:IsRecipe() then
    if item:IsFullyCastable() and item:IsOwnersManaEnough() then
      local target = ClosestHeroInRange(thisEntity:GetAbsOrigin(), BOSS_LEASH_SIZE)

      if target then
        UseAbility(item, thisEntity, target, BOSS_LEASH_SIZE)
      end
    end
  end
end

function StopFightingYourselfThink()
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
    thisEntity.state = SIMPLE_AI_STATE_IDLE
    thisEntity.aggro_target = nil
    thisEntity.BossTier = thisEntity.BossTier or 4
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

  local current_hp_pct = thisEntity:GetHealth() / thisEntity:GetMaxHealth()
  local aggro_hp_pct = SIMPLE_BOSS_AGGRO_HP_PERCENT / 100

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

    if ClosestHeroInRange(thisEntity:GetAbsOrigin(), SIMPLE_BOSS_LEASH_SIZE) then
      local dice_for_items = RandomFloat(0, 1)
      local dice_for_illusions = RandomFloat(0, 1)
      if current_hp_pct >= 75/100 then -- phase 1
        if dice_for_items <= 0.33 then
          UseRandomItem()
        end
        if dice_for_illusions <= 0.15 then
          return IllusionsCast(thisEntity)
        end
      elseif current_hp_pct >= 50/100 then -- phase 2
        if dice_for_items <= 0.66 then
          UseRandomItem()
        end
        if dice_for_illusions <= 0.3 then
          return IllusionsCast(thisEntity)
        end
      elseif current_hp_pct >= 25/100 then -- phase 3
        UseRandomItem()
        if dice_for_illusions <= 0.5 or thisEntity:GetUnitName() == "npc_dota_boss_stopfightingyourself_tier5" then
          return IllusionsCast(thisEntity)
        end
      else -- phase 4
        UseRandomItem()
        return IllusionsCast(thisEntity)
      end
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

  return 1
end

-- Entry Function
function Spawn(entityKeyValues) --luacheck: ignore Spawn
  if not thisEntity or not IsServer() then
    return
  end

  thisEntity.ABILITY_dupe_heroes = thisEntity:FindAbilityByName('boss_stopfightingyourself_dupe_heroes')

  --print("Starting AI for " .. thisEntity:GetUnitName() .. " " .. thisEntity:GetEntityIndex())
  thisEntity:SetContextThink('StopFightingYourselfThink', StopFightingYourselfThink, 1)
end
