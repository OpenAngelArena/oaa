LinkLuaModifier("modifier_generic_dead_tracker_oaa", "modifiers/modifier_generic_dead_tracker_oaa.lua", LUA_MODIFIER_MOTION_NONE)

beastmaster_call_of_the_wild_boar_oaa = class(AbilityBaseClass)

function beastmaster_call_of_the_wild_boar_oaa:OnSpellStart()
  local caster = self:GetCaster()
  local playerID = caster:GetPlayerID()
  local abilityLevel = self:GetLevel()
  local duration = self:GetSpecialValueFor("duration")

  self:SpawnBoar(caster, playerID, abilityLevel, duration)

  caster:EmitSound("Hero_Beastmaster.Call.Boar")

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
  local boar_hp = self:GetLevelSpecialValueFor("boar_health", abilityLevel-1)
  local boar_dmg = self:GetLevelSpecialValueFor("boar_damage", abilityLevel-1)
  local boar_armor = self:GetLevelSpecialValueFor("boar_armor", abilityLevel-1)
  local boar_speed = self:GetLevelSpecialValueFor("boar_move_speed", abilityLevel-1)

  -- Talent that increases attack damage of boars
  local talent = caster:FindAbilityByName("special_bonus_unique_beastmaster_2_oaa")
  if talent and talent:GetLevel() > 0 then
    boar_dmg = boar_dmg + talent:GetSpecialValueFor("value")
  end

  -- Spawn boar and orient it to face the same way as the caster
  local boar = self:SpawnUnit(levelUnitName, caster, playerID, abilityLevel, duration, false)
  boar:AddNewModifier(caster, self, "modifier_beastmaster_boar_poison", {})

  -- Fix stats of boars
  -- HP
  boar:SetBaseMaxHealth(boar_hp)
  boar:SetMaxHealth(boar_hp)
  boar:SetHealth(boar_hp)

  -- DAMAGE
  boar:SetBaseDamageMin(boar_dmg)
  boar:SetBaseDamageMax(boar_dmg)

  -- ARMOR
  boar:SetPhysicalArmorBaseValue(boar_armor)

  -- MOVEMENT SPEED
  boar:SetBaseMoveSpeed(boar_speed)

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
  npcCreep:AddNewModifier(caster, self, "modifier_generic_dead_tracker_oaa", {duration = duration + MANUAL_GARBAGE_CLEANING_TIME})

  return npcCreep
end

---------------------------------------------------------------------------------------------------

beastmaster_call_of_the_wild_hawk_oaa = class(AbilityBaseClass)

