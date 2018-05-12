function Spawn( kv )
	if not IsServer() then
		return
	end

	if thisEntity == nil then
		return
  end
  thisEntity.bForceKill = false

	thisEntity:SetContextThink( "TempleGuardianSpawnerThink", TempleGuardianSpawnerThink, 1 )
end

function TempleGuardianSpawnerThink()
  if not thisEntity.bInitialized then
		thisEntity.vInitialSpawnPos = thisEntity:GetOrigin()
    thisEntity.bInitialized = true
  end

  if thisEntity.bForceKill then
    -- Triggers boss reward
    local hAttackerHero = EntIndexToHScript( thisEntity.KillValues.entindex_attacker )
    thisEntity:Kill(nil, hAttackerHero)
    return -1
  end

  thisEntity.bossHandle1 = CreateUnitByName('npc_dota_creature_temple_guardian_tier5', thisEntity:GetAbsOrigin() +  Vector( 300, 0, 0 ), true, nil, nil, DOTA_TEAM_NEUTRALS)
  thisEntity.bossHandle1.BossTier = thisEntity.BossTier
  thisEntity.bossHandle2 = CreateUnitByName('npc_dota_creature_temple_guardian_tier5', thisEntity:GetAbsOrigin() +  Vector(-300, 0, 0 ), true, nil, nil, DOTA_TEAM_NEUTRALS)
  thisEntity.bossHandle2.BossTier = thisEntity.BossTier

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

  return
end

-- Pedestal death animation
function RemovePedestals()
  -- Ideally we would set the velocity but it does not work on Z axis.
  local offset = 0
  local step = 10

  EmitSoundOnLocationWithCaster(thisEntity.Pedestal1:GetOrigin(), "TempleGuardian.Pedestal.Explosion", thisEntity.Pedestal1)
  local nFXIndex1 = ParticleManager:CreateParticle( "particles/units/heroes/hero_earth_spirit/espirit_geomagneticgrip_pushrocks.vpcf", PATTACH_CUSTOMORIGIN, nil )
  ParticleManager:SetParticleControl( nFXIndex1, 0, thisEntity.Pedestal1:GetOrigin() )

  local nFXIndex2 = ParticleManager:CreateParticle( "particles/units/heroes/hero_earth_spirit/espirit_geomagneticgrip_pushrocks.vpcf", PATTACH_CUSTOMORIGIN, nil )
  ParticleManager:SetParticleControl( nFXIndex2, 0, thisEntity.Pedestal2:GetOrigin() )
  EmitSoundOnLocationWithCaster(thisEntity.Pedestal2:GetOrigin(), "TempleGuardian.Pedestal.Explosion", thisEntity.Pedestal2)

  Timers:CreateTimer("RemovePedestals", {
    useGameTime = false,
    endTime = 0.1,
    callback = function()
      -- print("OFFSET " .. tostring(offset))
      if offset > 480 then
        thisEntity.Pedestal1:ForceKill(false)
        thisEntity.Pedestal2:ForceKill(false)

        ParticleManager:DestroyParticle( nFXIndex1 , false)
        ParticleManager:ReleaseParticleIndex( nFXIndex1 )
        ParticleManager:DestroyParticle( nFXIndex2 , false)
        ParticleManager:ReleaseParticleIndex( nFXIndex2 )
        return
      end
      offset = offset + step
      thisEntity.Pedestal1:SetAbsOrigin(thisEntity.Pedestal1:GetAbsOrigin() - Vector(0,0,step))
      thisEntity.Pedestal2:SetAbsOrigin(thisEntity.Pedestal2:GetAbsOrigin() - Vector(0,0,step))

      return 0.1
    end
  })

  return
end

function OnBossKill(kv)
  if (not IsValidEntity(thisEntity.bossHandle1) or not thisEntity.bossHandle1:IsAlive()) and
     (not IsValidEntity(thisEntity.bossHandle2) or not thisEntity.bossHandle2:IsAlive()) then

      RemovePedestals()

      -- Calling Kill or ForceKill from this handler does not work
      thisEntity.KillValues = kv
      thisEntity.bForceKill = true
	    thisEntity:SetContextThink( "TempleGuardianSpawnerThink", TempleGuardianSpawnerThink, 0.1 )
  end
end
