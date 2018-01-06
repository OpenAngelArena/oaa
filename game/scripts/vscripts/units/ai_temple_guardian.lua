LinkLuaModifier( "modifier_temple_guardian_statue", "modifiers/modifier_temple_guardian_statue", LUA_MODIFIER_MOTION_NONE )

function Spawn( entityKeyValues )
	if not IsServer() then
		return
	end

	if thisEntity == nil then
		return
	end

	thisEntity.bIsEnraged = false

	HammerSmashAbility = thisEntity:FindAbilityByName( "temple_guardian_hammer_smash" )
	HammerThrowAbility = thisEntity:FindAbilityByName( "temple_guardian_hammer_throw" )
	PurificationAbility = thisEntity:FindAbilityByName( "temple_guardian_purification" )
	WrathAbility = thisEntity:FindAbilityByName( "temple_guardian_wrath" )

	RageHammerSmashAbility = thisEntity:FindAbilityByName( "temple_guardian_rage_hammer_smash" )
	RageHammerSmashAbility:SetHidden( false )
  thisEntity:StartGesture( ACT_DOTA_CAST_ABILITY_7 )

	thisEntity:SetContextThink( "TempleGuardianThink", TempleGuardianThink, 1 )
end

function TempleGuardianThink()
	if ( not thisEntity:IsAlive() ) then
		return -1
	end

	if GameRules:IsGamePaused() == true then
		return 1
	end

	if thisEntity:IsChanneling() == true then
		return 0.1
  end

  if not thisEntity.bInitialized then
		thisEntity.vInitialSpawnPos = thisEntity:GetOrigin()
    thisEntity.bInitialized = true
    thisEntity.bHasAgro = false
    thisEntity:AddNewModifier( thisEntity, nil, "modifier_temple_guardian_statue", {} )
	end

  local enemies = FindUnitsInRadius( thisEntity:GetTeamNumber(), thisEntity:GetOrigin(), nil, thisEntity:GetCurrentVisionRange(), DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES , FIND_CLOSEST, false )
  local fHpPercent = thisEntity:GetHealthPercent()
  local fDistanceToOrigin = ( thisEntity:GetOrigin() - thisEntity.vInitialSpawnPos ):Length2D()

  --Agro
  if (fDistanceToOrigin < 10 and thisEntity.bHasAgro and #enemies == 0) then
    thisEntity.bHasAgro = false
    thisEntity:AddNewModifier( thisEntity, nil, "modifier_temple_guardian_statue", {} )
    return 5
  elseif (fHpPercent < 100 and #enemies > 0) or FrendlyHasAgro() then
    if not thisEntity.bHasAgro then
      thisEntity.bHasAgro = true
      thisEntity:RemoveModifierByName( "modifier_temple_guardian_statue" )
      thisEntity:AddNewModifier( thisEntity, nil, "modifier_invulnerable", { duration = 3 } )
      thisEntity:StartGestureWithPlaybackRate(ACT_DOTA_CAST_ABILITY_5, 3.0)

      Timers:CreateTimer(2.5, function ()
        thisEntity:RemoveGesture( ACT_DOTA_CAST_ABILITY_7 )
      end)
      return 3.3
    end
  end

  -- Leash
  if not thisEntity.bHasAgro or #enemies==0 or fDistanceToOrigin > 2000 then
    if fDistanceToOrigin > 10 then
      return RetreatHome()
    end
    return 1
  end

  thisEntity.fFuzz = RandomFloat( 0, 0.2 ) -- Adds some timing separation to these units

  local hGuardians = {}

  table.insert( hGuardians, thisEntity )
  if IsValidEntity(thisEntity.hBrother) and thisEntity.hBrother:IsAlive() then
    table.insert( hGuardians, thisEntity.hBrother )
  end

	if #hGuardians == 1 and ( not thisEntity.bIsEnraged ) then
		-- Our brother died, swap for enraged version of hammer smash
		thisEntity:SwapAbilities( "temple_guardian_hammer_smash", "temple_guardian_rage_hammer_smash", false, true )
		thisEntity.bIsEnraged = true
		thisEntity.fTimeEnrageStarted = GameRules:GetGameTime()
	end

	if WrathAbility ~= nil and WrathAbility:IsCooldownReady() and #hGuardians == 1 and thisEntity:GetHealthPercent() < 90 then
		if thisEntity.fTimeEnrageStarted and ( GameRules:GetGameTime() > ( thisEntity.fTimeEnrageStarted + 5 ) ) then
			return Wrath()
		end
	end

	if HammerThrowAbility ~= nil and HammerThrowAbility:IsCooldownReady() and thisEntity:GetHealthPercent() < 90 then
		local hLastEnemy = enemies[ #enemies ]
		if hLastEnemy ~= nil then
			local flDist = (hLastEnemy:GetOrigin() - thisEntity:GetOrigin()):Length2D()
			if flDist > 450 then
				return Throw( hLastEnemy )
			end
		end
	end

	for _, hGuardian in pairs( hGuardians ) do
		if hGuardian ~= nil and hGuardian:IsAlive() and ( hGuardian ~= thisEntity or #hGuardians == 1 ) and ( hGuardian:GetHealthPercent() < 80 ) and PurificationAbility ~= nil and PurificationAbility:IsFullyCastable() then
			return Purification( hGuardian )
		end
	end

	if not thisEntity.bIsEnraged then
		if HammerSmashAbility ~= nil and HammerSmashAbility:IsCooldownReady() then
			return Smash( enemies[ 1 ] )
		end
	else
		if RageHammerSmashAbility ~= nil and RageHammerSmashAbility:IsFullyCastable() then
			return RageSmash( enemies[ 1 ] )
		end
	end

	return 0.5
end

function FrendlyHasAgro()
  if IsValidEntity(thisEntity.hBrother) and thisEntity.hBrother:IsAlive() then
    return thisEntity.hBrother.bHasAgro
  else
    return true
  end
end

function RetreatHome()
	ExecuteOrderFromTable({
		UnitIndex = thisEntity:entindex(),
		OrderType = DOTA_UNIT_ORDER_MOVE_TO_POSITION,
		Position = thisEntity.vInitialSpawnPos + Vector(0,10,0),
		Queue = false,
  })
	ExecuteOrderFromTable({
		UnitIndex = thisEntity:entindex(),
		OrderType = DOTA_UNIT_ORDER_MOVE_TO_POSITION,
		Position = thisEntity.vInitialSpawnPos,
		Queue = true,
  })
  return 2
end

function Wrath()
	print( "ai_temple_guardian - Wrath" )
	ExecuteOrderFromTable({
		UnitIndex = thisEntity:entindex(),
		OrderType = DOTA_UNIT_ORDER_CAST_NO_TARGET,
		AbilityIndex = WrathAbility:entindex(),
		Queue = false,
	})
	return 8
end

function Throw( enemy )
	print( "ai_temple_guardian - Throw" )
	ExecuteOrderFromTable({
		UnitIndex = thisEntity:entindex(),
		OrderType = DOTA_UNIT_ORDER_CAST_POSITION,
		AbilityIndex = HammerThrowAbility:entindex(),
		Position = enemy:GetOrigin(),
		Queue = false,
	})
	return 3 + thisEntity.fFuzz
end

function Purification( friendly )
	print( "ai_temple_guardian - Purification" )
	ExecuteOrderFromTable({
		UnitIndex = thisEntity:entindex(),
		OrderType = DOTA_UNIT_ORDER_CAST_TARGET,
		AbilityIndex = PurificationAbility:entindex(),
		TargetIndex = friendly:entindex(),
		Queue = false,
	})
	return 1.3 + thisEntity.fFuzz
end

function Smash( enemy )
	print( "ai_temple_guardian - Smash" )
	ExecuteOrderFromTable({
		UnitIndex = thisEntity:entindex(),
		OrderType = DOTA_UNIT_ORDER_CAST_POSITION,
		AbilityIndex = HammerSmashAbility:entindex(),
		Position = enemy:GetOrigin(),
		Queue = false,
	})
	return 1.4 + thisEntity.fFuzz
end

function RageSmash( enemy )
	print( "ai_temple_guardian - RageSmash" )
	ExecuteOrderFromTable({
		UnitIndex = thisEntity:entindex(),
		OrderType = DOTA_UNIT_ORDER_CAST_POSITION,
		AbilityIndex = RageHammerSmashAbility:entindex(),
		Position = enemy:GetOrigin(),
		Queue = false,
	})
	return 1.1 + thisEntity.fFuzz
end


