
visage_summon_familiars_oaa = class(AbilityBaseClass)

function visage_summon_familiars_oaa:OnSpellStart()
  local caster = self:GetCaster()
  local playerID = caster:GetPlayerID()
  local abilityLevel = self:GetLevel()

  if caster.familiars == nil then
    caster.familiars = {}
  end

  -- Kill non-dead familiars created with previous cast of this spell
  for _, v in pairs(caster.familiars) do
    if v and not v:IsNull() then
      if v:IsAlive() then
        v:ForceKillOAA(false)
      end
    end
  end

  local baseUnitName = "npc_dota_visage_familiar"
  local levelUnitName = "npc_dota_visage_familiar3"
  if abilityLevel <= 3 then
    levelUnitName = baseUnitName .. abilityLevel
  end

  -- KV variables
  local number_of_familiars = self:GetSpecialValueFor("total_familiars")
  local familiar_hp = self:GetLevelSpecialValueFor("familiar_hp", abilityLevel-1)
  local familiar_armor = self:GetLevelSpecialValueFor("familiar_armor", abilityLevel-1)
  local familiar_dmg = self:GetLevelSpecialValueFor("familiar_attack_damage", abilityLevel-1)
  local familiar_speed = self:GetLevelSpecialValueFor("familiar_speed", abilityLevel-1)

  for i = 1, number_of_familiars do
    local familiar = self:SpawnUnit(levelUnitName, caster, playerID, i)

    -- Level the familiar's stone form ability to match ability level
    local stoneFormAbility = familiar:FindAbilityByName("visage_summon_familiars_stone_form")
    if stoneFormAbility then
      stoneFormAbility:SetLevel(abilityLevel)
    end

    -- Add built-in modifier that handles flying and other stuff
    familiar:AddNewModifier(caster, self, "modifier_visage_summon_familiars_damage_charge", {})

    -- Fix stats of familiars
    -- HP
    familiar:SetBaseMaxHealth(familiar_hp)
    familiar:SetMaxHealth(familiar_hp)
    familiar:SetHealth(familiar_hp)

    -- DAMAGE
    familiar:SetBaseDamageMin(familiar_dmg)
    familiar:SetBaseDamageMax(familiar_dmg)

    -- ARMOR
    familiar:SetPhysicalArmorBaseValue(familiar_armor)

    -- Set Familiar movement speed
    familiar:SetBaseMoveSpeed(familiar_speed)

    -- Create particle effects
    --local particleName = ".vpcf"
    --local particle = ParticleManager:CreateParticle(particleName, PATTACH_CUSTOMORIGIN, caster)
    --ParticleManager:SetParticleControl(particle, 0, unit:GetOrigin())
    --ParticleManager:ReleaseParticleIndex(particle)

    -- Store familiars on the caster handle
    table.insert(caster.familiars, familiar)
  end

  -- Sound
  caster:EmitSound("Hero_Visage.SummonFamiliars.Cast")
end

function visage_summon_familiars_oaa:OnUpgrade()
  local caster = self:GetCaster()
  local abilityLevel = self:GetLevel()
  local self_cast_ability = caster:FindAbilityByName("visage_stone_form_self_cast")

  -- Check to not enter a level up loop
  if self_cast_ability and self_cast_ability:GetLevel() ~= abilityLevel then
    self_cast_ability:SetLevel(abilityLevel)
  end

  -- Shard hidden ability
  if caster:HasShardOAA() then
    local stone_form_ability = caster:FindAbilityByName("visage_summon_familiars_stone_form")

    -- Check to not enter a level up loop
    if stone_form_ability then
      if stone_form_ability:GetLevel() ~= abilityLevel then
        stone_form_ability:SetLevel(abilityLevel)
      end
    end
  end
end

function visage_summon_familiars_oaa:SpawnUnit(unit_name, caster, playerID, n)
  local position = caster:GetAbsOrigin()

  -- Directions
  local direction = caster:GetForwardVector()
  direction.z = 0.0
  direction = direction:Normalized()
  local perpendicular_direction = Vector(direction.y, -direction.x, 0.0)

  -- Distances
  local distance_in_front_of_caster = 200
  local distance_between = 120

  -- Spawn locations
  local spawn_location = position + direction * distance_in_front_of_caster
  if n == 1 then
    spawn_location = spawn_location - perpendicular_direction * (distance_between / 2)
  elseif n == 2 then
    spawn_location = spawn_location + perpendicular_direction * (distance_between / 2)
  end

  local unit = CreateUnitByName(unit_name, spawn_location, true, caster, caster:GetOwner(), caster:GetTeam())
  unit:SetControllableByPlayer(playerID, false)
  unit:SetOwner(caster)
  unit:SetForwardVector(direction)
  --FindClearSpaceForUnit(unit, spawn_location, true)

  return unit
end
