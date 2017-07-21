--[[
Broodking AI
]]

require( "units/ebf_ai_core" )

function Spawn( entityKeyValues )
  thisEntity:SetContextThink( "AIThinker", AIThink, 1 )
  thisEntity.fire = thisEntity:FindAbilityByName("creature_fire_breath")
  thisEntity.crush = thisEntity:FindAbilityByName("creature_slithereen_crush")
  thisEntity.origin = thisEntity:GetAbsOrigin()
  thisEntity.idle = GameRules:GetGameTime()
end


function AIThink()
  -- TODO: Prevent roaming
  local target
  if not thisEntity:IsDominated() and not thisEntity:IsChanneling() then
    if not thisEntity:IsChanneling() then
      local radius = thisEntity.crush:GetSpecialValueFor("crush_radius")
      if thisEntity.crush then
        if AICore:TotalNotDisabledEnemyHeroesInRange( thisEntity, radius, false ) >= math.floor(AICore:TotalEnemyHeroesInRange( thisEntity, radius ) / 2)
        and AICore:TotalEnemyHeroesInRange( thisEntity, radius ) ~= 0
        and thisEntity.crush:IsFullyCastable() and thisEntity.crush:IsCooldownReady() then
          ExecuteOrderFromTable({
            UnitIndex = thisEntity:entindex(),
            OrderType = DOTA_UNIT_ORDER_CAST_NO_TARGET,
            AbilityIndex = thisEntity.crush:entindex()
          })
          return 0.25
        end
      end
      if thisEntity.fire:IsFullyCastable() and thisEntity.fire:IsCooldownReady() then
        target = AICore:NearestDisabledEnemyHeroInRange( thisEntity, thisEntity.fire:GetCastRange(), false )
        if target then
          ExecuteOrderFromTable({
            UnitIndex = thisEntity:entindex(),
            OrderType = DOTA_UNIT_ORDER_CAST_POSITION,
            Position = target:GetOrigin(),
            AbilityIndex = thisEntity.fire:entindex()
          })
          thisEntity.idle = GameRules:GetGameTime()
          return thisEntity.fire:GetChannelTime()
        end
      end
      -- FORCE CAST AFTER SET DURATION --
      if thisEntity.idle + 10 < GameRules:GetGameTime() and thisEntity.fire:IsFullyCastable() and thisEntity.fire:IsCooldownReady() then
        target = AICore:HighestThreatHeroInRange(thisEntity, 900, 0, true)
        if target then
          ExecuteOrderFromTable({
              UnitIndex = thisEntity:entindex(),
              OrderType = DOTA_UNIT_ORDER_CAST_POSITION,
              Position = target:GetOrigin(),
              AbilityIndex = thisEntity.fire:entindex()
          })
          thisEntity.idle = GameRules:GetGameTime()
          return thisEntity.fire:GetChannelTime()
        end
      end
      AICore:AttackHighestPriority( thisEntity )
      return 0.25
    end
    return 0.5
  end
  return 0.25
end
