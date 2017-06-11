beastmaster_call_of_the_wild = class(AbilityBaseClass)

function beastmaster_call_of_the_wild:OnSpellStart()
  local caster = self:GetCaster()
  local playerID = caster:GetPlayerID()
  local abilityLevel = self:GetLevel()
  local duration = self:GetSpecialValueFor("hawk_duration")
  local baseUnitName = "npc_dota_beastmaster_hawk"
  local levelUnitName = baseUnitName .. "_" .. abilityLevel

  -- Spawn hawk and orient it to face the same way as the caster
  local hawk = CreateUnitByName(levelUnitName, caster:GetOrigin() + RandomVector(1):Normalized() * RandomFloat(50, 100), true, caster, caster:GetOwner(), caster:GetTeam())
  hawk:SetControllableByPlayer(playerID, false)
  hawk:SetOwner(caster)
  hawk:SetForwardVector(caster:GetForwardVector())
  hawk:AddNewModifier(caster, self, "modifier_kill", {duration = duration})

  -- Create particle effects
  local particleName = "particles/units/heroes/hero_beastmaster/beastmaster_call_bird.vpcf"
  local particle1 = ParticleManager:CreateParticle(particleName, PATTACH_CUSTOMORIGIN, caster)
  ParticleManager:SetParticleControl(particle1, 0, hawk:GetOrigin())
  ParticleManager:ReleaseParticleIndex(particle1)

  EmitSoundOn("Hero_Beastmaster.Call.Hawk", caster)
end

function beastmaster_call_of_the_wild:OnUpgrade()
  local linkedAbility = self:GetCaster():FindAbilityByName("beastmaster_call_of_the_wild_boar")
  local selfAbilityLevel = self:GetLevel()
  if linkedAbility then
    local linkedAbilityLevel = linkedAbility:GetLevel()
    if linkedAbilityLevel ~= selfAbilityLevel then
      linkedAbility:SetLevel(selfAbilityLevel)
    end
  end
end
