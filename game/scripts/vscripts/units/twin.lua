LinkLuaModifier( "modifier_boss_phase_controller", "modifiers/modifier_boss_phase_controller", LUA_MODIFIER_MOTION_NONE )

local ABILITY_empathy = nil


local function FarthestHeroInRange(position, range)
  return FindUnitsInRadius(
    DOTA_TEAM_NEUTRALS,
    position,
    nil,
    range,
    DOTA_UNIT_TARGET_TEAM_ENEMY,
    DOTA_UNIT_TARGET_HERO,
    DOTA_UNIT_TARGET_FLAG_NONE,
    FIND_FARTHEST,
    false
  )[1]
end

local function FindTwin()
  local unitsInRange = FindUnitsInRadius(
    DOTA_TEAM_NEUTRALS,
    thisEntity:GetAbsOrigin(),
    nil,
    2000,
    DOTA_UNIT_TARGET_TEAM_FRIENDLY,
    DOTA_UNIT_TARGET_HERO,
    DOTA_UNIT_TARGET_FLAG_NONE,
    FIND_ANY_ORDER,
    false
    )

  if #unitsInRange == 0 then
    return false
  end

  local i = 1
  while i <= #unitsInRange do
    if unitsInRange[i]:GetUnitName() == "npc_dota_boss_twin_dumb" then
      return unitsInRange[i]
    end
  end

  return false
end

local function HurtHandler(keys)
  local twin = FindTwin()
  if twin == false then
    return
  end
  local target = FarthestHeroInRange(twin:GetAbsOrigin(), 1000)
  ExecuteOrderFromTable({
    UnitIndex = thisEntity:entindex(),
    OrderType = DOTA_UNIT_ORDER_ATTACK_TARGET,
    Position = target:GetAbsOrigin(),
    Queue = 0
  })
end

local function TwinStartup()
  thisEntity:OnHurt(HurtHandler)

  local twin = CreateUnitByName("npc_dota_boss_twin_dumb", thisEntity:GetAbsOrigin(), true, thisEntity, thisEntity:GetOwner(), thisEntity:GetTeam())
  twin:AddNewModifier(thisEntity, ABILITY_empathy, "modifier_boss_twin_twin_empathy_buff", {})
end

function Spawn (entityKeyValues)
  thisEntity:SetContextThink( "TwinStartup", partial(TwinStartup, thisEntity) , 1)
  print("Starting AI for " .. thisEntity:GetUnitName() .. " " .. thisEntity:GetEntityIndex())

  ABILITY_empathy = thisEntity:FindAbilityByName("boss_twin_twin_empathy")

  local phaseController = thisEntity:AddNewModifier(thisEntity, ABILITY_empathy, "modifier_boss_phase_controller", {})
  phaseController:SetPhases({ 75, 50 })
  phaseController:SetAbilities({
    "boss_twin_twin_empathy"
  })
end
