--[[
Broodking AI
]]

require( "units/ebf_ai_core" )

function Spawn( entityKeyValues )
  thisEntity:SetContextThink( "AIThinker", AIThink, 1 )

  thisEntity.orb = thisEntity:FindAbilityByName("boss_death_archdemon_death_orb")
  thisEntity.death = thisEntity:FindAbilityByName("boss_death_archdemon_death_time")
  thisEntity.blink = thisEntity:FindAbilityByName("boss_death_archdemon_blink_on_far")
end


function AIThink()
  if not thisEntity:IsDominated() then
    local radius = 800
    if AICore:TotalEnemyHeroesInRange( thisEntity, radius ) >= 1 and thisEntity.orb:IsFullyCastable() then
      ExecuteOrderFromTable({
        UnitIndex = thisEntity:entindex(),
        OrderType = DOTA_UNIT_ORDER_CAST_NO_TARGET,
        AbilityIndex = thisEntity.orb:entindex()
      })
      return 3
    elseif AICore:TotalEnemyHeroesInRange( thisEntity, radius ) >= 1 and thisEntity.death:IsFullyCastable() then
      ExecuteOrderFromTable({
        UnitIndex = thisEntity:entindex(),
        OrderType = DOTA_UNIT_ORDER_CAST_NO_TARGET,
        AbilityIndex = thisEntity.death:entindex()
      })
      return 6
    elseif thisEntity.blink:IsFullyCastable() then
      local target = AICore:WeakestEnemyHeroInRange( thisEntity, thisEntity.blink:GetCastRange(), true)
      if target then
        ExecuteOrderFromTable({
          UnitIndex = thisEntity:entindex(),
          OrderType = DOTA_UNIT_ORDER_CAST_TARGET,
          TargetIndex = target:entindex(),
          AbilityIndex = thisEntity.blink:entindex()
        })
        return 1
      end
    else
      AICore:AttackHighestPriority( thisEntity )
      return 0.25
    end
    return 0.25
  else
    return 0.25
  end
end
