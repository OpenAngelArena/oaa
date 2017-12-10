
---------------------------------------------------------------------------

function Spawn( entityKeyValues )
	if thisEntity == nil then
		return
	end

	thisEntity.hSummonedUnits = { }
	thisEntity.nMaxSummonedUnits = 60
	thisEntity.nNumSummonCasts = 0

	thisEntity.bIsEnraged = false
	thisEntity.fOrigModelScale = thisEntity:GetModelScale()

	thisEntity.hLarvalParasiteAbility = thisEntity:FindAbilityByName( "spider_boss_larval_parasite" )
	thisEntity.hSummonEggsAbility = thisEntity:FindAbilityByName( "spider_boss_summon_eggs" )
  thisEntity.hRageAbility = thisEntity:FindAbilityByName( "spider_boss_rage" )

	thisEntity:SetContextThink( "SpiderBossThink", SpiderBossThink, 1 )
end

---------------------------------------------------------------------------

function SpiderBossThink()
	if ( thisEntity:IsNull() ) or ( thisEntity == nil ) or ( thisEntity:IsAlive() == false ) then
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
    if thisEntity.hSummonEggsAbility ~= nil and thisEntity.hSummonEggsAbility:IsFullyCastable() then
			return CastSummonEggs()
		end
  end

	-- Are we too far from our initial spawn position?
	local fDist = ( thisEntity:GetOrigin() - thisEntity.vInitialSpawnPos ):Length2D()
	if fDist > 2000 then
		RetreatHome()
		return 0.5
  end

  local healthPercent = thisEntity:GetHealthPercent()

  if fDist < 50 and healthPercent > 90 then
    -- Do not agro
		return 0.5
  end

	local hEnemies = FindUnitsInRadius( thisEntity:GetTeamNumber(), thisEntity:GetOrigin(), nil, 1500, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES + DOTA_UNIT_TARGET_FLAG_FOW_VISIBLE, FIND_CLOSEST, false )
	if #hEnemies == 0 then
		return 1
  end

	if healthPercent < 85 and #thisEntity.hSummonedUnits < thisEntity.nMaxSummonedUnits then
		if thisEntity.hSummonEggsAbility ~= nil and thisEntity.hSummonEggsAbility:IsFullyCastable() then
			return CastSummonEggs()
		end
	end

	if thisEntity.bIsEnraged == false and healthPercent < 50 and thisEntity.hRageAbility ~= nil and thisEntity.hRageAbility:IsFullyCastable() then
		return CastRage()
  end

	if healthPercent < 95 and thisEntity.hLarvalParasiteAbility ~= nil and thisEntity.hLarvalParasiteAbility:IsFullyCastable() then
		return CastLarvalParasite()
	end

  ExecuteOrderFromTable({
    UnitIndex = thisEntity:entindex(),
    OrderType = DOTA_UNIT_ORDER_ATTACK_TARGET,
    TargetIndex = hEnemies[1]:entindex(),
    Queue = 0
  })

	return 1.5
end

---------------------------------------------------------------------------

function RetreatHome()
	ExecuteOrderFromTable({
		UnitIndex = thisEntity:entindex(),
		OrderType = DOTA_UNIT_ORDER_MOVE_TO_POSITION,
		Position = thisEntity.vInitialSpawnPos
	})
end

----------------------------------------------------------------------------------------------

function CastLarvalParasite()
	ExecuteOrderFromTable({
		UnitIndex = thisEntity:entindex(),
		OrderType = DOTA_UNIT_ORDER_CAST_NO_TARGET,
		AbilityIndex = thisEntity.hLarvalParasiteAbility:entindex(),
		Queue = false,
	})

	return 4.0
end

----------------------------------------------------------------------------------------------

function CastSummonEggs()
	ExecuteOrderFromTable({
		UnitIndex = thisEntity:entindex(),
		OrderType = DOTA_UNIT_ORDER_CAST_NO_TARGET,
		AbilityIndex = thisEntity.hSummonEggsAbility:entindex(),
	})

	return 4.0
end

----------------------------------------------------------------------------------------------

function CastRage()
	PlayHungerSpeech()

	ExecuteOrderFromTable({
		UnitIndex = thisEntity:entindex(),
		OrderType = DOTA_UNIT_ORDER_CAST_NO_TARGET,
		AbilityIndex = thisEntity.hRageAbility:entindex(),
	})

	return 4.0
end

----------------------------------------------------------------------------------------------

function PlayHungerSpeech()
	local nSound = RandomInt( 1, 6 )
	if nSound == 1 then
		EmitSoundOn( "broodmother_broo_ability_hunger_01", thisEntity )
	end
	if nSound == 2 then
		EmitSoundOn( "broodmother_broo_ability_hunger_02", thisEntity )
	end
	if nSound == 3 then
		EmitSoundOn( "broodmother_broo_ability_hunger_03", thisEntity )
	end
	if nSound == 4 then
		EmitSoundOn( "broodmother_broo_ability_hunger_04", thisEntity )
	end
	if nSound == 5 then
		EmitSoundOn( "broodmother_broo_ability_hunger_05", thisEntity )
	end
	if nSound == 6 then
		EmitSoundOn( "broodmother_broo_ability_hunger_06", thisEntity )
	end
end

--------------------------------------------------------------------------------
