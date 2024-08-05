shadow_shaman_mass_serpent_ward_oaa = class(AbilityBaseClass)

function shadow_shaman_mass_serpent_ward_oaa:GetAOERadius()
	return self:GetSpecialValueFor("spawn_radius")
end

-- Lazy hack to make shard work and not crash at later levels
function shadow_shaman_mass_serpent_ward_oaa:OnUpgrade()
  local caster = self:GetCaster()
  local ability_level = self:GetLevel()
  local vanilla_ability = caster:FindAbilityByName("shadow_shaman_mass_serpent_ward")

  if not vanilla_ability then
    return
  end

  if vanilla_ability:GetLevel() == 3 or ability_level >= 4 then
    return
  end

  vanilla_ability:SetLevel(ability_level)
end

function shadow_shaman_mass_serpent_ward_oaa:OnSpellStart()
  local caster = self:GetCaster()
  local playerID = caster:GetPlayerID()
  local casterTeam = caster:GetTeamNumber()
  local owner = caster:GetOwner()
  local casterForwardVector = caster:GetForwardVector()
  local targetPoint = self:GetCursorPosition()
  local isMegaWard = self:GetSpecialValueFor("is_mega_ward") == 1
  local megaWardScale = self:GetSpecialValueFor("mega_ward_model_scale_multiplier")
  local wardCount = self:GetSpecialValueFor("ward_count")
  local wardHealth = self:GetSpecialValueFor("ward_health")
  local wardDamage = self:GetSpecialValueFor("damage_tooltip")
  local duration = self:GetSpecialValueFor("duration")
  local unitName = "npc_dota_shadow_shaman_ward_" .. self:GetLevel()
  local spawnSpacing = 64
  local xSpaceVector = Vector(spawnSpacing, 0, 0)
  local ySpaceVector = Vector(0, spawnSpacing, 0)

  -- Returns the spawn position for the nth ward
  local function GetNthSpawnLocation(n)
    -- Top and bottom from target location first
    if n == 1 then
      return targetPoint + ySpaceVector
    elseif n == 2 then
      return targetPoint - ySpaceVector
    -- Generate pairs of columns with 3 each on left and right sides
    -- FIlls the column left to right, top to bottom
    elseif n >= 3 and n <= 8 then
      local x = n - 2
      local m = math.ceil(x/2) - 1
      local k = math.ceil(x/6)
      return targetPoint + k * xSpaceVector * (-1)^x + (1-(m % 3)) * ySpaceVector
    -- Generate pairs of columns with 2 each on left and right sides
    -- FIlls the column left to right, top to bottom
    else
      local m = math.ceil(n/2) - 1
      local k = math.ceil(n/4) - 1
      return targetPoint + k * xSpaceVector * (-1)^n + (-1)^m * ySpaceVector
    end
  end

  local function SpawnWard(point)
    local serpentWard = CreateUnitByName(unitName, point, true, caster, owner, casterTeam)
    serpentWard.isMegaWard = isMegaWard -- true or false
    serpentWard:SetControllableByPlayer(playerID, false)
    serpentWard:SetOwner(caster)

    -- Mark it as serpent ward
    serpentWard:AddNewModifier(caster, self, "modifier_shadow_shaman_serpent_ward", {duration = duration})

    -- Fix ward health
    serpentWard:SetBaseMaxHealth(wardHealth)
    serpentWard:SetMaxHealth(wardHealth)
    serpentWard:SetHealth(wardHealth)

    -- Fix ward damage
    serpentWard:SetBaseDamageMin(wardDamage)
    serpentWard:SetBaseDamageMax(wardDamage)

    -- Fix facing of the ward
    serpentWard:SetForwardVector(casterForwardVector)

    -- Fix size of the ward
    if isMegaWard then
      serpentWard:SetModelScale(megaWardScale)
    end
  end

  -- Use tail because we don't want the result for n = 0
  local spawnLocations = tail(tabulate(GetNthSpawnLocation))
  foreach(SpawnWard, take(wardCount, spawnLocations))
  EmitSoundOnLocationWithCaster(targetPoint, "Hero_ShadowShaman.SerpentWard", caster)
end
