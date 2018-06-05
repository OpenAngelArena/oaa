
---------------------------------------------------------------------------

function Spawn( entityKeyValues )
	if thisEntity == nil then
		return
	end

	thisEntity.hSummonedUnits = { }
	thisEntity.nMaxSummonedUnits = 40
	thisEntity.nNumSummonCasts = 0

	thisEntity.bIsEnraged = false
	thisEntity.fOrigModelScale = thisEntity:GetModelScale()

	thisEntity.hLarvalParasiteAbility = thisEntity:FindAbilityByName( "spider_boss_larval_parasite_tier5" )
	thisEntity.hSummonEggsAbility = thisEntity:FindAbilityByName( "spider_boss_summon_eggs_tier5" )
  thisEntity.hRageAbility = thisEntity:FindAbilityByName( "spider_boss_rage_tier5" )

	thisEntity:SetContextThink( "SpiderBossThink", SpiderBossThink, 1 )
end

---------------------------------------------------------------------------

function SpiderBossThink()
	if ( not IsValidEntity(thisEntity) ) or ( not thisEntity:IsAlive()) then
		return -1
	end

	if GameRules:IsGamePaused() == true then
		return 1
	end

	-- Clean up our spawned units list if necessary
	for i, hSummonedUnit in ipairs( thisEntity.hSummonedUnits ) do
		if hSummonedUnit:IsNull() or hSummonedUnit == nil or hSummonedUnit:IsAlive() == false then
			table.remove( thisEntity.hSummonedUnits, i )
		end
	end

	if not thisEntity.bInitialized then
		thisEntity.vInitialSpawnPos = thisEntity:GetOrigin()
    thisEntity.bInitialized = true
    thisEntity.bHasAgro = false
    thisEntity.fAgroRange = thisEntity:GetAcquisitionRange()
    thisEntity:SetIdleAcquire(false)
    thisEntity:SetAcquisitionRange(0)
    -- if thisEntity.hSummonEggsAbility ~= nil and thisEntity.hSummonEggsAbility:IsFullyCastable() then
		-- 	return CastSummonEggs()
		-- end
  end

  local enemies = FindUnitsInRadius(
    thisEntity:GetTeamNumber(),
    thisEntity:GetOrigin(),
    nil,
    thisEntity:GetCurrentVisionRange(),
    DOTA_UNIT_TARGET_TEAM_ENEMY,
    DOTA_UNIT_TARGET_HERO,
    DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES + DOTA_UNIT_TARGET_FLAG_FOW_VISIBLE,
    FIND_CLOSEST,
    false )

  local fHpPercent = (thisEntity:GetHealth() / thisEntity:GetMaxHealth()) * 100
  local hasDamageThreshold = thisEntity:GetMaxHealth() - thisEntity:GetHealth() > thisEntity.BossTier * BOSS_AGRO_FACTOR;
  local fDistanceToOrigin = ( thisEntity:GetOrigin() - thisEntity.vInitialSpawnPos ):Length2D()

  --Aggro
  if (fDistanceToOrigin < 10 and thisEntity.bHasAgro and #enemies == 0) then
    DebugPrint("Spider Boss Deaggro")
    thisEntity.bHasAgro = false
    thisEntity:SetIdleAcquire(false)
    thisEntity:SetAcquisitionRange(0)
    return 2
  elseif hasDamageThreshold and #enemies > 0 then
    if not thisEntity.bHasAgro then
      DebugPrint("Spider Boss Aggro")
      thisEntity.bHasAgro = true
      thisEntity:SetIdleAcquire(false)
      thisEntity:SetAcquisitionRange(thisEntity.fAgroRange)
    end
  end

  -- Leash
  if not thisEntity.bHasAgro or #enemies==0 or fDistanceToOrigin > BOSS_LEASH_SIZE then
    if fDistanceToOrigin > 10 then
      return RetreatHome()
    end
    return 1
  end

	if fHpPercent < 85 and #thisEntity.hSummonedUnits < thisEntity.nMaxSummonedUnits then
		if thisEntity.hSummonEggsAbility ~= nil and thisEntity.hSummonEggsAbility:IsFullyCastable() then
			return CastSummonEggs()
		end
	end

	if thisEntity.bIsEnraged == false and fHpPercent < 50 and thisEntity.hRageAbility ~= nil and thisEntity.hRageAbility:IsFullyCastable() then
		return CastRage()
  end

	if fHpPercent < 90 and thisEntity.hLarvalParasiteAbility ~= nil and thisEntity.hLarvalParasiteAbility:IsFullyCastable() then
		return CastLarvalParasite()
	end

	return Attack(enemies[1])
end


----------------------------------------------------------------------------------------------
function Attack( target)
  DebugPrint("Attack")
  ExecuteOrderFromTable({
    UnitIndex = thisEntity:entindex(),
    OrderType = DOTA_UNIT_ORDER_ATTACK_MOVE,
    Position = target:GetAbsOrigin(),
    Queue = 0,
  })

	return 1.5
end

----------------------------------------------------------------------------------------------

function RetreatHome()
  DebugPrint("RetreatHome")
	ExecuteOrderFromTable({
		UnitIndex = thisEntity:entindex(),
		OrderType = DOTA_UNIT_ORDER_MOVE_TO_POSITION,
		Position = thisEntity.vInitialSpawnPos
  })
  return 6
end

----------------------------------------------------------------------------------------------

function CastLarvalParasite()
  DebugPrint("CastLarvalParasite")
	ExecuteOrderFromTable({
		UnitIndex = thisEntity:entindex(),
		OrderType = DOTA_UNIT_ORDER_CAST_NO_TARGET,
		AbilityIndex = thisEntity.hLarvalParasiteAbility:entindex(),
		Queue = false,
	})

	return 2.3
end

----------------------------------------------------------------------------------------------

function CastSummonEggs()
  DebugPrint("CastSummonEggs")
	ExecuteOrderFromTable({
		UnitIndex = thisEntity:entindex(),
		OrderType = DOTA_UNIT_ORDER_CAST_NO_TARGET,
		AbilityIndex = thisEntity.hSummonEggsAbility:entindex(),
	})

	return 2.3
end

----------------------------------------------------------------------------------------------

function CastRage()
  DebugPrint("CastRage")
	PlayHungerSpeech()

	ExecuteOrderFromTable({
		UnitIndex = thisEntity:entindex(),
		OrderType = DOTA_UNIT_ORDER_CAST_NO_TARGET,
		AbilityIndex = thisEntity.hRageAbility:entindex(),
	})

	return 1.8
end

----------------------------------------------------------------------------------------------

function PlayHungerSpeech()
	local nSound = RandomInt( 1, 6 )
	if nSound == 1 then
		thisEntity:EmitSound("broodmother_broo_ability_hunger_01")
	end
	if nSound == 2 then
		thisEntity:EmitSound("broodmother_broo_ability_hunger_02")
	end
	if nSound == 3 then
		thisEntity:EmitSound("broodmother_broo_ability_hunger_03")
	end
	if nSound == 4 then
		thisEntity:EmitSound("broodmother_broo_ability_hunger_04")
	end
	if nSound == 5 then
		thisEntity:EmitSound("broodmother_broo_ability_hunger_05")
	end
	if nSound == 6 then
		thisEntity:EmitSound("broodmother_broo_ability_hunger_06")
	end
end

--------------------------------------------------------------------------------
