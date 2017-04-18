
-- Entry Function
function Spawn(entityKeyValues)
  local disabled = false
  if disabled then
    return
  end
  thisEntity:SetContextThink('MirrorThink', partial(ChargerThink, thisEntity), 1)
end

function MirrorThink(state, target)
  if not thisEntity:IsAlive() then
    if thisEntity.illusions then
      each(function(illusion)
        illusion:ForceKill(false)
        illusion:RemoveSelf()
      end, thisEntity.illusions)
    end
    return 0
  end

  if not thisEntity:IsIdle() then
    return 0.1
  end

  if IsHeroInRange(thisEntity:GetAbsOrigin(), 1000) then
    if UseRandomItems() then
      return 0.1
    end
  end
  --IllusionsCast()
  return 0.1
end

function UseItems()
  for slot = DOTA_ITEM_SLOT_1, DOTA_ITEM_SLOT_6 do
    local item = thisEntity:GetItemInSlot(slot)
    if item:IsItem() then
      ExecuteOrderFromTable({
        UnitIndex = thisEntity:entindex(),
        OrderType = DOTA_UNIT_ORDER_CAST_TARGET,
        TargetIndex = RandomHeroInRange(thisEntity:GetAbsOrigin(), 1000):entindex(),
        AbilityIndex = item:GetAbility(),
        Queue = 0
      })
    end
  end
  return true
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
