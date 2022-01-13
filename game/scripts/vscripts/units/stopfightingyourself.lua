local GLOBAL_origin = nil
local ABILITY_dupe_heroes = nil

local function IllusionsCast()
  if ABILITY_dupe_heroes:IsFullyCastable() then
    ExecuteOrderFromTable({
      UnitIndex = thisEntity:entindex(),
      OrderType = DOTA_UNIT_ORDER_CAST_NO_TARGET,
      AbilityIndex = ABILITY_dupe_heroes:entindex(), --Optional.  Only used when casting abilities
      Queue = true
    })
  end
end

local function UseAbility(ability, caster, target, maxRange)
  local randomPosition = RandomVector(maxRange) + caster:GetAbsOrigin()
  local behavior = ability:GetBehavior()
  if type(behavior) == 'userdata' then
    behavior = tonumber(tostring(behavior))
  end

  -- Ability's behavior is
  if bit.band(behavior, DOTA_ABILITY_BEHAVIOR_PASSIVE) ~= 0 then --luacheck: ignore
    -- passive
  elseif bit.band(behavior, DOTA_ABILITY_BEHAVIOR_AUTOCAST) ~= 0 and not ability:GetAutoCastState() then
    ExecuteOrderFromTable({
      UnitIndex = caster:entindex(),
      OrderType = DOTA_UNIT_ORDER_CAST_TOGGLE_AUTO,
      AbilityIndex = ability:entindex(), --Optional.  Only used when casting abilities
      Queue = 0 --Optional.  Used for queueing up abilities
    })
  elseif bit.band(behavior, DOTA_ABILITY_BEHAVIOR_POINT) ~= 0 then
    -- point
    if IsValidEntity(target) then
      ExecuteOrderFromTable({
        UnitIndex = caster:entindex(),
        OrderType = DOTA_UNIT_ORDER_CAST_POSITION,
        AbilityIndex = ability:entindex(),
        Position = target:GetAbsOrigin(),
        Queue = 1
      })
    elseif randomPosition then
      ExecuteOrderFromTable({
        UnitIndex = caster:entindex(),
        OrderType = DOTA_UNIT_ORDER_CAST_POSITION,
        AbilityIndex = ability:entindex(), --Optional.  Only used when casting abilities
        Position = randomPosition,
        Queue = 1 --Optional.  Used for queueing up abilities
      })
    end
  elseif bit.band(behavior, DOTA_ABILITY_BEHAVIOR_NO_TARGET) ~= 0 then
    -- no target
    ExecuteOrderFromTable({
      UnitIndex = caster:entindex(),
      OrderType = DOTA_UNIT_ORDER_CAST_NO_TARGET,
      AbilityIndex = ability:entindex(), --Optional.  Only used when casting abilities
      Queue = 0 --Optional.  Used for queueing up abilities
    })
  elseif bit.band(behavior, DOTA_ABILITY_BEHAVIOR_UNIT_TARGET) ~= 0 then
    -- target
    if IsValidEntity(target) then
      ExecuteOrderFromTable({
        UnitIndex = caster:entindex(),
        OrderType = DOTA_UNIT_ORDER_CAST_TARGET,
        TargetIndex = target:entindex(), --Optional.  Only used when targeting units
        AbilityIndex = ability:entindex(), --Optional.  Only used when casting abilities
        Queue = 0 --Optional.  Used for queueing up abilities
      })
    end
  elseif bit.band(behavior, DOTA_ABILITY_BEHAVIOR_TOGGLE) ~= 0 and not ability:IsActivated() then
    -- toggle
    ExecuteOrderFromTable({
      UnitIndex = caster:entindex(),
      OrderType = DOTA_UNIT_ORDER_CAST_TOGGLE,
      AbilityIndex = ability:entindex(), --Optional.  Only used when casting abilities
      Queue = 0 --Optional.  Used for queueing up abilities
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
        return true
      end
    end
  end
end

local function IsHeroInRange(position, range)
  return FindUnitsInRadius(
    DOTA_TEAM_NEUTRALS,
    position,
    nil,
    range,
    DOTA_UNIT_TARGET_TEAM_ENEMY,
    DOTA_UNIT_TARGET_HERO,
    DOTA_UNIT_TARGET_FLAG_NONE,
    FIND_ANY_ORDER,
    false
  )[1] ~= nil
end

function StopFightingYourselfThink()
  if GameRules:State_Get() >= DOTA_GAMERULES_STATE_POST_GAME or not IsValidEntity(thisEntity) or not thisEntity:IsAlive() then
    return -1
  end

  if GameRules:IsGamePaused() then
    return 1
  end

  -- Leash
  if not GLOBAL_origin then
    GLOBAL_origin = thisEntity:GetAbsOrigin()
  else
    local distance = (GLOBAL_origin - thisEntity:GetAbsOrigin()):Length()
    if distance > BOSS_LEASH_SIZE then
      ExecuteOrderFromTable({
        UnitIndex = thisEntity:entindex(),
        OrderType = DOTA_UNIT_ORDER_MOVE_TO_POSITION,
        Position = GLOBAL_origin, --Optional.  Only used when targeting the ground
        Queue = 0 --Optional.  Used for queueing up abilities
      })
      return 5
    end
  end

  local healthpct = thisEntity:GetHealth() / thisEntity:GetMaxHealth()
  if healthpct >= 99/100 then
    return 1
  end

  if IsHeroInRange(thisEntity:GetAbsOrigin(), BOSS_LEASH_SIZE) then
    local dice = RandomFloat(0, 1)
    if dice <= 0.33 and healthpct <= 50/100 then
      UseRandomItem()
      return 0.5
    elseif dice <= 0.66 and healthpct <= 75/100 then
      -- IllusionsCast()
      if thisEntity:GetUnitName() == "npc_dota_boss_stopfightingyourself_tier5" then
        UseRandomItem()
      end
      return 1
    end
  end

  ExecuteOrderFromTable({
    UnitIndex = thisEntity:entindex(),
    OrderType = DOTA_UNIT_ORDER_ATTACK_MOVE,
    Position = GLOBAL_origin + RandomVector(400),
    Queue = 0
  })

  return 2
end

local function RandomHeroInRange(position, range)
  return FindUnitsInRadius(
    DOTA_TEAM_NEUTRALS,
    position,
    nil,
    range,
    DOTA_UNIT_TARGET_TEAM_ENEMY,
    DOTA_UNIT_TARGET_HERO,
    DOTA_UNIT_TARGET_FLAG_NONE,
    FIND_ANY_ORDER,
    false
  )[1]
end

local function RandomTreeInRange(range)
  return FindByNameWithin(nil, "ent_dota_tree", thisEntity:GetAbsOrigin(), range)
end

-- Entry Function
function Spawn(entityKeyValues) --luacheck: ignore Spawn
  if not thisEntity or not IsServer() then
    return
  end

  ABILITY_dupe_heroes = thisEntity:FindAbilityByName('boss_stopfightingyourself_dupe_heroes')

  print("Starting AI for " .. thisEntity:GetUnitName() .. " " .. thisEntity:GetEntityIndex())
  thisEntity:SetContextThink('StopFightingYourselfThink', StopFightingYourselfThink, 1)
end
