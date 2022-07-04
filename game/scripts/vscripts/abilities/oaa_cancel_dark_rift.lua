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
  local start = caster.dark_rift_target
  local destination = caster.dark_rift_origin
  local radius = self:GetSpecialValueFor("radius")

  -- Don't continue if there are no stored locations on the caster
  if not start or not destination then
    return
  end

  local targetTeam = self:GetAbilityTargetTeam()
  local targetType = self:GetAbilityTargetType()
  local targetFlags = DOTA_UNIT_TARGET_FLAG_NONE --self:GetAbilityTargetFlags()

  local units = FindUnitsInRadius(caster:GetTeamNumber(), start, nil, radius, targetTeam, targetType, targetFlags, FIND_ANY_ORDER, false)
  for _, unit in pairs(units) do
    -- Teleport only units that are stunned by Dark Rift
    if unit and not unit:IsNull() and unit.HasModifier and unit:HasModifier("modifier_underlord_dark_rift_oaa_stun") then
      if not unit:IsOAABoss() then
        should_teleport_caster = true
        if destination then
          -- Teleport the unit
          unit:SetAbsOrigin(destination)
          FindClearSpaceForUnit(unit, destination, true)

          -- Disjoint disjointable/dodgeable projectiles
          ProjectileManager:ProjectileDodge(unit)

          -- Teleportation particle
          --local part = ParticleManager:CreateParticle("particles/units/heroes/heroes_underlord/abbysal_underlord_darkrift_ambient_end.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
          --ParticleManager:SetParticleControl(part, 2, unit:GetAbsOrigin())
          --ParticleManager:SetParticleControl(part, 5, unit:GetAbsOrigin())
          --ParticleManager:ReleaseParticleIndex(part)
        end
      end
    end
  end

  -- Teleport the caster if there are any stunned units by him and if destination exists
  if should_teleport_caster and destination then
    -- Sound before teleport
    caster:EmitSound("Hero_AbyssalUnderlord.DarkRift.Aftershock")
    -- Teleport the caster
    caster:SetAbsOrigin(destination)
    FindClearSpaceForUnit(caster, destination, true)

    -- Remove stored location
    caster.dark_rift_origin = nil
    caster.dark_rift_target = nil

    -- Disjoint disjointable/dodgeable projectiles
    ProjectileManager:ProjectileDodge(caster)

    -- Destroy all trees around the caster
    GridNav:DestroyTreesAroundPoint(caster_location, radius, true)

    -- Destroy all trees around destination
    GridNav:DestroyTreesAroundPoint(destination, radius, true)

    -- Teleportation particle
    --local part2 = ParticleManager:CreateParticle("particles/units/heroes/heroes_underlord/abbysal_underlord_darkrift_ambient_end.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
    --ParticleManager:SetParticleControl(part2, 2, caster:GetAbsOrigin())
    --ParticleManager:SetParticleControl(part2, 5, caster:GetAbsOrigin())
    --ParticleManager:ReleaseParticleIndex(part2)

    -- Sound after teleport
    EmitSoundOnLocationWithCaster(destination, "Hero_AbyssalUnderlord.DarkRift.Aftershock", caster)
  end

	-- Remove particles
  --[[
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
  ]]
end
