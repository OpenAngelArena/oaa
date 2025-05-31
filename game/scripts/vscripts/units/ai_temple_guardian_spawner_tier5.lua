function Spawn( kv )
  if not thisEntity or not IsServer() then
    return
  end

  thisEntity.bForceKill = false

	thisEntity:SetContextThink( "TempleGuardianSpawnerThink", TempleGuardianSpawnerThink, 1 )
end

function TempleGuardianSpawnerThink()
  if GameRules:State_Get() >= DOTA_GAMERULES_STATE_POST_GAME or not IsValidEntity(thisEntity) or not thisEntity:IsAlive() then
    return -1
  end

  if GameRules:IsGamePaused() then
    return 1
  end

  if not thisEntity.bInitialized then
    thisEntity.vInitialSpawnPos = thisEntity:GetOrigin()
    thisEntity.bInitialized = true
  end

  if thisEntity.bForceKill then
    -- Triggers boss reward
    local killer = EntIndexToHScript( thisEntity.KillValues.entindex_attacker )
    if killer:GetTeamNumber() == DOTA_TEAM_NEUTRALS then
      thisEntity:ForceKillOAA(false)
    else
      thisEntity:Kill(nil, killer)
    end
    return -1
  end

  thisEntity.bossHandle1 = CreateUnitByName('npc_dota_creature_temple_guardian_tier5', thisEntity:GetAbsOrigin() +  Vector( 300, 0, 0 ), true, nil, nil, DOTA_TEAM_NEUTRALS)
  thisEntity.bossHandle1.BossTier = thisEntity.BossTier or 5
  thisEntity.bossHandle2 = CreateUnitByName('npc_dota_creature_temple_guardian_tier5', thisEntity:GetAbsOrigin() +  Vector(-300, 0, 0 ), true, nil, nil, DOTA_TEAM_NEUTRALS)
  thisEntity.bossHandle2.BossTier = thisEntity.BossTier or 5

  thisEntity.bossHandle1:SetHullRadius( 150 )
  thisEntity.bossHandle2:SetHullRadius( 150 )

  thisEntity.bossHandle1.hBrother = thisEntity.bossHandle2
  thisEntity.bossHandle2.hBrother = thisEntity.bossHandle1

  thisEntity.bossHandle1:OnDeath(OnBossKill)
  thisEntity.bossHandle2:OnDeath(OnBossKill)

  for i = DOTA_ITEM_SLOT_1, DOTA_ITEM_SLOT_6 do
    local item = thisEntity:GetItemInSlot(i)
    if item ~= nil then
      thisEntity.bossHandle1:AddItemByName( item:GetName() )
      thisEntity.bossHandle2:AddItemByName( item:GetName() )
    end
  end

  SpawnPedestals()

  return -1
end

function SpawnPedestals()
  thisEntity.Pedestal1 = CreateUnitByName('npc_dota_creature_pedestal', thisEntity:GetAbsOrigin() +  Vector( 300, 300, 0 ), true, nil, nil, DOTA_TEAM_NEUTRALS)
  -- For some reason add z values on CreateUnitByName does not work
  local pos = thisEntity.Pedestal1:GetOrigin();
  pos = pos + Vector(0, 0, 135)
  thisEntity.Pedestal1:SetAbsOrigin(pos)
  thisEntity.Pedestal1:SetAngles( 0, 240, 0 )
  thisEntity.Pedestal1:SetHullRadius( 240 )

  thisEntity.Pedestal2 = CreateUnitByName('npc_dota_creature_pedestal', thisEntity:GetAbsOrigin() +  Vector( -300, 300, 0 ), true, nil, nil, DOTA_TEAM_NEUTRALS)
  -- For some reason add z values on CreateUnitByName does not work
  pos = thisEntity.Pedestal2:GetOrigin();
  pos = pos + Vector(0, 0, 135)
  thisEntity.Pedestal2:SetAbsOrigin(pos)
  thisEntity.Pedestal2:SetAngles( 0, 240, 0 )
  thisEntity.Pedestal2:SetHullRadius( 240 )
end

-- Pedestal death animation
function RemovePedestals(p1, p2, killer_index)
  -- Ideally we would set the velocity but it does not work on Z axis.
  local offset = 0
  local step = 10

  local nFXIndex1
  if p1 and not p1:IsNull() then
    EmitSoundOnLocationWithCaster(p1:GetOrigin(), "TempleGuardian.Pedestal.Explosion", p1)
    nFXIndex1 = ParticleManager:CreateParticle( "particles/units/heroes/hero_earth_spirit/espirit_geomagneticgrip_pushrocks.vpcf", PATTACH_CUSTOMORIGIN, nil )
    ParticleManager:SetParticleControl( nFXIndex1, 0, p1:GetOrigin() )
  end

  local nFXIndex2
  if p2 and not p2:IsNull() then
    nFXIndex2 = ParticleManager:CreateParticle( "particles/units/heroes/hero_earth_spirit/espirit_geomagneticgrip_pushrocks.vpcf", PATTACH_CUSTOMORIGIN, nil )
    ParticleManager:SetParticleControl( nFXIndex2, 0, p2:GetOrigin() )
    --EmitSoundOnLocationWithCaster(p2:GetOrigin(), "TempleGuardian.Pedestal.Explosion", p2)
  end

  Timers:CreateTimer(0.1, function()
    if offset > 480 then
      local killer = EntIndexToHScript(killer_index)

      if p1 and not p1:IsNull() then
        p1:AddNoDraw()
        if killer:GetTeamNumber() == DOTA_TEAM_NEUTRALS then
          p1:ForceKillOAA(false)
        else
          p1:Kill(nil, killer)
        end
      end
      if p2 and not p2:IsNull() then
        p2:AddNoDraw()
        if killer:GetTeamNumber() == DOTA_TEAM_NEUTRALS then
          p2:ForceKillOAA(false)
        else
          p2:Kill(nil, killer)
        end
      end

      if nFXIndex1 then
        ParticleManager:DestroyParticle( nFXIndex1 , false)
        ParticleManager:ReleaseParticleIndex( nFXIndex1 )
      end
      if nFXIndex2 then
        ParticleManager:DestroyParticle( nFXIndex2 , false)
        ParticleManager:ReleaseParticleIndex( nFXIndex2 )
      end
      return -- stops the timer
    end

    offset = offset + step
    if p1 and not p1:IsNull() then
      p1:SetAbsOrigin(p1:GetAbsOrigin() - Vector(0,0,step))
    end
    if p2 and not p2:IsNull() then
      p2:SetAbsOrigin(p2:GetAbsOrigin() - Vector(0,0,step))
    end

    return 0.1 -- repeat the timer
  end)
end

function OnBossKill(kv)
  if (not IsValidEntity(thisEntity.bossHandle1) or not thisEntity.bossHandle1:IsAlive()) and
     (not IsValidEntity(thisEntity.bossHandle2) or not thisEntity.bossHandle2:IsAlive()) then

      RemovePedestals(thisEntity.Pedestal1, thisEntity.Pedestal2, kv.entindex_attacker)

      -- Calling Kill or ForceKill from this handler does not work
      thisEntity.KillValues = kv
      thisEntity.bForceKill = true
	    thisEntity:SetContextThink( "TempleGuardianSpawnerThink", TempleGuardianSpawnerThink, 0.1 )
  end
end
