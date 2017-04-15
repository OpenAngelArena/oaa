shadow_shaman_mass_serpent_ward = class({})

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

  function GetNthSpawnLocation(n)
    n = n + 1
    if n == 1 then
      return targetPoint + ySpaceVector
    elseif n == 2 then
      return targetPoint - ySpaceVector
    else
      local x = n - 2
      local m = math.ceil(x/2) - 1
      local k = math.ceil(x/6)
      return targetPoint + k * xSpaceVector * (-1)^x + (1-(m % 3)) * ySpaceVector
    end
  end

  function SpawnWard(point)
    local serpentWard = CreateUnitByName(unitName, point, true, caster, owner, casterTeam)
    serpentWard:SetControllableByPlayer(playerID, false)
    serpentWard:AddNewModifier(caster, self, "modifier_shadow_shaman_serpent_ward", {duration = duration})
    serpentWard:SetForwardVector(casterForwardVector)
  end

  local spawnLocations = tabulate(GetNthSpawnLocation)
  foreach(SpawnWard, take(wardCount, spawnLocations))
  EmitSoundOnLocationWithCaster(targetPoint, "Hero_ShadowShaman.SerpentWard", caster)
end
