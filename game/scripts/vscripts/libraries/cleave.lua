--cleaveInfo = {
--    startRadius = 150,
--    endRadius = 330,
--    length = 625
--}
--damageMult = 1.0
--damageType = DAMAGE_TYPE_PHYSICAL
--damageFlags = DOTA_DAMAGE_FLAG_IGNORES_PHYSICAL_ARMOR -- Original Cleave
--damageFlags = DOTA_DAMAGE_FLAG_NONE -- OAA Cleave
--damageFlags = DOTA_DAMAGE_FLAG_REFLECTION -- If we do not want them to return damage from cleave

--targetTeam = DOTA_UNIT_TARGET_TEAM_ENEMY
--targetUnit = DOTA_UNIT_TARGET_BASIC | DOTA_UNIT_TARGET_HERO
--targetFlags = DOTA_UNIT_TARGET_FLAG_NONE

-- Cleave from target's location
-- self.cleaveFromTarget
-- event.cleaveFromTarget
-- parent.cleaveFromTarget

-- Does not work for illusions (still play sound and show particle when provided)
-- Does not work on allies, towers, barracks, buildings and wards
-- Does not work with BREAK effect ( unit:PassivesDisabled() )
-- Does not work if event == nil or event.target == nil or event.target ~= self:GetParent()
function CDOTABaseAbility:PerformCleaveOnAttack(event, cleaveInfo, damageMult, soundName, hitSoundName, particleNameCleave, particleNameHit)
  if event == nil or event.target == nil or event.attacker ~= self:GetCaster() then
    return false
  end

  if damageMult == nil then
    damageMult = 1.0
  end

  local parent = self:GetCaster()
  local target = event.target

  -- Do not proc when passives are disabled
  if parent:PassivesDisabled() then
    return
  end

  -- Do not proc from Monkey King's Boundless Strike
  local activeAbility = parent:GetCurrentActiveAbility();
  if activeAbility ~= nil and activeAbility:GetAbilityName() == "monkey_king_boundless_strike" then
    return
  end

  -- Does not cleave upon attacking wards, buildings or allied units.
  if target:GetTeamNumber() == parent:GetTeamNumber() or
      target == nil or
      target:IsTower() or
      target:IsBarracks() or
      target:IsBuilding() or
      target:IsOther()
    then
    return false
  end

  -- Play the impact sound
  if soundName ~= nil then
    target:EmitSound( soundName )
  end

  local startEntity = parent
  -- Should cleave from target (set anywhere - unit, ability or event)
  -- Or is PA
  if self.cleaveFromTarget or event.cleaveFromTarget or parent.cleaveFromTarget or parent:GetName() == "npc_dota_hero_phantom_assassin" then
    startEntity = target
  end
  local startPos = startEntity:GetAbsOrigin()

  -- Play the impact particle
  if particleNameCleave ~= nil then
    local cleave_pfx = ParticleManager:CreateParticle( particleNameCleave, PATTACH_ABSORIGIN_FOLLOW, startEntity )
    ParticleManager:SetParticleControl( cleave_pfx, 0, target:GetAbsOrigin() )
    ParticleManager:ReleaseParticleIndex( cleave_pfx )
  end

  -- Not work on illusions (only visuals works)
  if parent:IsIllusion() then
    return false
  end

  local hitUnits = PerformCleave(
    parent, self, target,
    parent:GetTeamNumber(),
    startPos,
    (target:GetAbsOrigin() - parent:GetAbsOrigin()):Normalized(), --parent:GetForwardVector(),
    cleaveInfo,
    event.damage * damageMult
  )

  if particleNameHit ~= nil then
    for _,unit in pairs(hitUnits) do
      local cleave_hit_pfx = ParticleManager:CreateParticle( particleNameHit, PATTACH_ABSORIGIN, unit )
      ParticleManager:SetParticleControl( cleave_hit_pfx, 0, unit:GetAbsOrigin() )
      ParticleManager:ReleaseParticleIndex( cleave_hit_pfx )
    end
  end

  if hitSoundName ~= nil then
    for _,unit in pairs(hitUnits) do
      unit:EmitSound(hitSoundName)
    end
  end

  return hitUnits
end

function CDOTA_BaseNPC:PerformCleave(
  originalTarget,
  cleaveInfo,
  damage, damageType, damageFlags,
  targetTeam, targetUnit, targetFlags)

  return PerformCleave(self, nil, originalTarget,
      caster:GetTeamNumber(), caster:GetAbsOrigin(), caster:GetForwardVector(),
      cleaveInfo,
      damage, damageType, damageFlags,
      targetTeam, targetUnit, targetFlags)
end

function CDOTABaseAbility:PerformCleave(
  originalTarget,
  cleaveInfo,
  damage, damageType, damageFlags,
  targetTeam, targetUnit, targetFlags)

  local caster = self:GetCaster()
  return PerformCleave(caster, self, originalTarget,
      caster:GetTeamNumber(), caster:GetAbsOrigin(), caster:GetForwardVector(),
      cleaveInfo,
      damage, damageType, damageFlags,
      targetTeam, targetUnit, targetFlags)
