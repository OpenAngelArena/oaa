
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
    local bossTier = bossPit:GetIntAttr('tier')
    local options = Bosses[bossTier]
    local bossName = options[math.random(#options)]

    DebugPrint('Spawning ' .. bossName)
    BossSpawner:SpawnBoss(bossPit, bossName, bossTier)
  end
end

function BossSpawner:SpawnBoss (pit, boss, bossTier)
  local bossHandle = CreateUnitByName(boss, pit:GetAbsOrigin(), true, nil, nil, DOTA_TEAM_NEUTRALS)

  local heart = CreateItem("item_heart", bossHandle, bossHandle)

  bossHandle:AddItem(heart)

  BossAI:Create(bossHandle, {
    tier = bossTier
  })
end
