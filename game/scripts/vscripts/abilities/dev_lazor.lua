
dev_lazor = class({})

function dev_lazor:OnUpgrade()
  self.effectName = "particles/econ/items/lina/lina_ti6/lina_ti6_laguna_blade.vpcf"

  Timers:CreateTimer(function ()
    self:Think()
    return self:GetSpecialValueFor("delay")
  end)
end

function dev_lazor:Think()
  local caster = self:GetCaster()
  local origin = caster:GetAbsOrigin()
  local teamID = caster:GetTeam()

  local units = FindUnitsInRadius(
    teamID,
    origin,
    nil,
    self:GetCastRange(),
    self:GetAbilityTargetTeam(),
    self:GetAbilityTargetType(),
    self:GetAbilityTargetFlags(),
    FIND_ANY_ORDER,
    false
  )
  for _,unit in ipairs(units) do
    self:Attack(unit)
  end
end

function dev_lazor:Attack(unit)
  local caster = self:GetCaster()
  local teamID = caster:GetTeamNumber()
  local killTime = self:GetSpecialValueFor("timetokill")
  local attackEffect = self.effectName
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
