
function Spawn( entityKeyValues )
	if thisEntity == nil then
		return
	end

	if IsServer() == false then
		return
	end


	thisEntity.hVolcanoAbility = thisEntity:FindAbilityByName( "boss_magma_mage_volcano" )

	thisEntity:SetContextThink( "MagmaMageBossThink", MagmaMageBossThink, 1 )
end


function MagmaMageBossThink()
	if GameRules:IsGamePaused() == true or GameRules:State_Get() == DOTA_GAMERULES_STATE_POST_GAME or thisEntity:IsAlive() == false then
		return 1
  end

  if not thisEntity.bInitialized then
		thisEntity.vInitialSpawnPos = thisEntity:GetOrigin()
    thisEntity.bInitialized = true
    thisEntity.bHasAgro = false
    thisEntity.fAgroRange = thisEntity:GetAcquisitionRange(  )
    thisEntity:SetIdleAcquire(false)
    thisEntity:SetAcquisitionRange(0)
	end

  local hEnemies = FindUnitsInRadius(
    thisEntity:GetTeamNumber(),
    thisEntity:GetOrigin(), nil,
    thisEntity:GetCurrentVisionRange(),
    DOTA_UNIT_TARGET_TEAM_ENEMY,
    DOTA_UNIT_TARGET_HERO,
    DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES + DOTA_UNIT_TARGET_FLAG_FOW_VISIBLE,
    FIND_CLOSEST,
    false )

  local hasDamageThreshold = thisEntity:GetMaxHealth() - thisEntity:GetHealth() > thisEntity.BossTier * BOSS_AGRO_FACTOR;
  local fDistanceToOrigin = ( thisEntity:GetOrigin() - thisEntity.vInitialSpawnPos ):Length2D()

	--Agro
  if (fDistanceToOrigin < 10 and thisEntity.bHasAgro and #hEnemies == 0) then
    DebugPrint("MagmaMage Boss Deaggro")
    thisEntity.bHasAgro = false
    thisEntity:SetIdleAcquire(false)
    thisEntity:SetAcquisitionRange(0)
    thisEntity.hVolcanoAbility:KillAllVolcanos()
    thisEntity.hVolcanoAbility:SetLevel(1) --back to phase 1
    return 2
  elseif (hasDamageThreshold and #hEnemies > 0) then
    if not thisEntity.bHasAgro then
      DebugPrint("MagmaMage Boss Aggro")
      thisEntity.bHasAgro = true
      thisEntity:SetIdleAcquire(true)
      thisEntity:SetAcquisitionRange(thisEntity.fAgroRange)
    end
  end

  -- Leash
  if not thisEntity.bHasAgro or #hEnemies==0 or fDistanceToOrigin > 2000 then
    if fDistanceToOrigin > 10 then
      return RetreatHome()
    end
    return 1
  end

  	if (thisEntity:GetHealthPercent() <= 50) and (thisEntity.hVolcanoAbility:GetLevel() < 3) then
  		thisEntity.hVolcanoAbility:SetLevel(3)
  	elseif (thisEntity:GetHealthPercent() <= 75) and (thisEntity.hVolcanoAbility:GetLevel() < 2) then
  		thisEntity.hVolcanoAbility:SetLevel(2)
  	end

  	print("MAGMA_MAGE phase ", thisEntity.hVolcanoAbility:GetLevel())

	if thisEntity.hVolcanoAbility ~= nil and thisEntity.hVolcanoAbility:IsFullyCastable() and (thisEntity.hVolcanoAbility:GetNumVolcanos() <= 10) then
		return CastVolcano()
	end

	if (thisEntity.hVolcanoAbility:GetLevel() >= 3) and (thisEntity:GetHealthPercent() < 60) and (thisEntity.hVolcanoAbility:GetNumVolcanos() > 0) then

		if thisEntity:HasModifier("modifier_boss_magma_mage_volcano_burning_effect") then
			return HoldPosition()
		else 
			return GoToMagma()
		end
	end

	if #hEnemies == 0 then
		return GoToMagma()
	else
		return AttackRandomEnemy(hEnemies)
	end

	return 0.5
end


function RetreatHome()
	ExecuteOrderFromTable({
		UnitIndex = thisEntity:entindex(),
		OrderType = DOTA_UNIT_ORDER_MOVE_TO_POSITION,
		Position = thisEntity.vInitialSpawnPos
  })
  return 6
end

function HoldPosition() --not really hold, attack move onto current position. hold stops auto attacks for some reason
	ExecuteOrderFromTable({
		UnitIndex = thisEntity:entindex(),
		OrderType = DOTA_UNIT_ORDER_ATTACK_MOVE,
		Position = thisEntity:GetOrigin(),
  })
  return 2.5
end

function AttackRandomEnemy( hEnemies )
	ExecuteOrderFromTable({
		UnitIndex = thisEntity:entindex(),
		OrderType = DOTA_UNIT_ORDER_ATTACK_TARGET,
		TargetIndex = (hEnemies[math.random(#hEnemies)]):entindex()
  })
  return 1.5
end


function GoToMagma()
	local vPosition = thisEntity.hVolcanoAbility:FindClosestMagmaPool()
	if vPosition == nil then
		return 0.3
	end
	ExecuteOrderFromTable({
		UnitIndex = thisEntity:entindex(),
		OrderType = DOTA_UNIT_ORDER_MOVE_TO_POSITION,
		Position = thisEntity.hVolcanoAbility:FindClosestMagmaPool()
  })
  return 2
end


function CastVolcano()
	ExecuteOrderFromTable({
		UnitIndex = thisEntity:entindex(),
		OrderType = DOTA_UNIT_ORDER_CAST_NO_TARGET,
		AbilityIndex = thisEntity.hVolcanoAbility:entindex(),
	})
	local cast_point = thisEntity.hVolcanoAbility:GetCastPoint() or 1
	return cast_point + 0.1
end