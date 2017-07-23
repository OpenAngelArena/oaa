--[[
Broodking AI
]]

require( "units/ebf_ai_core" )

function Spawn( entityKeyValues )
  thisEntity:SetContextThink( "AIThinker", AIThink, 1 )
  thisEntity.impale = thisEntity:FindAbilityByName("boss_nyx_slayer_melee_impale")
  thisEntity.impale2 = thisEntity:FindAbilityByName("boss_nyx_slayer_melee_impale_b")
end


function AIThink()
  -- TODO stop roaming
  if not thisEntity:IsDominated() then
    local radius = 500
    if AICore:TotalNotDisabledEnemyHeroesInRange( thisEntity, radius, false ) <= AICore:TotalEnemyHeroesInRange( thisEntity, radius )
    and AICore:TotalEnemyHeroesInRange( thisEntity, radius ) ~= 0
    and thisEntity.impale:IsFullyCastable() then
      local smashRadius = thisEntity.impale:GetSpecialValueFor("impact_radius")
      local position = AICore:OptimalHitPosition(thisEntity, radius, smashRadius)
      if position then
        ExecuteOrderFromTable({
          UnitIndex = thisEntity:entindex(),
          OrderType = DOTA_UNIT_ORDER_CAST_POSITION,
          Position = position,
          AbilityIndex = thisEntity.impale:entindex()
        })
        return 0.25
      end
    end
    if thisEntity.impale2:IsFullyCastable() then
      local target = AICore:NearestEnemyHeroInRange( thisEntity, thisEntity.impale2:GetCastRange(), false )
      if target then
        ExecuteOrderFromTable({
          UnitIndex = thisEntity:entindex(),
          OrderType = DOTA_UNIT_ORDER_CAST_POSITION,
          Position = target:GetOrigin(),
          AbilityIndex = thisEntity.impale2:entindex()
        })
        return 0.25
      end
    end
    AICore:AttackHighestPriority( thisEntity )
    return 0.25
  else
    return 0.25
  end
end
