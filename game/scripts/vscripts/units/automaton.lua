-- Credid: EBF by yahnich
--[[
Broodking AI
]]
TECHIES_BEHAVIOR_SEEK_AND_DESTROY = 1
TECHIES_BEHAVIOR_ROAM_AND_MINE = 2
require( "units/ebf_ai_core" )

local GLOBAL_origin = nil
function Spawn( entityKeyValues )
  thisEntity:SetContextThink( "AIThinker", AIThink, 1 )
  thisEntity.suicide = thisEntity:FindAbilityByName("boss_automaton_suicide")
  thisEntity.mine = thisEntity:FindAbilityByName("boss_automaton_proximity")
  thisEntity.behavior = RandomInt(1,2)
  --[[
  if  math.floor(GameRules.gameDifficulty + 0.5) > 3 then
    thisEntity.suicide:SetLevel(4)
    thisEntity.mine:SetLevel(4)
  elseif  math.floor(GameRules.gameDifficulty + 0.5) == 3 then
    thisEntity.suicide:SetLevel(3)
    thisEntity.mine:SetLevel(3)
  elseif  math.floor(GameRules.gameDifficulty + 0.5) == 2 then
    thisEntity.suicide:SetLevel(2)
    thisEntity.mine:SetLevel(2)
  else
    thisEntity.suicide:SetLevel(1)
    thisEntity.mine:SetLevel(1)
  end
  ]]
  thisEntity.suicide:SetLevel(4)
  thisEntity.mine:SetLevel(4)
end


function AIThink()
  if not GLOBAL_origin then
    GLOBAL_origin = thisEntity:GetAbsOrigin()
  end
  if not thisEntity:IsAlive() then
    for _,mine in pairs( FindUnitsInRadius( thisEntity:GetTeam(), thisEntity:GetOrigin(), nil, 99999, DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_ALL, 0, 0, false ) ) do
      if mine:GetUnitName() == "npc_dota_techies_land_mine" or mine:GetName() == "npc_dota_techies_land_mine" or mine:GetUnitLabel() == "npc_dota_techies_land_mine" then
        if mine:GetOwnerEntity() == thisEntity then
          -- print("secondcheck")
          mine:RemoveSelf()
        end
      end
    end
    return 5
  end
  if not thisEntity:IsDominated() then
    if thisEntity:IsChanneling() then return 0.25 end
    local boom = AICore:NearestEnemyHeroInRange( thisEntity, 300, true )
    if boom then
      if thisEntity.suicide:IsFullyCastable() then
        ExecuteOrderFromTable({
          UnitIndex = thisEntity:entindex(),
          OrderType = DOTA_UNIT_ORDER_CAST_POSITION,
          Position = boom:GetOrigin(),
          AbilityIndex = thisEntity.suicide:entindex()
        })
        return 0.25
      end
    end
    if thisEntity.mine:IsFullyCastable() and not AICore:SpecificAlliedUnitsInRange( thisEntity, "npc_dota_techies_land_mine", 450 )
    and not AICore:SpecificAlliedUnitsInRange( thisEntity, "npc_dota_techies", 450 ) then
      ExecuteOrderFromTable({
        UnitIndex = thisEntity:entindex(),
        OrderType = DOTA_UNIT_ORDER_CAST_POSITION,
        Position = thisEntity:GetOrigin(),
        AbilityIndex = thisEntity.mine:entindex()
      })
      return 0.25
    end
    if thisEntity.behavior == TECHIES_BEHAVIOR_SEEK_AND_DESTROY then
      AICore:RunToTarget( thisEntity, AICore:NearestEnemyHeroInRange( thisEntity, 900, true ) ) -- reduced from 9999
    elseif thisEntity.behavior == TECHIES_BEHAVIOR_ROAM_AND_MINE then
      AICore:RunToRandomPositionLocation( thisEntity, GLOBAL_origin, 15, 900 ) -- set to spawn position and 900 units
    end
    return 0.25
  else return 0.25 end
end
