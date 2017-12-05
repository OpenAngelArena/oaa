--[[
Broodking AI
]]

require( "units/ebf_ai_core" )

function Spawn( entityKeyValues )
  thisEntity:SetContextThink( "AIThinker", AIThink, 1 )
  thisEntity.doom = thisEntity:FindAbilityByName("boss_demon_king_doom_bring")
  thisEntity.raze = thisEntity:FindAbilityByName("boss_demon_king_doomraze")
  thisEntity.tempest = thisEntity:FindAbilityByName("boss_demon_king_hell_tempest")
end


function AIThink()
  if not thisEntity:IsDominated() then
    if thisEntity.raze:IsFullyCastable() then
      local width = 300
      local range = 1000
      local target = AICore:FarthestEnemyHeroInRange( thisEntity, range, false )
      if target and AICore:EnemiesInLine(thisEntity, range, width, false)  then
        local distance = (target:GetOrigin() - thisEntity:GetOrigin()):Length2D()
        if distance < range then
          ExecuteOrderFromTable({
            UnitIndex = thisEntity:entindex(),
            OrderType = DOTA_UNIT_ORDER_CAST_NO_TARGET,
            AbilityIndex = thisEntity.raze:entindex()
          })
          return 1.25
        end
      end
    end
    if thisEntity.doom:IsFullyCastable() then
      local target = AICore:HighestThreatHeroInRange(thisEntity, thisEntity.doom:GetCastRange(), 10, true)
      if not target then target = AICore:StrongestEnemyHeroInRange( thisEntity, thisEntity.doom:GetCastRange(), true ) end
      if target then
        ExecuteOrderFromTable({
          UnitIndex = thisEntity:entindex(),
          OrderType = DOTA_UNIT_ORDER_CAST_TARGET,
          TargetIndex = target:entindex(),
          AbilityIndex = thisEntity.doom:entindex()
        })
        return 1
      end
    end
    if AICore:TotalEnemyHeroesInRange( thisEntity, 1000 ) >= 1 and thisEntity.tempest:IsFullyCastable() then
      ExecuteOrderFromTable({
        UnitIndex = thisEntity:entindex(),
        OrderType = DOTA_UNIT_ORDER_CAST_NO_TARGET,
        AbilityIndex = thisEntity.tempest:entindex()
      })
      return 2
    else
      AICore:AttackHighestPriority( thisEntity )
      return 0.25
    end
  end
  return 0.25
end
