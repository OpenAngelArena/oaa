LinkLuaModifier( "modifier_boss_phase_controller", "modifiers/modifier_boss_phase_controller", LUA_MODIFIER_MOTION_NONE )

local ABILITY_charge = nil
local ABILITY_summon_pillar = nil
local GLOBAL_origin = nil

local function GetAllPillars ()
  local towers = FindUnitsInRadius(
    thisEntity:GetTeamNumber(),
    GLOBAL_origin,
    nil,
    1500,
    DOTA_UNIT_TARGET_TEAM_FRIENDLY,
    DOTA_UNIT_TARGET_BASIC,
    DOTA_UNIT_TARGET_FLAG_INVULNERABLE + DOTA_UNIT_TARGET_FLAG_FOW_VISIBLE,
    FIND_CLOSEST,
    false
  )

  local function isTower (tower)
    return tower:GetUnitName() == "npc_dota_boss_charger_pillar"
  end

  return filter(isTower, iter(towers))
end

local function CheckPillars ()
  local towers = GetAllPillars()

  -- print('Found ' .. towers:length() .. ' towers!')

  if towers:length() > 3 then
    return false
  end

  local towerLocation = Vector(0,0,0)
  while towerLocation:Length() < 500 do
    -- sometimes rng fails us
    towerLocation = RandomVector(1):Normalized() * RandomFloat(500, 600)
  end

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

local function ChargeHero ()
  if not ABILITY_charge:IsCooldownReady() then
    return false
  end
  local units = FindUnitsInRadius(
    thisEntity:GetTeamNumber(),
    thisEntity:GetAbsOrigin(),
    nil,
    1000,
    DOTA_UNIT_TARGET_TEAM_ENEMY,
    DOTA_UNIT_TARGET_HERO,
    DOTA_UNIT_TARGET_FLAG_FOW_VISIBLE + DOTA_UNIT_TARGET_FLAG_INVULNERABLE,
    FIND_CLOSEST,
    false
  )

  if #units == 0 then
    return false
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

  return true
end

local function ChargerThink (state, target)
  if not IsValidEntity(thisEntity) or not thisEntity:IsAlive() then
    return 0
  end
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
  if ChargeHero() then
    return 1
  end

  ExecuteOrderFromTable({
    UnitIndex = thisEntity:entindex(),
    OrderType = DOTA_UNIT_ORDER_MOVE_TO_POSITION,
    Position = GLOBAL_origin, --Optional.  Only used when targeting the ground
    Queue = 0 --Optional.  Used for queueing up abilities
  })

  return 0.1
end

function Spawn (entityKeyValues) --luacheck: ignore Spawn
  thisEntity:FindAbilityByName("boss_charger_summon_pillar")

  thisEntity:SetContextThink( "ChargerThink", partial(ChargerThink, thisEntity) , 1)
  print("Starting AI for " .. thisEntity:GetUnitName() .. " " .. thisEntity:GetEntityIndex())

  local chargeAbilityName = "boss_charger_charge"
  if not thisEntity:HasAbility( chargeAbilityName ) then
    chargeAbilityName = "boss_charger_charge_tier5"
  end

  ABILITY_charge = thisEntity:FindAbilityByName(chargeAbilityName)
  ABILITY_summon_pillar = thisEntity:FindAbilityByName("boss_charger_summon_pillar")

  local phaseController = thisEntity:AddNewModifier(thisEntity, ABILITY_charge, "modifier_boss_phase_controller", {})
  phaseController:SetPhases({ 66, 33 })
  phaseController:SetAbilities({
    chargeAbilityName,
    "boss_charger_super_armor"
  })
end
