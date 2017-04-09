
modifier_boss_phase_controller = class({})

function modifier_boss_phase_controller:OnCreated (keys)
  if not IsServer() then
    return
  end

  local caster = self:GetCaster()

  print(keys)
  for k,v in pairs(keys) do
    print(k .. ': ' .. tostring(v))
  end

  keys.phases = keys.phases or { 66, 33 }
  keys.abilities = keys.abilities or { 'boss_charger_charge' }

  self.phases = iter(keys.phases)

  function getAbilityByName (name)
    return caster:FindAbilityByName(name)
  end

  self.abilities = map(getAbilityByName, iter(keys.abilities))

  self:StartIntervalThink( 0.5 )
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