LinkLuaModifier( "modifier_hawk_invisibility_oaa", "abilities/oaa_call_of_the_wild.lua", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_hawk_shard_truesight", "abilities/oaa_call_of_the_wild.lua", LUA_MODIFIER_MOTION_NONE )

function beastmaster_call_of_the_wild_hawk_oaa:GetAOERadius()
  return self:GetSpecialValueFor("hawk_vision")
end

function beastmaster_call_of_the_wild_hawk_oaa:OnSpellStart()
  local target_loc = self:GetCursorPosition()
  local caster = self:GetCaster()
  local playerID = caster:GetPlayerID()
  local abilityLevel = self:GetLevel()
  local duration = self:GetSpecialValueFor("duration")

  local hawk = self:SpawnHawk(caster, playerID, abilityLevel, duration, 1)

  caster:EmitSound("Hero_Beastmaster.Call.Hawk")

  Timers:CreateTimer(2/30, function()
    if hawk and target_loc then
      hawk:MoveToPosition(target_loc)
    end
  end)
end

function beastmaster_call_of_the_wild_hawk_oaa:SpawnHawk(caster, playerID, abilityLevel, duration, number_of_hawks)
  local unit_name = "npc_dota_beastmaster_hawk_oaa"
  local hawk_hp = self:GetLevelSpecialValueFor("hawk_hp", abilityLevel-1)
  local hawk_armor = self:GetLevelSpecialValueFor("hawk_armor", abilityLevel-1)
  local hawk_speed = self:GetLevelSpecialValueFor("hawk_speed", abilityLevel-1)
  local hawk_vision = self:GetLevelSpecialValueFor("hawk_vision", abilityLevel-1)
  local hawk_magic_resistance = self:GetLevelSpecialValueFor("hawk_magic_resistance", abilityLevel-1)
  local hawk_gold_bounty = self:GetLevelSpecialValueFor("hawk_gold_bounty", abilityLevel-1)

  if caster:HasShardOAA() then
    hawk_magic_resistance = 100
  end

  for i = 1, number_of_hawks do
    -- Spawn hawk and orient it to face the same way as the caster
    local hawk = self:SpawnUnit(unit_name, caster, playerID, abilityLevel, duration, true)

    -- Create particle effects
    local particleName = "particles/units/heroes/hero_beastmaster/beastmaster_call_bird.vpcf"
    local particle1 = ParticleManager:CreateParticle(particleName, PATTACH_CUSTOMORIGIN, caster)
    ParticleManager:SetParticleControl(particle1, 0, hawk:GetOrigin())
    ParticleManager:ReleaseParticleIndex(particle1)

    -- Invisibility buff
    hawk:AddNewModifier(caster, self, "modifier_hawk_invisibility_oaa", {})

    -- Fix stats of hawks
    -- HP
    hawk:SetBaseMaxHealth(hawk_hp)
    hawk:SetMaxHealth(hawk_hp)
    hawk:SetHealth(hawk_hp)

    -- ARMOR
    hawk:SetPhysicalArmorBaseValue(hawk_armor)

    -- MOVEMENT SPEED
    hawk:SetBaseMoveSpeed(hawk_speed)

    -- VISION
    hawk:SetDayTimeVisionRange(hawk_vision)
    hawk:SetNightTimeVisionRange(hawk_vision)

    -- Magic Resistance
    hawk:SetBaseMagicalResistanceValue(hawk_magic_resistance)

    -- GOLD BOUNTY
    hawk:SetMaximumGoldBounty(hawk_gold_bounty)
    hawk:SetMinimumGoldBounty(hawk_gold_bounty)

    if caster:HasShardOAA() then
      local dive_bomb = hawk:AddAbility("beastmaster_hawk_dive_oaa")
      dive_bomb:SetLevel(1)
      -- True-Sight buff
      hawk:AddNewModifier(caster, self, "modifier_hawk_shard_truesight", {})
    end

    if number_of_hawks == 1 then
      return hawk
    end
  end
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
  npcCreep:AddNewModifier(caster, self, "modifier_generic_dead_tracker_oaa", {duration = duration + MANUAL_GARBAGE_CLEANING_TIME})

  return npcCreep
end

---------------------------------------------------------------------------------------------------

modifier_hawk_invisibility_oaa = class(ModifierBaseClass)

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
  return {
    MODIFIER_PROPERTY_INVISIBILITY_LEVEL,
  }
end

function modifier_hawk_invisibility_oaa:GetModifierInvisibilityLevel()
  if IsClient() then
    return 1
  end
end

function modifier_hawk_invisibility_oaa:CheckState()
  return {
    [MODIFIER_STATE_INVISIBLE] = true,
  }
end

function modifier_hawk_invisibility_oaa:GetPriority()
  return MODIFIER_PRIORITY_ULTRA
end

---------------------------------------------------------------------------------------------------

modifier_hawk_shard_truesight = class(ModifierBaseClass)

function modifier_hawk_shard_truesight:IsHidden()
  return true
end

function modifier_hawk_shard_truesight:IsDebuff()
  return false
end

function modifier_hawk_shard_truesight:IsPurgable()
  return false
end

function modifier_hawk_shard_truesight:IsAura()
  return true
end

function modifier_hawk_shard_truesight:GetModifierAura()
  return "modifier_truesight"
end

function modifier_hawk_shard_truesight:GetAuraRadius()
  local parent = self:GetParent()
  return parent:GetCurrentVisionRange() or 1100
end

function modifier_hawk_shard_truesight:GetAuraSearchTeam()
  return DOTA_UNIT_TARGET_TEAM_ENEMY
end

function modifier_hawk_shard_truesight:GetAuraSearchType()
  return DOTA_UNIT_TARGET_ALL
end

function modifier_hawk_shard_truesight:GetAuraSearchFlags()
  return bit.bor(DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, DOTA_UNIT_TARGET_FLAG_INVULNERABLE)
end
