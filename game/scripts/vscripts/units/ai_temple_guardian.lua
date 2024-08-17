
function Spawn( entityKeyValues )
  if not thisEntity or not IsServer() then
    return
  end

  LinkLuaModifier("modifier_temple_guardian_statue", "abilities/boss/temple_guardian/modifier_temple_guardian_statue.lua", LUA_MODIFIER_MOTION_NONE)

  thisEntity.HammerSmashAbility = thisEntity:FindAbilityByName( "temple_guardian_hammer_smash" ) or thisEntity:FindAbilityByName( "temple_guardian_hammer_smash_tier5" )
  thisEntity.HammerThrowAbility = thisEntity:FindAbilityByName( "temple_guardian_hammer_throw" ) or thisEntity:FindAbilityByName( "temple_guardian_hammer_throw_tier5" )
  thisEntity.PurificationAbility = thisEntity:FindAbilityByName( "temple_guardian_purification" ) or thisEntity:FindAbilityByName( "temple_guardian_purification_tier5" )
  thisEntity.WrathAbility = thisEntity:FindAbilityByName( "temple_guardian_wrath" ) or thisEntity:FindAbilityByName( "temple_guardian_wrath_tier5" )

  thisEntity.RageHammerSmashAbility = thisEntity:FindAbilityByName( "temple_guardian_rage_hammer_smash" ) or thisEntity:FindAbilityByName( "temple_guardian_rage_hammer_smash_tier5" )
  thisEntity.RageHammerSmashAbility:SetHidden( false )

  thisEntity:SetContextThink( "TempleGuardianThink", TempleGuardianThink, 1 )
end

