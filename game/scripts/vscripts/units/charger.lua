
function GetAllPillars ()
  local towers = FindUnitsInRadius(
    thisEntity:GetTeamNumber(),
    thisEntity.GLOBAL_origin,
    nil,
    1500,
    DOTA_UNIT_TARGET_TEAM_FRIENDLY,
    DOTA_UNIT_TARGET_BASIC,
    bit.bor(DOTA_UNIT_TARGET_FLAG_INVULNERABLE, DOTA_UNIT_TARGET_FLAG_OUT_OF_WORLD),
    FIND_CLOSEST,
    false
  )

  local function isTower (tower)
    return tower:GetUnitName() == "npc_dota_boss_pillar_charger_oaa"
  end

  return filter(isTower, iter(towers))
end

function CheckPillars ()
  if not thisEntity.ABILITY_summon_pillar then
    return false
  end

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

  towerLocation = towerLocation + thisEntity.GLOBAL_origin

  ExecuteOrderFromTable({
    UnitIndex = thisEntity:entindex(),
    OrderType = DOTA_UNIT_ORDER_CAST_POSITION,
    AbilityIndex = thisEntity.ABILITY_summon_pillar:entindex(),
    Position = towerLocation,
    Queue = 0,
  })

  return true
end

function ChargeHero ()
  if not thisEntity.ABILITY_charge then
    return false
  end
  if not thisEntity.ABILITY_charge:IsCooldownReady() then
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
    AbilityIndex = thisEntity.ABILITY_charge:entindex(),
    Position = hero:GetAbsOrigin(),
    Queue = 0,
  })

  return true
end

function ChargerThink ()
  if GameRules:State_Get() >= DOTA_GAMERULES_STATE_POST_GAME or not IsValidEntity(thisEntity) or not thisEntity:IsAlive() then
    return -1
  end

  if GameRules:IsGamePaused() then
    return 1
  end

  if not thisEntity.initialized then
    thisEntity.GLOBAL_origin = thisEntity:GetAbsOrigin()
    thisEntity.BossTier = thisEntity.BossTier or 2
    thisEntity.initialized = true
  end

  local distance = (thisEntity.GLOBAL_origin - thisEntity:GetAbsOrigin()):Length()
  if distance > 1000 then
    ExecuteOrderFromTable({
      UnitIndex = thisEntity:entindex(),
      OrderType = DOTA_UNIT_ORDER_MOVE_TO_POSITION,
      Position = thisEntity.GLOBAL_origin,
      Queue = false,
    })
    return 5
  end

  if thisEntity:GetHealth() / thisEntity:GetMaxHealth() >= 99/100 then
    return 1
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
    Position = thisEntity.GLOBAL_origin,
    Queue = 0,
  })

  return 0.1
end

function Spawn (entityKeyValues) --luacheck: ignore Spawn
  if not thisEntity or not IsServer() then
    return
  end

  local chargeAbilityName = "boss_charger_charge"
  if not thisEntity:HasAbility( chargeAbilityName ) then
    chargeAbilityName = "boss_charger_charge_tier5"
  end

  thisEntity.ABILITY_charge = thisEntity:FindAbilityByName(chargeAbilityName)
  thisEntity.ABILITY_summon_pillar = thisEntity:FindAbilityByName("boss_charger_summon_pillar")

  thisEntity:SetContextThink("ChargerThink", ChargerThink , 1)
  --print("Starting AI for " .. thisEntity:GetUnitName() .. " " .. thisEntity:GetEntityIndex())

  local phaseController = thisEntity:AddNewModifier(thisEntity, thisEntity.ABILITY_charge, "modifier_boss_phase_controller", {})
  phaseController:SetPhases({ 66, 33 })
  phaseController:SetAbilities({
    chargeAbilityName,
  })
end
