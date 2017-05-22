LinkLuaModifier( "modifier_boss_phase_controller", "modifiers/modifier_boss_phase_controller", LUA_MODIFIER_MOTION_NONE )

local ABILITY_empathy = nil

function TwinThink(twin)
  thisEntity:OnHurt(HurtHandler)
end

function Spawn (entityKeyValues) --luacheck: ignore Spawn
  local twin = CreateUnitByName("npc_dota_boss_twin_dumb", thisEntity:GetAbsOrigin(), true, thisEntity, thisEntity:GetOwner(), thisEntity:GetTeam())
  twin:AddNewModifier(thisEntity, ABILITY_empathy, "modifier_boss_twin_twin_empathy_buff", {})

  thisEntity:SetContextThink( "TwinThink", partial(TwinThink, thisEntity) , 1)
  print("Starting AI for " .. thisEntity:GetUnitName() .. " " .. thisEntity:GetEntityIndex())

  ABILITY_empathy = thisEntity:FindAbilityByName("boss_twin_twin_empathy")

  local phaseController = thisEntity:AddNewModifier(thisEntity, ABILITY_empathy, "modifier_boss_phase_controller", {})
  phaseController:SetPhases({ 75, 50 })
  phaseController:SetAbilities({
    "boss_twin_twin_empathy"
  })
end

function HutHandler()
  local target = FarthestHeroInRange(thisEntity:GetAbsOrigin(), 1000)

    ExecuteOrderFromTable({
    UnitIndex = thisEntity:entindex(),
    OrderType = DOTA_UNIT_ORDER_ATTACK_TARGET,
    Position = target:GetAbsOrigin(),
    Queue = 0
  })
end

local function FarthestHeroInRange(position, range)
  return FindUnitsInRadius(
    DOTA_TEAM_NEUTRALS,
    nil,
    range,
    DOTA_UNIT_TARGET_TEAM_ENEMY,
    DOTA_UNIT_TARGET_HERO,
    DOTA_UNIT_TARGET_FLAG_NONE,
    FIND_FARTHEST,
    false
  )[1]
end