function TempleGuardianThink()
	if GameRules:State_Get() >= DOTA_GAMERULES_STATE_POST_GAME or not IsValidEntity(thisEntity) or not thisEntity:IsAlive() then
    return -1
  end

  if GameRules:IsGamePaused() then
    return 1
  end

	if thisEntity:IsChanneling() == true then
		return 0.1
  end

  if not thisEntity.bInitialized then
    thisEntity.vInitialSpawnPos = thisEntity:GetAbsOrigin()
    thisEntity.bHasAgro = false
    thisEntity.bIsEnraged = false
    thisEntity.BossTier = thisEntity.BossTier or 4
    thisEntity.SiltBreakerProtection = true
    thisEntity.bInitialized = true
  end

  local function IsValidTarget(target)
    return not target:IsNull() and target:IsAlive() and not target:IsAttackImmune() and not target:IsInvulnerable() and not target:IsOutOfGame() and not target:IsCourier()
  end

  local function FindValidTarget(candidates)
    for _, enemy in ipairs(candidates) do
      if IsValidTarget(enemy) then
        return enemy
      end
    end
    return nil
  end

  local enemies = FindUnitsInRadius(
    thisEntity:GetTeamNumber(),
    thisEntity:GetAbsOrigin(),
    nil,
    thisEntity:GetCurrentVisionRange(),
    DOTA_UNIT_TARGET_TEAM_ENEMY,
    bit.bor(DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_BASIC),
    bit.bor(DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, DOTA_UNIT_TARGET_FLAG_FOW_VISIBLE),
    FIND_CLOSEST,
    false
  )

  local hasDamageThreshold = thisEntity:GetMaxHealth() - thisEntity:GetHealth() > thisEntity.BossTier * BOSS_AGRO_FACTOR
  local fDistanceToOrigin = ( thisEntity:GetAbsOrigin() - thisEntity.vInitialSpawnPos ):Length2D()

  -- Remove debuff protection that was added during retreat
  thisEntity:RemoveModifierByName("modifier_anti_stun_oaa")

  if not thisEntity.bHasAgro then
    -- Aggro conditions
    if #enemies > 0 and hasDamageThreshold then
      -- Aggro
      thisEntity.bHasAgro = true
      thisEntity:RemoveModifierByName( "modifier_temple_guardian_statue" )
      thisEntity:RemoveGesture(ACT_DOTA_CAST_ABILITY_7)
      if not thisEntity.bIsEnraged then
        thisEntity:AddNewModifier( thisEntity, nil, "modifier_invulnerable", { duration = 3 } )
        thisEntity:StartGestureWithPlaybackRate(ACT_DOTA_CAST_ABILITY_5, 3.0)
        return 3.3
      end
      return 1
    end
  else
    -- Deaggro conditions
    if #enemies == 0 and not hasDamageThreshold then
      -- Deaggro
      thisEntity.bHasAgro = false
      if fDistanceToOrigin < 10 then
        return 1
      end
    end
  end

  -- Leash
  if not thisEntity.bHasAgro or fDistanceToOrigin > BOSS_LEASH_SIZE then
    if fDistanceToOrigin > 10 and not thisEntity:HasModifier("modifier_temple_guardian_statue") then
      return RetreatHome()
    elseif not thisEntity:HasModifier("modifier_temple_guardian_statue") and not thisEntity.bIsEnraged then
      thisEntity:StartGesture(ACT_DOTA_CAST_ABILITY_7)
      thisEntity:AddNewModifier(thisEntity, nil, "modifier_temple_guardian_statue", {})
    end
    return 1
  end

  thisEntity.fFuzz = RandomFloat(0.1, 0.5) -- Adds some timing separation to these units
  if thisEntity:GetUnitName() == "npc_dota_creature_temple_guardian_tier5" then
    thisEntity.fFuzz = RandomFloat(0, 0.2)
  end

  local hGuardians = {}

  table.insert( hGuardians, thisEntity )
  if IsValidEntity(thisEntity.hBrother) and thisEntity.hBrother:IsAlive() then
    table.insert( hGuardians, thisEntity.hBrother )
  end

  if #hGuardians == 1 and not thisEntity.bIsEnraged then
    -- Our brother died, swap for enraged version of hammer smash
    if thisEntity:GetUnitName() == "npc_dota_creature_temple_guardian_tier5" then
      thisEntity:SwapAbilities( "temple_guardian_hammer_smash_tier5", "temple_guardian_rage_hammer_smash_tier5", false, true )
    else
      thisEntity:SwapAbilities( "temple_guardian_hammer_smash", "temple_guardian_rage_hammer_smash", false, true )
    end
    thisEntity.bIsEnraged = true
    thisEntity.fTimeEnrageStarted = GameRules:GetGameTime()
  end

	if thisEntity.WrathAbility and thisEntity.WrathAbility:IsCooldownReady() and #hGuardians == 1 and thisEntity:GetHealthPercent() < 90 then
		if thisEntity.fTimeEnrageStarted and ( GameRules:GetGameTime() > ( thisEntity.fTimeEnrageStarted + 5 ) ) then
			return Wrath()
		end
	end

	if thisEntity.HammerThrowAbility and thisEntity.HammerThrowAbility:IsCooldownReady() and thisEntity:GetHealthPercent() < 90 then
		local hLastEnemy = enemies[ #enemies ]
		if hLastEnemy then
			local flDist = (hLastEnemy:GetAbsOrigin() - thisEntity:GetAbsOrigin()):Length2D()
			if flDist > 450 then
				return Throw( hLastEnemy )
			end
		end
	end

	for _, hGuardian in pairs( hGuardians ) do
		if hGuardian and not hGuardian:IsNull() and hGuardian:IsAlive() and ( hGuardian ~= thisEntity or #hGuardians == 1 ) and ( hGuardian:GetHealthPercent() < 80 ) and thisEntity.PurificationAbility and thisEntity.PurificationAbility:IsFullyCastable() then
			return Purification( hGuardian )
		end
	end

	if not thisEntity.bIsEnraged then
		if thisEntity.HammerSmashAbility and thisEntity.HammerSmashAbility:IsCooldownReady() then
			return Smash(FindValidTarget(enemies))
		end
	else
		if thisEntity.RageHammerSmashAbility and thisEntity.RageHammerSmashAbility:IsFullyCastable() then
			return RageSmash(FindValidTarget(enemies))
		end
	end

	return 0.5
end

function RetreatHome()
  -- Add Debuff Protection when leashing
  thisEntity:AddNewModifier(thisEntity, nil, "modifier_anti_stun_oaa", {})

  local current_loc = thisEntity:GetAbsOrigin()
  local destination1 = thisEntity.vInitialSpawnPos + Vector(0, 100, 0)
  local destination2 = thisEntity.vInitialSpawnPos
  local distance1 = (destination1 - current_loc):Length2D()
  local distance2 = (destination2 - destination1):Length2D()
  local speed = thisEntity:GetIdealSpeed()
  local retreat_time = (distance1 + distance2) / speed

  ExecuteOrderFromTable({
    UnitIndex = thisEntity:entindex(),
    OrderType = DOTA_UNIT_ORDER_MOVE_TO_POSITION,
    Position = destination1,
    Queue = false,
  })
   ExecuteOrderFromTable({
    UnitIndex = thisEntity:entindex(),
    OrderType = DOTA_UNIT_ORDER_MOVE_TO_POSITION,
    Position = destination2,
    Queue = true,
  })

  return retreat_time + 0.5
end

function Wrath()
  thisEntity:DispelWeirdDebuffs()

  local wrath_ability = thisEntity.WrathAbility
  local cast_point = wrath_ability:GetCastPoint()
  local channel_duration = wrath_ability:GetChannelTime()

  ExecuteOrderFromTable({
    UnitIndex = thisEntity:entindex(),
    OrderType = DOTA_UNIT_ORDER_CAST_NO_TARGET,
    AbilityIndex = wrath_ability:entindex(),
    Queue = false,
  })

  return cast_point + channel_duration + 1
end

function Throw( enemy )
  if enemy and not enemy:IsNull() then
    thisEntity:DispelWeirdDebuffs()

    local hammer_throw_ability = thisEntity.HammerThrowAbility
    local cast_point = hammer_throw_ability:GetCastPoint()
    local throw_duration = hammer_throw_ability:GetSpecialValueFor("throw_duration")

    ExecuteOrderFromTable({
      UnitIndex = thisEntity:entindex(),
      OrderType = DOTA_UNIT_ORDER_CAST_POSITION,
      AbilityIndex = hammer_throw_ability:entindex(),
      Position = enemy:GetAbsOrigin(),
      Queue = false,
    })

    return cast_point + throw_duration + thisEntity.fFuzz
  end

  return 0.5
end

function Purification( friendly )
  thisEntity:DispelWeirdDebuffs()

  local purification_ability = thisEntity.PurificationAbility
  local cast_point = purification_ability:GetCastPoint()

  ExecuteOrderFromTable({
    UnitIndex = thisEntity:entindex(),
    OrderType = DOTA_UNIT_ORDER_CAST_TARGET,
    AbilityIndex = purification_ability:entindex(),
    TargetIndex = friendly:entindex(),
    Queue = false,
  })

  return cast_point + thisEntity.fFuzz
end

function Smash( enemy )
  if enemy and not enemy:IsNull() then
    thisEntity:DispelWeirdDebuffs()

    local smash_ability = thisEntity.HammerSmashAbility
    local cast_point = smash_ability:GetCastPoint()
    local swing_time = smash_ability:GetSpecialValueFor("base_swing_speed")
    local total = cast_point + swing_time + 0.5

    if not thisEntity:HasModifier( "modifier_provide_vision" ) then
      --print( "If player can't see me, provide brief vision to his team as I start my Smash" )
      thisEntity:AddNewModifier( enemy, nil, "modifier_provide_vision", { duration = total } )
    end

    ExecuteOrderFromTable({
      UnitIndex = thisEntity:entindex(),
      OrderType = DOTA_UNIT_ORDER_CAST_POSITION,
      AbilityIndex = smash_ability:entindex(),
      Position = enemy:GetAbsOrigin(),
      Queue = false,
    })

    return cast_point + swing_time + thisEntity.fFuzz
  end

  return 0.5
end

function RageSmash( enemy )
  if enemy and not enemy:IsNull() then
    thisEntity:DispelWeirdDebuffs()

    local rage_smash_ability = thisEntity.RageHammerSmashAbility
    local cast_point = rage_smash_ability:GetCastPoint()
    local swing_time = rage_smash_ability:GetSpecialValueFor("base_swing_speed")
    local total = cast_point + swing_time + 0.5

    if not thisEntity:HasModifier( "modifier_provide_vision" ) then
      --print( "If player can't see me, provide brief vision to his team as I start my Smash" )
      thisEntity:AddNewModifier( enemy, nil, "modifier_provide_vision", { duration = total } )
    end

    ExecuteOrderFromTable({
      UnitIndex = thisEntity:entindex(),
      OrderType = DOTA_UNIT_ORDER_CAST_POSITION,
      AbilityIndex = rage_smash_ability:entindex(),
      Position = enemy:GetAbsOrigin(),
      Queue = false,
    })

    return total
  end

  return 0.5
end
