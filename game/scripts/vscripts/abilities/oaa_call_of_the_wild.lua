
beastmaster_call_of_the_wild_boar_oaa = class(AbilityBaseClass)

function beastmaster_call_of_the_wild_boar_oaa:OnSpellStart()
  local caster = self:GetCaster()
  local playerID = caster:GetPlayerID()
  local abilityLevel = self:GetLevel()
  local duration = self:GetSpecialValueFor("duration")

  self:SpawnBoar(caster, playerID, abilityLevel, duration)

  -- if abilityLevel > 3 then
    -- local npcCreepList = {
      -- "npc_dota_neutral_alpha_wolf",
      -- "npc_dota_neutral_centaur_khan",
      -- "npc_dota_neutral_dark_troll_warlord",
      -- "npc_dota_neutral_polar_furbolg_ursa_warrior",
      -- "npc_dota_neutral_satyr_hellcaller"
    -- }

    -- local levelUnitName = npcCreepList[RandomInt(1, 5)]

    -- local npcCreep = self:SpawnUnit(levelUnitName, caster, playerID, abilityLevel, duration, false)
  -- end
end

function beastmaster_call_of_the_wild_boar_oaa:OnUpgrade()
  local abilityLevel = self:GetLevel()
  local hawk_ability = self:GetCaster():FindAbilityByName("beastmaster_call_of_the_wild_hawk_oaa")

	-- Check to not enter a level up loop
  if hawk_ability and hawk_ability:GetLevel() ~= abilityLevel then
		hawk_ability:SetLevel(abilityLevel)
	end
end

function beastmaster_call_of_the_wild_boar_oaa:SpawnBoar(caster, playerID, abilityLevel, duration)
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

function beastmaster_call_of_the_wild_boar_oaa:SpawnUnit(levelUnitName, caster, playerID, abilityLevel, duration, bRandomPosition)
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

beastmaster_call_of_the_wild_hawk_oaa = class(AbilityBaseClass)

LinkLuaModifier( "modifier_hawk_invisibility_oaa", "abilities/oaa_call_of_the_wild.lua", LUA_MODIFIER_MOTION_NONE )

function beastmaster_call_of_the_wild_hawk_oaa:OnSpellStart()
  local caster = self:GetCaster()
  local playerID = caster:GetPlayerID()
  local abilityLevel = self:GetLevel()
  local duration = self:GetSpecialValueFor("duration")

  self:SpawnHawk(caster, playerID, abilityLevel, duration, 1)
end

function beastmaster_call_of_the_wild_hawk_oaa:SpawnHawk(caster, playerID, abilityLevel, duration, number_of_hawks)

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
    -- Invisibility buff
    hawk:AddNewModifier(caster, self, "modifier_hawk_invisibility_oaa", {})
  end

  caster:EmitSound("Hero_Beastmaster.Call.Hawk")
end

function beastmaster_call_of_the_wild_hawk_oaa:SpawnUnit(levelUnitName, caster, playerID, abilityLevel, duration, bRandomPosition)
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

--------------------------------------------------------------------------------

modifier_hawk_invisibility_oaa = class( ModifierBaseClass )

--------------------------------------------------------------------------------

function modifier_hawk_invisibility_oaa:IsHidden()
  return true
end

function modifier_hawk_invisibility_oaa:IsDebuff()
  return false
end

function modifier_hawk_invisibility_oaa:IsPurgable()
  return false
end

function modifier_hawk_invisibility_oaa:OnCreated()
  local particle = ParticleManager:CreateParticle("particles/generic_hero_status/status_invisibility_start.vpcf", PATTACH_ABSORIGIN, self:GetParent())
  ParticleManager:ReleaseParticleIndex(particle)
end

function modifier_hawk_invisibility_oaa:DeclareFunctions()
  local funcs = { MODIFIER_PROPERTY_INVISIBILITY_LEVEL, }
  return funcs
end

function modifier_hawk_invisibility_oaa:GetModifierInvisibilityLevel()
  if IsClient() then
    return 1
  end
end

function modifier_hawk_invisibility_oaa:CheckState()
  if IsServer() then
    local state = { [MODIFIER_STATE_INVISIBLE] = true}
    return state
  end
end

function modifier_hawk_invisibility_oaa:GetPriority()
  return MODIFIER_PRIORITY_ULTRA
end
