
function Spawn (entityKeyValues)
  thisEntity:FindAbilityByName("boss_charger_summon_pillar")

  thisEntity:SetContextThink( "ChargerThink", partial(ChargerThink, thisEntity) , 1)
  print("Starting AI for " .. thisEntity:GetUnitName() .. " " .. thisEntity:GetEntityIndex())

  ABILITY_charge = thisEntity:FindAbilityByName("boss_charger_charge")
  ABILITY_summon_pillar = thisEntity:FindAbilityByName("boss_charger_summon_pillar")

  ABILITY_charge:SetLevel(1)
  ABILITY_summon_pillar:SetLevel(1)
end

function CheckPillars ()
  local towers = FindUnitsInRadius(
    thisEntity:GetTeamNumber(),
    GLOBAL_origin,
    nil,
    1200,
    DOTA_UNIT_TARGET_TEAM_FRIENDLY,
    DOTA_UNIT_TARGET_BASIC,
    DOTA_UNIT_TARGET_FLAG_INVULNERABLE + DOTA_UNIT_TARGET_FLAG_FOW_VISIBLE,
    FIND_CLOSEST,
    false
  )

  function isTower (tower)
    return tower:GetUnitName() == "npc_dota_boss_charger_pillar"
  end

  towers = filter(isTower, iter(towers))

  print('Found ' .. towers:length() .. ' towers!')

  if towers:length() > 5 then
    return false
  end

  local towerLocation = Vector(math.random(-1,1), math.random(-1,1), 0):Normalized() * 500

  towerLocation = towerLocation + GLOBAL_origin

  ExecuteOrderFromTable({
    UnitIndex = thisEntity:entindex(),
    OrderType = DOTA_UNIT_ORDER_CAST_POSITION,
    AbilityIndex = ABILITY_summon_pillar:entindex(), --Optional.  Only used when casting abilities
    Position = towerLocation, --Optional.  Only used when targeting the ground
    Queue = 0 --Optional.  Used for queueing up abilities
  })

  return true
end

function ChargerThink (state, target)
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

  if not thisEntity:IsIdle() then
    return 0.1
  end
  if CheckPillars() then
    return 0.5
  end
  local units = FindUnitsInRadius(
    thisEntity:GetTeamNumber(),
    thisEntity:GetAbsOrigin(),
    nil,
    1000,
    DOTA_UNIT_TARGET_TEAM_ENEMY,
    DOTA_UNIT_TARGET_HERO,
    DOTA_UNIT_TARGET_FLAG_FOW_VISIBLE,
    FIND_CLOSEST,
    false
  )

  print('Trying to aggro against ' .. #units .. ' heroes')

  if #units == 0 then
    return 5
  end
  local hero = units[1]

  ExecuteOrderFromTable({
    UnitIndex = thisEntity:entindex(),
    OrderType = DOTA_UNIT_ORDER_CAST_POSITION,
    TargetIndex = hero:entindex(), --Optional.  Only used when targeting units
    AbilityIndex = ABILITY_charge:entindex(), --Optional.  Only used when casting abilities
    Position = hero:GetAbsOrigin(), --Optional.  Only used when targeting the ground
    Queue = 0 --Optional.  Used for queueing up abilities
  })

  return 1
end
