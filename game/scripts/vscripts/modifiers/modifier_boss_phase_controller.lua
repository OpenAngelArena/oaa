
modifier_boss_phase_controller = class({})

function modifier_boss_phase_controller:OnRefresh ()
  if not IsServer() then
    return
  end

  self:StartIntervalThink( 0.5 )
end

function modifier_boss_phase_controller:OnCreated (keys)
  if not IsServer() then
    return
  end

  self.phases = iter({ 66, 33 })
  self.abilities = nil

  self:StartIntervalThink( 0.5 )
end

function modifier_boss_phase_controller:IsPurgable()
  return false
end

function modifier_boss_phase_controller:SetPhases (phases)
  self.phases = iter(phases)
end

function modifier_boss_phase_controller:SetAbilities (abilities)
  local caster = self:GetCaster()

  local function getAbilityByName (name)
    return caster:FindAbilityByName(name)
  end

  self.abilities = map(getAbilityByName, iter(abilities))
end

function modifier_boss_phase_controller:OnIntervalThink ()
  local desiredLevel = 1
  local caster = self:GetCaster()
  local hpPercent = 100 * caster:GetHealth() / caster:GetMaxHealth()
  self.phases:each(function (percent)
    if hpPercent < percent then
      desiredLevel = desiredLevel + 1
    end
  end)
  self.abilities:each(function (ability)
    if ability:GetLevel() ~= desiredLevel then
      print('Phase desired level is ' .. desiredLevel)
      ability:SetLevel(desiredLevel)
    end
  end)
end
