local GLOBAL_origin = nil
local ABILITY_tidebringer = nil

local function Think(state, target)
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

  if not ABILITY_tidebringer:IsActivated() then
    ExecuteOrderFromTable({
      UnitIndex = thisEntity:entindex(),
      OrderType = DOTA_UNIT_ORDER_CAST_TOGGLE,
      AbilityIndex = ABILITY_tidebringer:entindex(), --Optional.  Only used when casting abilities
      Queue = 0 --Optional.  Used for queueing up abilities
    })
    return 0.1
  end

  ExecuteOrderFromTable({
    UnitIndex = thisEntity:entindex(),
    OrderType = DOTA_UNIT_ORDER_ATTACK_MOVE,
    Position = GLOBAL_origin + RandomVector(400),
    Queue = 0
  })
  return 2
end

-- Entry Function
function Spawn(entityKeyValues) --luacheck: ignore Spawn
  print("Starting AI for " .. thisEntity:GetUnitName() .. " " .. thisEntity:GetEntityIndex())
  thisEntity:SetContextThink('SimpleBoss3Think', partial(Think, thisEntity), 1)

  ABILITY_tidebringer  = thisEntity:FindAbilityByName('boss_tidebringer')
end
