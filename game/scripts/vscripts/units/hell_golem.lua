--[[
Broodking AI
]]

require( "units/ebf_ai_core" )

function Spawn( entityKeyValues )
  thisEntity:SetContextThink( "AIThinker", AIThink, 1 )
  thisEntity.fire = thisEntity:FindAbilityByName("boss_hell_golem_melee_fire_orb")
end


function AIThink()
  if not thisEntity:IsDominated() then
    local radius = thisEntity.fire:GetCastRange() / 2
    if AICore:TotalEnemyHeroesInRange( thisEntity, radius ) >= 1 and thisEntity.fire:IsFullyCastable() then
      ExecuteOrderFromTable({
        UnitIndex = thisEntity:entindex(),
        OrderType = DOTA_UNIT_ORDER_CAST_POSITION,
        Position = thisEntity:GetOrigin(),
        AbilityIndex = thisEntity.fire:entindex()
      })
      return 0.25
    end
    AICore:AttackHighestPriority( thisEntity )
    return 0.25
  else
    return 0.25
  end
end