end
-- damageFlags
-- DOTA_DAMAGE_FLAG_IGNORES_PHYSICAL_ARMOR -- Original Cleave
-- DOTA_DAMAGE_FLAG_NO_SPELL_AMPLIFICATION + DOTA_DAMAGE_FLAG_NO_SPELL_LIFESTEAL -- No spell lifesteal or amplification (DEFAULT for OAA)
-- DOTA_DAMAGE_FLAG_REFLECTION -- If we do not want them to return damage from cleave

-- Required: attacker
-- Recommended: cleaveInfo (no value can be <= 0)
function PerformCleave(
  attacker, ability, originalTarget,
  teamNumber, position, direction,
  cleaveInfo,
  damage, damageType, damageFlags,
  targetTeam, targetUnit, targetFlags)

  if attacker == nil then
    return nil
  end

  if teamNumber == nil then
    --teamNumber = DOTA_TEAM_NEUTRALS
    teamNumber = attacker:GetTeamNumber()
  end
  if position == nil then
    position = attacker:GetAbsOrigin()
  end
  if direction == nil or direction:Length2D() == 0 then
    direction = attacker:GetForwardVector()
  end
  direction = Vector(direction.x, direction.y, 0):Normalized() -- Make sure the direction vector is 2D only and normalized (length=1)

  if cleaveInfo == nil then
    cleaveInfo = {
        startRadius = 150,
        endRadius = 330,
        length = 625
    }
  else
    if cleaveInfo.startRadius == nil then
      cleaveInfo.startRadius = 150
    end
    if cleaveInfo.endRadius == nil then
      cleaveInfo.endRadius = 330
    end
    if cleaveInfo.length == nil then
      cleaveInfo.length = 625
    end
    if cleaveInfo.startRadius <= 0 or cleaveInfo.endRadius <= 0 or cleaveInfo.length <= 0 then
      print("Zero radius cleave!")
      return nil
    end
  end

  if damage == nil then
    damage = 0
  end
  if damageType == nil then
    damageType = DAMAGE_TYPE_PHYSICAL
  end
  if damageFlags == nil then
    damageFlags = bit.bor(DOTA_DAMAGE_FLAG_NO_SPELL_AMPLIFICATION, DOTA_DAMAGE_FLAG_NO_SPELL_LIFESTEAL)
  end

  if targetTeam == nil then
    targetTeam = DOTA_UNIT_TARGET_TEAM_ENEMY
  end
  if targetUnit == nil then
    targetUnit = bit.bor(DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_HERO)
  end
  if targetFlags == nil then
    targetFlags = DOTA_UNIT_TARGET_FLAG_NONE
  end

  local units = FindUnitsInCone(teamNumber, direction, position, cleaveInfo.startRadius, cleaveInfo.endRadius, cleaveInfo.length, nil, targetTeam, targetUnit, targetFlags, FIND_CLOSEST, false)
  for _,unit in pairs(units) do
    if originalTarget ~= nil and unit ~= originalTarget then
      local damageTable = {
        victim = unit,
        attacker = attacker,
        damage = damage,
        damage_type = damageType,
        damage_flags = damageFlags, --Optional.
        ability = ability, --Optional.
      }
      ApplyDamage(damageTable)
    end
  end

  return units -- Return hit units
end

-- Got from https://github.com/fcalife on https://github.com/OpenAngelArena/oaa/issues/2289
-- Cleave-like cone search - returns the units in front of the caster in a cone.
function FindUnitsInCone(teamNumber, vDirection, vPosition, startRadius, endRadius, flLength, hCacheUnit, targetTeam, targetUnit, targetFlags, findOrder, bCache)
  local vDirectionCone = Vector( vDirection.y, -vDirection.x, 0.0 )
  local enemies = FindUnitsInRadius(teamNumber, vPosition, hCacheUnit, endRadius + flLength, targetTeam, targetUnit, targetFlags, findOrder, bCache )
  local unitTable = {}
  if #enemies > 0 then
    for _,enemy in pairs(enemies) do
      if enemy ~= nil then
        local vToPotentialTarget = enemy:GetOrigin() - vPosition
        local flSideAmount = math.abs( vToPotentialTarget.x * vDirectionCone.x + vToPotentialTarget.y * vDirectionCone.y + vToPotentialTarget.z * vDirectionCone.z )
        local enemy_distance_from_caster = ( vToPotentialTarget.x * vDirection.x + vToPotentialTarget.y * vDirection.y + vToPotentialTarget.z * vDirection.z )

        -- Author of this "increase over distance": Fudge, pretty proud of this :D

        -- Calculate how much the width of the check can be higher than the starting point
        local max_increased_radius_from_distance = endRadius - startRadius

        -- Calculate how close the enemy is to the caster, in comparison to the total distance
        local pct_distance = enemy_distance_from_caster / flLength

        -- Calculate how much the width should be higher due to the distance of the enemy to the caster.
        local radius_increase_from_distance = max_increased_radius_from_distance * pct_distance

        if ( flSideAmount < startRadius + radius_increase_from_distance ) and ( enemy_distance_from_caster > 0.0 ) and ( enemy_distance_from_caster < flLength ) then
          table.insert(unitTable, enemy)
        end
      end
    end
  end
  return unitTable
end
