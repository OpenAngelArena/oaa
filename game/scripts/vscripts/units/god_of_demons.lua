--[[
Broodking AI
]]

require( "units/ebf_ai_core" )

function Spawn( entityKeyValues )
  thisEntity:SetContextThink( "AIThinker", AIThink, 1 )

  thisEntity.hell = thisEntity:FindAbilityByName("boss_god_of_demons_hell_on_earth")
  thisEntity.fist = thisEntity:FindAbilityByName("boss_god_of_demons_flaming_fist")
end


function AIThink()
  if not thisEntity:IsDominated() then
    if AICore:TotalEnemyHeroesInRange( thisEntity, 1000 ) >= 2 and thisEntity.fist:IsFullyCastable() then
      ExecuteOrderFromTable({
        UnitIndex = thisEntity:entindex(),
        OrderType = DOTA_UNIT_ORDER_CAST_POSITION,
        Position = thisEntity:GetOrigin(),
        AbilityIndex = thisEntity.fist:entindex()
      })
      return 2
    end
    if not thisEntity:HasModifier("modifier_sleight_of_fist_caster_datadriven") and thisEntity.hell:IsFullyCastable() and AICore:TotalEnemyHeroesInRange( thisEntity, 1500 ) >= 1 then
      ExecuteOrderFromTable({
        UnitIndex = thisEntity:entindex(),
        OrderType = DOTA_UNIT_ORDER_CAST_NO_TARGET,
        AbilityIndex = thisEntity.hell:entindex()
      })
      return thisEntity.hell:GetCastPoint() + 0.1
    end
    AICore:AttackHighestPriority( thisEntity )
    return 0.25
  else
    return 0.25
  end
end
