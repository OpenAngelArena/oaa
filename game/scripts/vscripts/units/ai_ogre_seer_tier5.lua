
--------------------------------------------------------------------------------

function Spawn( entityKeyValues )
	if not IsServer() then
		return
	end

	if thisEntity == nil then
		return
	end

	thisEntity.IgniteAbility = thisEntity:FindAbilityByName( "ogre_seer_area_ignite_tier5" )
	thisEntity.BloodlustAbility = thisEntity:FindAbilityByName( "ogre_magi_channelled_bloodlust_tier5" )

	thisEntity:SetContextThink( "OgreSeerThink", OgreSeerThink, 1 )
end

--------------------------------------------------------------------------------

function FindOgreBoss()
  local friendlies = FindUnitsInRadius( thisEntity:GetTeamNumber(), thisEntity:GetOrigin(), nil, thisEntity:GetCurrentVisionRange(), DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_ALL, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES + DOTA_UNIT_TARGET_FLAG_FOW_VISIBLE, 0, false )
  for _,friendly in pairs ( friendlies ) do
    if friendly ~= nil then
      if friendly:GetUnitName() == "npc_dota_creature_ogre_tank_boss_tier5" then
        return friendly
      end
    end
  end
end

--------------------------------------------------------------------------------

function OgreSeerThink()
	if ( not IsValidEntity(thisEntity) ) or ( not thisEntity:IsAlive()) or (thisEntity:IsDominated()) then
		return -1
	end

	if GameRules:IsGamePaused() == true then
		return 1
  end

  if not thisEntity.bInitialized then
		thisEntity.vInitialSpawnPos = thisEntity:GetOrigin()
    thisEntity.bInitialized = true
    thisEntity.bHasAgro = false
    thisEntity.fAgroRange = thisEntity:GetAcquisitionRange(  )
    thisEntity:SetIdleAcquire(false)
    thisEntity:SetAcquisitionRange(0)
    thisEntity.hOgreBoss = FindOgreBoss()
  end

  if thisEntity.hOgreBoss == nil or not thisEntity.hOgreBoss:IsAlive() then
    thisEntity.hOgreBoss = FindOgreBoss()
  end

	local enemies = FindUnitsInRadius( thisEntity:GetTeamNumber(), thisEntity:GetOrigin(), nil, thisEntity:GetCurrentVisionRange(), DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES + DOTA_UNIT_TARGET_FLAG_FOW_VISIBLE, 0, false )
  local fDistanceToOrigin = ( thisEntity:GetOrigin() - thisEntity.vInitialSpawnPos ):Length2D()

  local hasDamageThreshold = thisEntity:GetMaxHealth() - thisEntity:GetHealth() > BOSS_AGRO_FACTOR;
  if thisEntity.hOgreBoss then
    hasDamageThreshold = thisEntity:GetMaxHealth() - thisEntity:GetHealth() > thisEntity.hOgreBoss.BossTier * BOSS_AGRO_FACTOR;
  end

  --Agro
  if (IsValidEntity(thisEntity.hOgreBoss) and thisEntity.hOgreBoss:IsAlive() and not thisEntity.hOgreBoss.bHasAgro and thisEntity.bHasAgro and #enemies == 0) then
    DebugPrint("Ogre Seer Deagro")
    thisEntity.bHasAgro = false
    thisEntity:SetIdleAcquire(false)
    thisEntity:SetAcquisitionRange(0)
    return 2
  elseif thisEntity.hOgreBoss==nil or not thisEntity.hOgreBoss:IsAlive() or (hasDamageThreshold and #enemies > 0) or (thisEntity.hOgreBoss~=nil and thisEntity.hOgreBoss.bHasAgro) then
    if not thisEntity.bHasAgro then
      DebugPrint("Ogre Seer Agro")
      thisEntity.bHasAgro = true
      thisEntity:SetIdleAcquire(true)
      thisEntity:SetAcquisitionRange(thisEntity.fAgroRange)
    end
  end

  -- Leash
  if not thisEntity.bHasAgro or #enemies==0 or fDistanceToOrigin > 800 then
    if fDistanceToOrigin > 10 then
      return RetreatHome()
    end
    return 1
  end

	if thisEntity.BloodlustAbility ~= nil and thisEntity.BloodlustAbility:IsChanneling() then
		return 0.5
	end

  local bIgniteReady = ( #enemies > 0 and thisEntity.IgniteAbility ~= nil and thisEntity.IgniteAbility:IsFullyCastable() )
  local bBloodlustReady = ( thisEntity.hOgreBoss ~= nil and thisEntity.BloodlustAbility ~= nil and thisEntity.BloodlustAbility:IsFullyCastable() )
  local fBloodlustCastRange = thisEntity.BloodlustAbility:GetCastRange( thisEntity:GetOrigin(), nil )

	if bIgniteReady then
		return IgniteArea( enemies[ RandomInt( 1, #enemies ) ] )
	end

  if bBloodlustReady then
    local fDistanceToOgreBoss = ( thisEntity.hOgreBoss:GetOrigin() - thisEntity:GetOrigin() ):Length2D()
    -- If can cast bloodlust do it
    if ( fDistanceToOgreBoss <= fBloodlustCastRange )   then
      return Bloodlust( thisEntity.hOgreBoss )
    -- If cannot cast try to ignite first, then approach ogre
    elseif ( fDistanceToOgreBoss > 600 ) and ( fDistanceToOgreBoss < 1500 ) and ( not bIgniteReady )  then
      return Approach( thisEntity.hOgreBoss )
    end
	end

	local fFuzz = RandomFloat( -0.1, 0.1 ) -- Adds some timing separation to these seers
	return 0.5 + fFuzz
end

--------------------------------------------------------------------------------

function Approach( hUnit )
  DebugPrint("Approach")
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
  thisEntity:CastAbilityOnTarget( hUnit, thisEntity.BloodlustAbility, thisEntity:entindex() )
	return 1
end

--------------------------------------------------------------------------------

function IgniteArea( hEnemy )
  thisEntity:CastAbilityOnPosition( hEnemy:GetOrigin(), thisEntity.IgniteAbility, thisEntity:entindex() )
	return 1
end

--------------------------------------------------------------------------------

function RetreatHome()
  DebugPrint("RetreatHome Ogre Seer")
	ExecuteOrderFromTable({
		UnitIndex = thisEntity:entindex(),
		OrderType = DOTA_UNIT_ORDER_MOVE_TO_POSITION,
		Position = thisEntity.vInitialSpawnPos
  })
  return 6
end
