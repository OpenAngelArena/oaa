function CDOTA_BaseNPC:PerformCleave(
  originalTarget,
  startRadius, endRadius, length,
  damage, damageType, damageFlags,
  targetTeam, targetUnit, targetFlags)

  return PerformCleave(self, nil, originalTarget,
      caster:GetTeamNumber(), caster:GetAbsOrigin(), caster:GetForwardVector(),
      startRadius, endRadius, length,
      damage, damageType, damageFlags,
      targetTeam, targetUnit, targetFlags)
end

function CDOTABaseAbility:PerformCleave(
  originalTarget,
  startRadius, endRadius, length,
  damage, damageType, damageFlags,
  targetTeam, targetUnit, targetFlags)

  local caster = self:GetCaster()
  return PerformCleave(caster, self, originalTarget,
      caster:GetTeamNumber(), caster:GetAbsOrigin(), caster:GetForwardVector(),
      startRadius, endRadius, length,
      damage, damageType, damageFlags,
      targetTeam, targetUnit, targetFlags)
end

-- damageFlags = DOTA_DAMAGE_FLAG_IGNORES_PHYSICAL_ARMOR -- Original Cleave
-- damageFlags = DOTA_DAMAGE_FLAG_NONE -- OAA Cleave
-- damageFlags = DOTA_DAMAGE_FLAG_REFLECTION -- If we do not want them to return damage from cleave

-- Required: attacker
-- Recommended: startRadius, endRadius, length (all of them cannot be nil or 0)
function PerformCleave(
  attacker, ability, originalTarget,
  teamNumber, position, direction,
  startRadius, endRadius, length,
  damage, damageType, damageFlags,
  targetTeam, targetUnit, targetFlags)

  if attacker == nil then
    return 0
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

  if startRadius == nil then
    startRadius = 150
  end
  if endRadius == nil then
    endRadius = 330
  end
  if length == nil then
    length = 625
  end
  if startRadius <= 0 or endRadius <= 0 or length <= 0 then
    print("Zero radius cleave!")
    return 0
  end

  if damage == nil then
    damage = 0
  end
  if damageType == nil then
    damageType = DAMAGE_TYPE_PHYSICAL
  end
  if damageFlags == nil then
    --damageFlags = DOTA_DAMAGE_FLAG_IGNORES_PHYSICAL_ARMOR -- Original Cleave
    damageFlags = DOTA_DAMAGE_FLAG_NONE -- OAA Cleave
    --damageFlags = DOTA_DAMAGE_FLAG_REFLECTION -- If we do not want them to return damage from cleave
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

  local units = FindUnitsInCone(teamNumber, direction, position, startRadius, endRadius, length, nil, targetTeam, targetUnit, targetFlags, FIND_CLOSEST, false)
  for _,unit in pairs(units) do
	if unit:GetAbsOrigin() ~= originalTarget:GetAbsOrigin() then
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

  return #units -- Return amounts of hit units
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
