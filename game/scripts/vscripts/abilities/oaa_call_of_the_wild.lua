beastmaster_call_of_the_wild = class(AbilityBaseClass)

function beastmaster_call_of_the_wild:OnSpellStart()
  local caster = self:GetCaster()
  local playerID = caster:GetPlayerID()
  local abilityLevel = self:GetLevel()
  local duration = self:GetSpecialValueFor("duration")

  self:SpawnBoar(caster, playerID, abilityLevel, duration)

  
  if abilityLevel > 2 then
    self:SpawnHawk(caster, playerID, abilityLevel, duration, 1)
  end
  
  if IsServer() then
	-- TODO: Change the talent for something useful in OAA
	-- Lvl 25 Talent that adds 2 more hawks
	local talent = caster:FindAbilityByName("special_bonus_unique_beastmaster_3")
	if talent then
		if talent:GetLevel() ~= 0 then
			local bonus_hawks = talent:GetSpecialValueFor("value")
			self:SpawnHawk(caster, playerID, abilityLevel, duration, bonus_hawks)
		end
    end
  end


  if abilityLevel > 3 then
    local npcCreepList = {
      "npc_dota_neutral_alpha_wolf",
      "npc_dota_neutral_centaur_khan",
      "npc_dota_neutral_dark_troll_warlord",
      "npc_dota_neutral_polar_furbolg_ursa_warrior",
      "npc_dota_neutral_satyr_hellcaller"
    }

    local levelUnitName = npcCreepList[RandomInt(1, 5)]

    local npcCreep = self:SpawnUnit(levelUnitName, caster, playerID, abilityLevel, duration, false)
  end
end

function beastmaster_call_of_the_wild:SpawnUnit(levelUnitName, caster, playerID, abilityLevel, duration, bRandomPosition)
  local position = caster:GetOrigin();

  if bRandomPosition then
    position = position + RandomVector(1):Normalized() * RandomFloat(50, 100)
  end

  local npcCreep = CreateUnitByName(levelUnitName, position, true, caster, caster:GetOwner(), caster:GetTeam())
  npcCreep:SetControllableByPlayer(playerID, false)
  npcCreep:SetOwner(caster)
  npcCreep:SetForwardVector(caster:GetForwardVector())
  npcCreep:AddNewModifier(caster, self, "modifier_kill", {duration = duration})

  return npcCreep
end

function beastmaster_call_of_the_wild:SpawnHawk(caster, playerID, abilityLevel, duration, number_of_hawks)

  local baseUnitName = "npc_dota_beastmaster_hawk"
  local levelUnitName = baseUnitName .. "_" .. abilityLevel
  
  for i = 1, number_of_hawks do
	-- Spawn hawk and orient it to face the same way as the caster
	local hawk = self:SpawnUnit(levelUnitName, caster, playerID, abilityLevel, duration, true)
	
	-- Create particle effects
	local particleName = "particles/units/heroes/hero_beastmaster/beastmaster_call_bird.vpcf"
	local particle1 = ParticleManager:CreateParticle(particleName, PATTACH_CUSTOMORIGIN, caster)
	ParticleManager:SetParticleControl(particle1, 0, hawk:GetOrigin())
	ParticleManager:ReleaseParticleIndex(particle1)
  end

  caster:EmitSound("Hero_Beastmaster.Call.Hawk")
end


function beastmaster_call_of_the_wild:SpawnBoar(caster, playerID, abilityLevel, duration)
  local baseUnitName = "npc_dota_beastmaster_boar"
  local levelUnitName = baseUnitName .. "_" .. abilityLevel

  -- Spawn boar and orient it to face the same way as the caster
  local boar = self:SpawnUnit(levelUnitName, caster, playerID, abilityLevel, duration, false)
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

  caster:EmitSound("Hero_Beastmaster.Call.Boar")
end
