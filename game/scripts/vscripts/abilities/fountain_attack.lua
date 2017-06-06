require('internal/util')

fountain_attack = class({})

function fountain_attack:OnUpgrade()
  local caster = self:GetCaster()
  local teamID = caster:GetTeamNumber()
  local fountainName = 'fountain_' .. GetShortTeamName(teamID)
  self.fountain = {
    trigger = Entities:FindByName(nil, fountainName .. '_trigger'),
    effectName = "particles/econ/items/lina/lina_ti6/lina_ti6_laguna_blade.vpcf",
    duration = self:GetSpecialValueFor("timetokill")
  }

  Timers:CreateTimer(function ()
    self:Think()
    return self:GetSpecialValueFor("delay")
  end)
end

function fountain_attack:Think()
  local caster = self:GetCaster()
  local fountainOrigin = self.fountain.trigger:GetAbsOrigin()
  local searchRadius = self.fountain.trigger:GetBoundingMaxs():Length2D()
  local teamID = caster:GetTeam()

  local units = FindUnitsInRadius(
    teamID,
    fountainOrigin,
    nil,
    searchRadius,
    self:GetAbilityTargetTeam(),
    self:GetAbilityTargetType(),
    self:GetAbilityTargetFlags(),
    FIND_ANY_ORDER,
    false
  )
  for _,unit in ipairs(units) do
    if unit:GetTeamNumber() ~= DOTA_TEAM_NEUTRALS and self:IsInFountain(unit) then
      self:Attack(unit)
    end
  end
end

function fountain_attack:Attack(unit)
  local caster = self:GetCaster()
  local teamID = caster:GetTeamNumber()
  local killTime = self.fountain.duration
  local attackEffect = self.fountain.effectName
  local killTicks = killTime / self:GetSpecialValueFor("delay")
  local unitHealth = unit:GetHealth()
  local unitMaxHealth = unit:GetMaxHealth()
  local healthReductionAmount = unitMaxHealth / killTicks
  local unitMaxMana = unit:GetMaxMana()
  local manaReductionAmount = unitMaxMana / killTicks

  unit:MakeVisibleDueToAttack(teamID)
  unit:Purge(true, false, false, false, true)
  unit:ReduceMana(manaReductionAmount)
  if unitHealth - healthReductionAmount < 1 then
    unit:Kill(self, caster)
  else
    unit:SetHealth(unitHealth - healthReductionAmount)
  end

  local particle = ParticleManager:CreateParticle(attackEffect, PATTACH_CUSTOMORIGIN, nil)
  ParticleManager:SetParticleControlEnt(particle, 0, caster, PATTACH_POINT_FOLLOW, "attach_attack1", caster:GetAbsOrigin(), true)
  ParticleManager:SetParticleControlEnt(particle, 1, unit, PATTACH_POINT_FOLLOW, "attach_hitloc", unit:GetAbsOrigin(), true)
end

function fountain_attack:IsInFountain(entity)
  local fountainOrigin = self.fountain.trigger:GetAbsOrigin()
  local bounds = self.fountain.trigger:GetBounds()

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
