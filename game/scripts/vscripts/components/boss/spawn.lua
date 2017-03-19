
-- Taken from bb template
if BossSpawner == nil then
  DebugPrint ( 'creating new BossSpawner object' )
  BossSpawner = class({})

  Debug.EnabledModules['boss:*'] = true
end

function BossSpawner:Init ()
  Timers:CreateTimer(5, Dynamic_Wrap(BossSpawner, 'SpawnAllBosses'))
end

function BossSpawner:SpawnAllBosses ()
  if BossSpawner.bossesHaveSpawned then
    return
  end
  BossSpawner.bossesHaveSpawned = true

  local bossPits = Entities:FindAllByName('boss_pit')

  for _,bossPit in ipairs(bossPits) do
    BossSpawner:SpawnBossAtPit(bossPit)
  end
end

function BossSpawner:SpawnBossAtPit (pit, tieroverride)
  local bossTier = tieroverride or pit:GetIntAttr('tier')
  local options = Bosses[bossTier]
  local bossName = options[math.random(#options)]

  DebugPrint('Spawning ' .. bossName)
  BossSpawner:SpawnBoss(pit, bossName, bossTier)
end

function BossSpawner:SpawnBoss (pit, boss, bossTier)
  local bossHandle = CreateUnitByName(boss, pit:GetAbsOrigin(), true, nil, nil, DOTA_TEAM_NEUTRALS)

  if bossHandle == nil then
    return
  end

  local heart = CreateItem("item_heart", bossHandle, bossHandle)

  bossHandle:AddItem(heart)

  local bossAI = BossAI:Create(bossHandle, {
    tier = bossTier
  })

  local newBossTier = math.max(6, bossTier + 1)

  bossAI.onDeath(function ()
    Timers:CreateTimer(60, function()
      BossSpawner:SpawnBossAtPit(pit, newBossTier)
    end)
  end)
end
