
if Fountain == nil then
  Debug.EnabledModules["fountain:fountain"] = true
  DebugPrint("Created new Fountain Object")
  Fountain = class({})
end

function Fountain:Init()
  self.fountains = {}
  for teamID = DOTA_TEAM_GOODGUYS,DOTA_TEAM_BADGUYS do
    local fountainName = 'fountain_' .. GetShortTeamName(teamID)
    local attack = {
      effectName = "particles/econ/items/lina/lina_ti6/lina_ti6_laguna_blade.vpcf",
      attacker = Entities:FindByName(nil, fountainName .. '_attacker'),
      duration = 2
    }
    self.fountains[teamID] = {
      teamID = teamID,
      trigger = Entities:FindByName(nil, fountainName .. '_trigger'),
      attack = attack
    }

    Timers:CreateTimer(function ()
      self:Think(self.fountains[teamID])
      return 0.1
    end)
  end

end

function Fountain:Think(fountain)
  local fountainOrigin = fountain.trigger:GetAbsOrigin()
  local searchRadius = fountain.trigger:GetBoundingMaxs():Length2D()
  local teamID = fountain.teamID

  local units = FindUnitsInRadius(
    teamID,
    fountainOrigin,
    nil,
    searchRadius,
    DOTA_UNIT_TARGET_TEAM_ENEMY,
    DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
    DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES + DOTA_UNIT_TARGET_FLAG_INVULNERABLE + DOTA_UNIT_TARGET_FLAG_NOT_CREEP_HERO + DOTA_UNIT_TARGET_FLAG_OUT_OF_WORLD,
    FIND_ANY_ORDER,
    false
  )
  for _,unit in ipairs(units) do
    if self:IsInFountain(fountain, unit) then
      self:Attack(fountain, unit)
    end
  end
end

function Fountain:Attack(fountain, unit)
  local teamID = fountain.teamID
  local killTime = fountain.attack.duration
  local attacker = fountain.attack.attacker
  local attackEffect = fountain.attack.effectName
  local killTicks = killTime / 0.1
  local unitHealth = unit:GetHealth()
  local unitMaxHealth = unit:GetMaxHealth()
  local healthReductionAmount = unitMaxHealth / killTicks
  local unitMaxMana = unit:GetMaxMana()
  local manaReductionAmount = unitMaxMana / killTicks

  DebugPrint('Fountain of team ' .. teamID .. ' is attacking ' .. unit:GetName())

  unit:MakeVisibleDueToAttack(teamID)
  unit:Purge(true, false, false, false, true)
  unit:ReduceMana(manaReductionAmount)
  if unitHealth - healthReductionAmount < 1 then
    unit:ForceKill(true)
    --unit:Kill(nil, killer)
  else
    unit:SetHealth(unitHealth - healthReductionAmount)
  end

  local particle = ParticleManager:CreateParticle(attackEffect, PATTACH_CUSTOMORIGIN, nil)
  ParticleManager:SetParticleControlEnt(particle, 0, fountain.trigger, PATTACH_POINT_FOLLOW, "attach_attack1", attacker:GetAbsOrigin(), true)
  ParticleManager:SetParticleControlEnt(particle, 1, unit, PATTACH_POINT_FOLLOW, "attach_hitloc", unit:GetAbsOrigin(), true)
end

function Fountain:IsInFountain (fountain, entity)
  local fountainOrigin = fountain.trigger:GetAbsOrigin()
  local bounds = fountain.trigger:GetBounds()

  local origin = entity
  if entity.GetAbsOrigin then
    origin = entity:GetAbsOrigin()
  end

  if origin.x < bounds.Mins.x + fountainOrigin.x then
    -- DebugPrint('x is too small')
    return false
  end
  if origin.y < bounds.Mins.y + fountainOrigin.y then
    -- DebugPrint('y is too small')
    return false
  end
  if origin.x > bounds.Maxs.x + fountainOrigin.x then
    -- DebugPrint('x is too large')
    return false
  end
  if origin.y > bounds.Maxs.y + fountainOrigin.y then
    -- DebugPrint('y is too large')
    return false
  end

  return true
end
