abyssal_underlord_cancel_dark_rift_oaa = class( AbilityBaseClass )

--------------------------------------------------------------------------------

function abyssal_underlord_cancel_dark_rift_oaa:IsStealable()
  return false
end

--------------------------------------------------------------------------------

function abyssal_underlord_cancel_dark_rift_oaa:ProcsMagicStick()
  return false
end

--------------------------------------------------------------------------------

function abyssal_underlord_cancel_dark_rift_oaa:OnSpellStart()
  local caster = self:GetCaster()
  local caster_location = caster:GetAbsOrigin()
  local should_teleport_caster = false
  local destination = caster.original_cast_location
  local radius = self:GetSpecialValueFor("radius")

  -- play modified gesture
  caster:StartGesture( ACT_DOTA_OVERRIDE_ABILITY_4 )

  -- Destroy all trees around the caster and around the destination if destination exists
  if destination then
    GridNav:DestroyTreesAroundPoint(caster_location, radius, true)
    GridNav:DestroyTreesAroundPoint(destination, radius, true)
  end

  local targetTeam = self:GetAbilityTargetTeam()
  local targetType = self:GetAbilityTargetType()
  local targetFlags = self:GetAbilityTargetFlags()

  local units_around_caster = FindUnitsInRadius(caster:GetTeamNumber(), caster_location, nil, radius, targetTeam, targetType, targetFlags, FIND_ANY_ORDER, false)
  for _, unit in pairs(units_around_caster) do
    -- Teleport only units that are stunned by Dark Rift
    if unit.HasModifier and unit:HasModifier("modifier_underlord_dark_rift_oaa_stun") then
      should_teleport_caster = true
      if destination then
        -- Teleport the unit
        unit:SetAbsOrigin(destination)
        FindClearSpaceForUnit(unit, destination, true)

        -- Disjoint disjointable/dodgeable projectiles
        ProjectileManager:ProjectileDodge(unit)

        -- Teleportation particle
        local part = ParticleManager:CreateParticle("particles/units/heroes/heroes_underlord/abbysal_underlord_darkrift_ambient_end.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
        ParticleManager:SetParticleControl(part, 2, unit:GetAbsOrigin())
        ParticleManager:SetParticleControl(part, 5, unit:GetAbsOrigin())
        ParticleManager:ReleaseParticleIndex(part)
      end
    end
  end

  -- Teleport the caster if there are any stunned units by him and if destination exists
  if should_teleport_caster and destination then
    -- Teleport the caster
    caster:SetAbsOrigin(destination)
    FindClearSpaceForUnit(caster, destination, true)
    caster.original_cast_location = nil

    -- Disjoint disjointable/dodgeable projectiles
    ProjectileManager:ProjectileDodge(caster)

    -- Teleportation particle
    local part2 = ParticleManager:CreateParticle("particles/units/heroes/heroes_underlord/abbysal_underlord_darkrift_ambient_end.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
    ParticleManager:SetParticleControl(part2, 2, caster:GetAbsOrigin())
    ParticleManager:SetParticleControl(part2, 5, caster:GetAbsOrigin())
    ParticleManager:ReleaseParticleIndex(part2)

    -- play teleportation sounds
    caster:EmitSound("Hero_AbyssalUnderlord.DarkRift.Aftershock")
    EmitSoundOnLocationWithCaster(destination, "Hero_AbyssalUnderlord.DarkRift.Aftershock", caster)
  end

	-- Remove particles
  if caster.partPortal1 then
    ParticleManager:DestroyParticle(caster.partPortal1, false)
    ParticleManager:ReleaseParticleIndex(caster.partPortal1)
    caster.partPortal1 = nil
  end
  if caster.partPortal2 then
    ParticleManager:DestroyParticle(caster.partPortal2, false)
    ParticleManager:ReleaseParticleIndex(caster.partPortal2)
    caster.partPortal2 = nil
  end
end
