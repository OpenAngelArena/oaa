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
	thisEntity.OgreSummonSeers = { }

	thisEntity:SetContextThink( "OgreTankBossThink", OgreTankBossThink, 1 )
end

function FrendlyHasAgro()
  for i, hSummonedUnit in ipairs( thisEntity.OgreSummonSeers ) do
    if ( IsValidEntity(hSummonedUnit) and hSummonedUnit:IsAlive() and hSummonedUnit.bHasAgro) then
      local hasDamageThreshold = hSummonedUnit:GetMaxHealth() - hSummonedUnit:GetHealth() > thisEntity.BossTier * BOSS_AGRO_FACTOR;
      if hasDamageThreshold then
        return true
      end
		end
  end
  return false
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
    thisEntity.bHasAgro = false
    SpawnAllies()
	end

  local enemies = FindUnitsInRadius(
    thisEntity:GetTeamNumber(),
    thisEntity:GetOrigin(),
    nil,
    thisEntity:GetCurrentVisionRange(),
    DOTA_UNIT_TARGET_TEAM_ENEMY,
    DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES,
    FIND_CLOSEST,
    false )

  local hasDamageThreshold = thisEntity:GetMaxHealth() - thisEntity:GetHealth() > thisEntity.BossTier * BOSS_AGRO_FACTOR;
  local fDistanceToOrigin = ( thisEntity:GetOrigin() - thisEntity.vInitialSpawnPos ):Length2D()

  --Agro
  if (fDistanceToOrigin < 10 and thisEntity.bHasAgro and #enemies == 0) then
    DebugPrint("Ogre Boss Deagro")
    thisEntity.bHasAgro = false
    return 2
  elseif (hasDamageThreshold and #enemies > 0) or FrendlyHasAgro() then
    if not thisEntity.bHasAgro then
      DebugPrint("Ogre Boss Agro")
      thisEntity.bHasAgro = true
    end
  end

  -- Leash
  if not thisEntity.bHasAgro or #enemies==0 or fDistanceToOrigin > BOSS_LEASH_SIZE then
    if fDistanceToOrigin > 10 then
      return RetreatHome()
    end
    return 1
  end

	local nCloseEnemies = 0
  for i = 1, #enemies do
		local enemy = enemies[i]
		if enemy ~= nil then
			local flDist = ( enemy:GetOrigin() - thisEntity:GetOrigin() ):Length2D()
			if flDist < 300 then
				nCloseEnemies = nCloseEnemies + 1
				table.remove( enemies, i )
			end
		end
  end

	if thisEntity.JumpAbility ~= nil and thisEntity.JumpAbility:IsFullyCastable() and nCloseEnemies > 0 then
		return Jump()
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

  table.insert(thisEntity.OgreSummonSeers, ally1)
  table.insert(thisEntity.OgreSummonSeers, ally2)

  --ally2:AddItem(CreateItem("item_heart", ally2, ally2))
  --ally1:AddItem(CreateItem("item_heart", ally1, ally1))
end

function Jump()
	ExecuteOrderFromTable({
		UnitIndex = thisEntity:entindex(),
		OrderType = DOTA_UNIT_ORDER_CAST_NO_TARGET,
		AbilityIndex = thisEntity.JumpAbility:entindex(),
		Queue = false,
	})
  return 3
end

function Smash( enemy )
	if enemy == nil then
		return 0.5
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

  return thisEntity.SmashAbility:GetPlaybackRateOverride()
end

function RetreatHome()
	ExecuteOrderFromTable({
		UnitIndex = thisEntity:entindex(),
		OrderType = DOTA_UNIT_ORDER_MOVE_TO_POSITION,
		Position = thisEntity.vInitialSpawnPos,
		Queue = false,
  })
  return 6
end

