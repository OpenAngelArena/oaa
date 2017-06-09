beastmaster_call_of_the_wild_boar = class({})

function beastmaster_call_of_the_wild_boar:OnSpellStart()
  local caster = self:GetCaster()
  local playerID = caster:GetPlayerID()
  local abilityLevel = self:GetLevel()
  local duration = self:GetSpecialValueFor("boar_duration")
  local baseUnitName = "npc_dota_beastmaster_boar"
  local levelUnitName = baseUnitName .. "_" .. abilityLevel
  local spawnCount = 1

  local hasExtraBoar = caster:HasLearnedAbility("special_bonus_unique_beastmaster_2")

  if hasExtraBoar then
    spawnCount = spawnCount + caster:FindAbilityByName("special_bonus_unique_beastmaster_2"):GetSpecialValueFor("value")
  end

  local function SpawnBoar()
    -- Spawn boar and orient it to face the same way as the caster
    local boar = CreateUnitByName(levelUnitName, caster:GetOrigin(), true, caster, caster:GetOwner(), caster:GetTeam())
    boar:SetControllableByPlayer(playerID, false)
    boar:SetOwner(caster)
    boar:SetForwardVector(caster:GetForwardVector())
    boar:AddNewModifier(caster, self, "modifier_kill", {duration = duration})
    boar:AddNewModifier(caster, self, "modifier_beastmaster_boar_poison", {})
    -- Level the boar's poison ability to match abilityLevel
    local boarPoisonAbility = boar:FindAbilityByName("beastmaster_boar_poison")
    if boarPoisonAbility then
      boarPoisonAbility:SetLevel(abilityLevel)
    end
    -- Create particle effects
    local particleName = "particles/units/heroes/hero_beastmaster/beastmaster_call_boar.vpcf"
    local particle1 = ParticleManager:CreateParticle(particleName, PATTACH_CUSTOMORIGIN, caster)
    ParticleManager:SetParticleControl(particle1, 0, boar:GetOrigin())
    ParticleManager:ReleaseParticleIndex(particle1)
  end
  foreach(SpawnBoar, range(spawnCount))

  EmitSoundOn("Hero_Beastmaster.Call.Boar", caster)
end

function beastmaster_call_of_the_wild_boar:OnUpgrade()
  local linkedAbility = self:GetCaster():FindAbilityByName("beastmaster_call_of_the_wild")
  local selfAbilityLevel = self:GetLevel()
  if linkedAbility then
    local linkedAbilityLevel = linkedAbility:GetLevel()
    if linkedAbilityLevel ~= selfAbilityLevel then
      linkedAbility:SetLevel(selfAbilityLevel)
    end
  end
end
