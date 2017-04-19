
-- Entry Function
function Spawn(entityKeyValues)
  local disabled = false
  if disabled then
    return
  end

  thisEntity:SetContextThink('StopFightingYourselfThink', partial(Think, thisEntity), 1)
  print("Starting AI for " .. thisEntity:GetUnitName() .. " " .. thisEntity:GetEntityIndex())
end

function Think(state, target)
  if not thisEntity:IsAlive() then
    if thisEntity.illusions then
      for i,illusion in ipairs(thisEntity.illusions) do
        illusion:ForceKill(false)
        illusion:RemoveSelf()
        thisEntity.illusions[i] = nil
      end
    end
    return 0
  end

  -- Leash
  if not GLOBAL_origin then
    GLOBAL_origin = thisEntity:GetAbsOrigin()
  else
    local distance = (GLOBAL_origin - thisEntity:GetAbsOrigin()):Length()
    if distance > 1000 then
      ExecuteOrderFromTable({
        UnitIndex = thisEntity:entindex(),
        OrderType = DOTA_UNIT_ORDER_MOVE_TO_POSITION,
        Position = GLOBAL_origin, --Optional.  Only used when targeting the ground
        Queue = 0 --Optional.  Used for queueing up abilities
      })
      return 5
    end
  end

  if thisEntity:IsIdle() then
    ExecuteOrderFromTable({
      UnitIndex = thisEntity:entindex(),
      OrderType = DOTA_UNIT_ORDER_ATTACK_MOVE,
      TargetIndex = GLOBAL_origin,
      Queue = 0
    })
  end

  if IsHeroInRange(thisEntity:GetAbsOrigin(), 1000) then
    if UseRandomItem() then
      return 0.5
    end
  end
  --IllusionsCast()

  return 0.1
end

function RandomHeroInRange(position, range)
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

function ClosestHeroInRange(position, range)
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

function IsHeroInRange(position, range)
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

function RandomTreeInRange(range)
  return FindByNameWithin(nil, "ent_dota_tree", thisEntity:GetAbsOrigin(), range)
end

function UseRandomItem()
  for slot=DOTA_ITEM_SLOT_1, DOTA_ITEM_SLOT_6 do
    local item = GetItemInSlot(slot)
    if item and item:IsItem() then
      if item:IsRecipe() then
        return false
      end
      if not item:GetAbility():IsFullyCastable() then
        return false
      end
      if item:GetAbility():IsCooldownReady() then
        local range = item:GetAbility():GetCastRange()
        local target = ClosestHeroInRange(thisEntity:GetAbsOrigin(), range)
        if target then
          UseAbility(item, thisEntity, target, range)
        end
      end
    end
  end
end

function UseAbility(ability, caster, target, maxRange)
  local randomPosition = RandomVector(maxRange) + caster:GetAbsOrigin()
  local randomTree = RandomTreeInRange(maxRange)

  local targetlessOrders = {
    DOTA_UNIT_ORDER_CAST_NO_TARGET,
    DOTA_UNIT_ORDER_CAST_TOGGLE
  }

  -- Target
  ExecuteOrderFromTable({
    UnitIndex = caster:entindex(),
    OrderType = order,
    TargetIndex = target:entindex(), --Optional.  Only used when targeting units
    AbilityIndex = ability, --Optional.  Only used when casting abilities
    Queue = 0 --Optional.  Used for queueing up abilities
  })

  -- Self
  ExecuteOrderFromTable({
    UnitIndex = caster:entindex(),
    OrderType = DOTA_UNIT_ORDER_CAST_TARGET,
    TargetIndex = caster:entindex(), --Optional.  Only used when targeting units
    AbilityIndex = ability, --Optional.  Only used when casting abilities
    Queue = 0 --Optional.  Used for queueing up abilities
  })

  -- Position
  if randomPosition then
    ExecuteOrderFromTable({
      UnitIndex = caster:entindex(),
      OrderType = DOTA_UNIT_ORDER_CAST_POSITION,
      AbilityIndex = ability, --Optional.  Only used when casting abilities
      Position = randomPosition,
      Queue = 0 --Optional.  Used for queueing up abilities
    })
  end

  -- Tree
  if randomTree then
    ExecuteOrderFromTable({
      UnitIndex = caster:entindex(),
      OrderType = DOTA_UNIT_ORDER_CAST_TARGET,
      TargetIndex = randomTree:entindex(), --Optional.  Only used when targeting units
      AbilityIndex = ability, --Optional.  Only used when casting abilities
      Queue = 0 --Optional.  Used for queueing up abilities
    })
  end

  -- Toggle and no Target
  for _,order in ipairs(targetlessOrders) do
    ExecuteOrderFromTable({
      UnitIndex = caster:entindex(),
      OrderType = order,
      AbilityIndex = ability, --Optional.  Only used when casting abilities
      Queue = 0 --Optional.  Used for queueing up abilities
    })
  end
end
