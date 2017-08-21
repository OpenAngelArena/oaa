-- Credit: EBF by yahnich
--[[
Broodking AI
]]
LinkLuaModifier( "modifier_boss_phase_controller", "modifiers/modifier_boss_phase_controller", LUA_MODIFIER_MOTION_NONE )

TECHIES_BEHAVIOR_SEEK_AND_DESTROY = 1
TECHIES_BEHAVIOR_ROAM_AND_MINE = 2
require("units/ebf_ai_core")

function Spawn( entityKeyValues )
  thisEntity:SetContextThink( "AIThinker", AIThink, 1 )
  thisEntity.spawn = thisEntity:FindAbilityByName("boss_factorio_spawn_techies")

  local phaseController = thisEntity:AddNewModifier(thisEntity, thisEntity.spawn, "modifier_boss_phase_controller", {})
  phaseController:SetPhases({ 66, 33 })
  phaseController:SetAbilities({
    "boss_factorio_spawn_techies"
  })
end

function AIThink()
  if thisEntity:IsDominated() then return 0.25 end
  if thisEntity:IsChanneling() then return 0.25 end
  if not thisEntity.spawn:IsCooldownReady() then return 0.25 end
  ExecuteOrderFromTable({
    UnitIndex = thisEntity:entindex(),
    OrderType = DOTA_UNIT_ORDER_CAST_NO_TARGET,
    AbilityIndex = thisEntity.spawn:entindex()
  })
  return 3
end
