
if Fountain == nil then
  Debug.EnabledModules["fountain:fountain"] = true
  DebugPrint("Created new Fountain Object")
  Fountain = class({})
end

function Fountain:Init()
  self.fountains = {}
  for teamID = DOTA_TEAM_GOODGUYS, DOTA_TEAM_BADDGUYS do
    local fountainName = 'fountain_' .. GetShortTeamName(teamID)
    local attack = {
      effectName = "particles/econ/items/lina/lina_ti6/lina_ti6_laguna_blade.vpcf",
      position = Entities:FindByName(fountainName .. '_attacker'):GetAbsOrigin(),
      duration = 5
    }
    self.fountains[teamID] = {
      teamID = teamID,
      trigger = Entities:FindByName(fountainName .. '_trigger'),
      attack = attack
    }

    Timers:CreateTimer(0, function ()
      self:Think(self.fountains[teamID])
      return 0.1
    end)
  end

end

function Fountain:Think(fountain)
  local searchRadius = (fountain.trigger:GetAbsOrigin() - fountain.trigger.GetBoundingMaxs()):Lenght2D()
  local teamID = fountain.teamID
  local fountainOrigin = fountain.trigger:GetAbsOrigin()

  local units = FindUnitsInRadius(
    teamID,
    fountainOrigin,
    nil,
    searchRadius,
    DOTA_UNIT_TARGET_TEAM_ENEMY,
    DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
    DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES + DOTA_UNIT_TARGET_FLAG_INVULNERABLE + DOTA_UNIT_TARGET_FLAG_NOT_CREEP_HERO + DOTA_UNIT_TARGET_FLAG_OUT_OF_WORLD
  )
  for _,unit in ipairs(units) do
    --if self:IsInFountain(unit) then
    if fountain.trigger:IsTouching() then
      self:Attack(fountain, unit)
    end
  end
end

function Fountain:Attack(fountain, unit)
  local teamID = fountain.teamID
  local killTime = fountain.attack.duration
  local killTicks = killTime / 0.1
  local unitHealth = unit:GetHealth()
  local unitMaxHealth = unit:GetMaxHealth()
  local healthReductionAmount = unitHealth / killTicks
  local unitMaxMana = unit:GetMaxMana()
  local manaReductionAmount = unitMaxMana / killTicks

  DebugPrint('Fountain of team ' .. teamID .. ' is attacking ' .. unit:GetName())

  unit:MakeVisibleDueToAttack(teamID)
  unit:Purge(true, false, false, false, true)
  unit:ReduceMana(manaReductionAmount)
  unit:SetHealth(unitHealth - healthReductionAmount)
end

function Fountain:IsInFountain (fountain, entity)
  local fountainOrigin = fountain.trigger:GetAbsOrigin()
  local bounds = fountain.trigger:GetBounds()

  local origin = entity
  if entity.GetAbsOrigin then
    origin = entity:GetAbsOrigin()
  end

  if origin.x < bounds.Mins.x + caveOrigin.x then
    -- DebugPrint('x is too small')
    return false
  end
  if origin.y < bounds.Mins.y + caveOrigin.y then
    -- DebugPrint('y is too small')
    return false
  end
  if origin.x > bounds.Maxs.x + caveOrigin.x then
    -- DebugPrint('x is too large')
    return false
  end
  if origin.y > bounds.Maxs.y + caveOrigin.y then
    -- DebugPrint('y is too large')
    return false
  end

  return true
end
