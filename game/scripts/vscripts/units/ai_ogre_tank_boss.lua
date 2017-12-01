LinkLuaModifier("ogre_tank_boss_jump_smash", "abilities/siltbreaker/npc_dota_creature_ogre_tank_boss/ogre_tank_boss_jump_smash.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("ogre_tank_boss_melee_smash", "abilities/siltbreaker/npc_dota_creature_ogre_tank_boss/ogre_tank_boss_melee_smash.lua", LUA_MODIFIER_MOTION_NONE)

function Spawn( entityKeyValues )
	if not IsServer() then
		return
	end

	if thisEntity == nil then
		return
	end

	thisEntity.SmashAbility = thisEntity:FindAbilityByName( "ogre_tank_boss_melee_smash" )
	thisEntity.JumpAbility = thisEntity:FindAbilityByName( "ogre_tank_boss_jump_smash" )

	thisEntity:SetContextThink( "OgreTankBossThink", OgreTankBossThink, 1 )
end

function OgreTankBossThink()
	if ( not IsValidEntity(thisEntity) or not thisEntity:IsAlive() ) then
		return -1
	end

	if GameRules:IsGamePaused() == true then
		return 1
	end

	if not thisEntity.bInitialized then
		thisEntity.vInitialSpawnPos = thisEntity:GetOrigin()
    thisEntity.bInitialized = true
    SpawnAllies()
	end

	-- Are we too far from our initial spawn position?
	local fDist = ( thisEntity:GetOrigin() - thisEntity.vInitialSpawnPos ):Length2D()
	if fDist > 2000 then
		RetreatHome()
		return 2.0
	end

	local nEnemiesRemoved = 0
	local enemies = FindUnitsInRadius( thisEntity:GetTeamNumber(), thisEntity:GetOrigin(), nil, 1200, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES + DOTA_UNIT_TARGET_FLAG_FOW_VISIBLE, FIND_CLOSEST, false )
	for i = 1, #enemies do
		local enemy = enemies[i]
		if enemy ~= nil then
			local flDist = ( enemy:GetOrigin() - thisEntity:GetOrigin() ):Length2D()
			if flDist < 300 then
				nEnemiesRemoved = nEnemiesRemoved + 1
				table.remove( enemies, i )
			end
		end
	end

	if thisEntity.JumpAbility ~= nil and thisEntity.JumpAbility:IsFullyCastable() and nEnemiesRemoved > 0 then
		return Jump()
	end

	if #enemies == 0 then
		RetreatHome()
		return 1
	end

	if thisEntity.SmashAbility ~= nil and thisEntity.SmashAbility:IsFullyCastable() then
		return Smash( enemies[ 1 ] )
	end

	return 0.5
end

function SpawnAllies()
  local posTopLeft = thisEntity:GetAbsOrigin()
  posTopLeft.y = posTopLeft.y + 400
  posTopLeft.x = posTopLeft.x - 400
  local posTopRight = thisEntity:GetAbsOrigin()
  posTopRight.y = posTopRight.y + 400
  posTopRight.x = posTopRight.x + 400
  local ally1 = CreateUnitByName("npc_dota_creature_ogre_seer", posTopLeft, true, thisEntity, thisEntity:GetOwner(), thisEntity:GetTeam())
  local ally2 = CreateUnitByName("npc_dota_creature_ogre_seer", posTopRight, true, thisEntity, thisEntity:GetOwner(), thisEntity:GetTeam())
end

function Jump()
	ExecuteOrderFromTable({
		UnitIndex = thisEntity:entindex(),
		OrderType = DOTA_UNIT_ORDER_CAST_NO_TARGET,
		AbilityIndex = thisEntity.JumpAbility:entindex(),
		Queue = false,
	})
	return 2.5
end


function Smash( enemy )
	if enemy == nil then
		return
	end

	if ( not thisEntity:HasModifier( "modifier_provide_vision" ) ) then
		--print( "If player can't see me, provide brief vision to his team as I start my Smash" )
		thisEntity:AddNewModifier( thisEntity, nil, "modifier_provide_vision", { duration = 1.5 } )
	end

	ExecuteOrderFromTable({
		UnitIndex = thisEntity:entindex(),
		OrderType = DOTA_UNIT_ORDER_CAST_POSITION,
		AbilityIndex = thisEntity.SmashAbility:entindex(),
		Position = enemy:GetOrigin(),
		Queue = false,
	})

	return 3 / thisEntity:GetHasteFactor()
end

function RetreatHome()
	ExecuteOrderFromTable({
		UnitIndex = thisEntity:entindex(),
		OrderType = DOTA_UNIT_ORDER_MOVE_TO_POSITION,
		Position = thisEntity.vInitialSpawnPos
	})
end

