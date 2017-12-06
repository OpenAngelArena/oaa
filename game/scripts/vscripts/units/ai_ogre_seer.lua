
--------------------------------------------------------------------------------

function Spawn( entityKeyValues )
	if not IsServer() then
		return
	end

	if thisEntity == nil then
		return
	end

	thisEntity.IgniteAbility = thisEntity:FindAbilityByName( "ogre_seer_area_ignite" )
	thisEntity.BloodlustAbility = thisEntity:FindAbilityByName( "ogre_magi_channelled_bloodlust" )

	thisEntity:SetContextThink( "OgreSeerThink", OgreSeerThink, 1 )
end

--------------------------------------------------------------------------------

function OgreSeerThink()
	if ( not thisEntity:IsAlive() ) then
		return -1
	end

	if GameRules:IsGamePaused() == true then
		return 1
  end

  if not thisEntity.bInitialized then
		thisEntity.vInitialSpawnPos = thisEntity:GetOrigin()
		thisEntity.bInitialized = true
	end

	if thisEntity.BloodlustAbility ~= nil and thisEntity.BloodlustAbility:IsChanneling() then
		return 0.5
	end

	local enemies = FindUnitsInRadius( thisEntity:GetTeamNumber(), thisEntity:GetOrigin(), nil, 800, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES + DOTA_UNIT_TARGET_FLAG_FOW_VISIBLE, FIND_CLOSEST, false )

	local bIgniteReady = ( #enemies > 0 and thisEntity.IgniteAbility ~= nil and thisEntity.IgniteAbility:IsFullyCastable() )

	if thisEntity.BloodlustAbility ~= nil and thisEntity.BloodlustAbility:IsFullyCastable() then
		local friendlies = FindUnitsInRadius( thisEntity:GetTeamNumber(), thisEntity:GetOrigin(), nil, 1500, DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_ALL, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, FIND_CLOSEST, false )
		for _,friendly in pairs ( friendlies ) do
			if friendly ~= nil then
				if ( friendly:GetUnitName() == "npc_dota_creature_ogre_tank" ) or ( friendly:GetUnitName() == "npc_dota_creature_ogre_tank_boss" ) then
					local fDist = ( friendly:GetOrigin() - thisEntity:GetOrigin() ):Length2D()
					local fCastRange = thisEntity.BloodlustAbility:GetCastRange( thisEntity:GetOrigin(), nil )
					if ( fDist <= fCastRange ) and ( ( #enemies > 0 ) or ( friendly:GetAggroTarget() ) ) then
            return Bloodlust( friendly )
					elseif ( fDist > 600 ) and ( fDist < 1500 ) and (friendly:GetUnitName() == "npc_dota_creature_ogre_tank_boss") and ( #enemies > 0 )  then
						if bIgniteReady == false then
              return Approach( friendly )
          elseif #enemies == 0 then
            RetreatHome()
            return 1
						end
					end
				end
			end
		end
  end

	if bIgniteReady then
		return IgniteArea( enemies[ RandomInt( 1, #enemies ) ] )
	end

	local fFuzz = RandomFloat( -0.1, 0.1 ) -- Adds some timing separation to these seers
	return 0.5 + fFuzz
end

--------------------------------------------------------------------------------

function Approach( hUnit )
	local vToUnit = hUnit:GetOrigin() - thisEntity:GetOrigin()
	vToUnit = vToUnit:Normalized()

	ExecuteOrderFromTable({
		UnitIndex = thisEntity:entindex(),
		OrderType = DOTA_UNIT_ORDER_MOVE_TO_POSITION,
		Position = thisEntity:GetOrigin() + vToUnit * thisEntity:GetIdealSpeed()
	})

	return 1
end

--------------------------------------------------------------------------------

function Bloodlust( hUnit )
	ExecuteOrderFromTable({
		UnitIndex = thisEntity:entindex(),
		OrderType = DOTA_UNIT_ORDER_CAST_TARGET,
		AbilityIndex = thisEntity.BloodlustAbility:entindex(),
		TargetIndex = hUnit:entindex(),
		Queue = false,
	})

	return 1
end

--------------------------------------------------------------------------------

function IgniteArea( hEnemy )
	ExecuteOrderFromTable({
		UnitIndex = thisEntity:entindex(),
		OrderType = DOTA_UNIT_ORDER_CAST_POSITION,
		AbilityIndex = thisEntity.IgniteAbility:entindex(),
		Position = hEnemy:GetOrigin(),
		Queue = false,
	})

	return 0.55
end

--------------------------------------------------------------------------------

function RetreatHome()
	ExecuteOrderFromTable({
		UnitIndex = thisEntity:entindex(),
		OrderType = DOTA_UNIT_ORDER_MOVE_TO_POSITION,
		Position = thisEntity.vInitialSpawnPos
	})
end
