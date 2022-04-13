function Spawn( entityKeyValues )
	if not IsServer() then
		return
	end

	if thisEntity == nil then
		return
	end

	thisEntity.SmashAbility = thisEntity:FindAbilityByName( "ogre_tank_boss_melee_smash_tier5" )
	thisEntity.JumpAbility = thisEntity:FindAbilityByName( "ogre_tank_boss_jump_smash_tier5" )
	thisEntity.OgreSummonSeers = { }

	thisEntity:SetContextThink( "OgreTankBossThink", OgreTankBossThink, 1 )
end

function FrendlyHasAgro()
  for i, hSummonedUnit in pairs( thisEntity.OgreSummonSeers ) do
    if IsValidEntity(hSummonedUnit) and hSummonedUnit:IsAlive() and hSummonedUnit.bHasAgro then
      local hasDamageThreshold = hSummonedUnit:GetHealth() / hSummonedUnit:GetMaxHealth() < 99/100
      if hasDamageThreshold then
        return true
      end
		end
  end
  return false
end

function OgreTankBossThink()
	if GameRules:State_Get() >= DOTA_GAMERULES_STATE_POST_GAME or not IsValidEntity(thisEntity) or not thisEntity:IsAlive() then
		return -1
	end

	if GameRules:IsGamePaused() then
		return 1
	end

  if not thisEntity.bInitialized then
    thisEntity.vInitialSpawnPos = thisEntity:GetOrigin()
    thisEntity.bHasAgro = false
    thisEntity.BossTier = thisEntity.BossTier or 5
    SpawnAllies()
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
    thisEntity.vInitialSpawnPos,
    nil,
    BOSS_LEASH_SIZE,
    DOTA_UNIT_TARGET_TEAM_ENEMY,
    bit.bor(DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_BASIC),
    DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES,
    FIND_CLOSEST,
    false
  )

  local hasDamageThreshold = thisEntity:GetHealth() / thisEntity:GetMaxHealth() < 99/100
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
  if not thisEntity.bHasAgro or #enemies == 0 or fDistanceToOrigin > BOSS_LEASH_SIZE then
    if fDistanceToOrigin > 10 then
      return RetreatHome()
    end
    return 1
  end

	local closeRadius = 400
  if thisEntity.JumpAbility then
    closeRadius = thisEntity.JumpAbility:GetSpecialValueFor("impact_radius")
  end
  local nCloseEnemies = 0
  for i, enemy in pairs(enemies) do
    if enemy and not enemy:IsNull() then
      local flDist = ( enemy:GetOrigin() - thisEntity:GetOrigin() ):Length2D()
      if flDist <= closeRadius and IsValidTarget(enemy) then
        nCloseEnemies = nCloseEnemies + 1
        enemies[i] = nil
      end
    end
  end

  if thisEntity.JumpAbility and thisEntity.JumpAbility:IsFullyCastable() and nCloseEnemies > 0 then
    return Jump()
  end

  local smashTarget = FindValidTarget(enemies)
  if thisEntity.SmashAbility and thisEntity.SmashAbility:IsFullyCastable() and smashTarget then
    return Smash(smashTarget)
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
  local ally1 = CreateUnitByName("npc_dota_creature_ogre_seer_tier5", posTopLeft, true, thisEntity, thisEntity:GetOwner(), thisEntity:GetTeam())
  local ally2 = CreateUnitByName("npc_dota_creature_ogre_seer_tier5", posTopRight, true, thisEntity, thisEntity:GetOwner(), thisEntity:GetTeam())

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

	if not thisEntity:HasModifier( "modifier_provide_vision" ) then
		--print( "If player can't see me, provide brief vision to his team as I start my Smash" )
		thisEntity:AddNewModifier( enemy, nil, "modifier_provide_vision", { duration = 1.5 } )
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

