shadow_shaman_mass_serpent_ward = class(AbilityBaseClass)

function shadow_shaman_mass_serpent_ward:GetAOERadius()
	return self:GetSpecialValueFor("spawn_radius")
end

function shadow_shaman_mass_serpent_ward:OnSpellStart()
  local caster = self:GetCaster()
  local playerID = caster:GetPlayerID()
  local casterTeam = caster:GetTeamNumber()
  local owner = caster:GetOwner()
  local casterForwardVector = caster:GetForwardVector()
  local targetPoint = self:GetCursorPosition()
  local wardCount = self:GetSpecialValueFor("ward_count")
  local duration = self:GetSpecialValueFor("duration")
  local unitName = "npc_dota_shadow_shaman_ward_" .. self:GetLevel()
  local spawnSpacing = 64
  local xSpaceVector = Vector(spawnSpacing, 0, 0)
  local ySpaceVector = Vector(0, spawnSpacing, 0)

  -- Check whether the caster has the extra ward hitpoint talent
  local casterHasWardHealth = caster:HasLearnedAbility("special_bonus_unique_shadow_shaman_1")

  local wardBonusHealth = 0
  if casterHasWardHealth then
    wardBonusHealth = caster:FindAbilityByName("special_bonus_unique_shadow_shaman_1"):GetSpecialValueFor("value")
  end

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
    serpentWard:SetControllableByPlayer(playerID, false)
    serpentWard:SetOwner(caster)
    -- Give extra health from talent
    serpentWard:SetBaseMaxHealth(serpentWard:GetMaxHealth() + wardBonusHealth)
    serpentWard:AddNewModifier(caster, self, "modifier_shadow_shaman_serpent_ward", {duration = duration})
    serpentWard:SetForwardVector(casterForwardVector)
  end

  -- Use tail because we don't want the result for n = 0
  local spawnLocations = tail(tabulate(GetNthSpawnLocation))
  foreach(SpawnWard, take(wardCount, spawnLocations))
  EmitSoundOnLocationWithCaster(targetPoint, "Hero_ShadowShaman.SerpentWard", caster)
end
