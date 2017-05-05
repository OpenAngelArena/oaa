
-- Taken from bb template
if BossSpawner == nil then
  DebugPrint ( 'creating new BossSpawner object' )
  BossSpawner = class({})

  Debug.EnabledModules['boss:spawn'] = false
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
    bossPit.killCount = 1 -- 1 index because lua is that person from the internet who doesn't look like their pictures
    BossSpawner:SpawnBossAtPit(bossPit)
  end
end

function BossSpawner:SpawnBossAtPit (pit)
  local startTier = pit:GetIntAttr('tier')
  local options = Bosses[startTier]
  local tierIndex = math.min(#options, pit.killCount)
  local bossTier = tierIndex - 1 + startTier
  local bossName = options[tierIndex]

  DebugPrint('Spawning ' .. bossName)
  BossSpawner:SpawnBoss(pit, bossName, bossTier)
end

function BossSpawner:SpawnBoss (pit, boss, bossTier)
  local bossHandle = CreateUnitByName(boss, pit:GetAbsOrigin(), true, nil, nil, DOTA_TEAM_NEUTRALS)

  local bossPrefix = string.sub(boss, 0, 19)
  DebugPrint('boss name ' .. bossPrefix)

  if bossHandle == nil then
    return
  end

  local heart = CreateItem("item_heart", bossHandle, bossHandle)

  bossHandle:AddItem(heart)

  local resistance = bossHandle:FindAbilityByName("boss_resistance")
  if resistance then
    DebugPrint('Leveling up the boss resistance manager')
    resistance:SetLevel(1)
  end

  local bossAI = BossAI:Create(bossHandle, {
    tier = bossTier,
    customAgro = bossPrefix ~= 'npc_dota_boss_tier_'
  })

  local newBossTier = math.min(6, bossTier + 1)

  bossAI.onDeath(function ()
    DebugPrint('Boss has died ' .. pit.killCount .. ' times')
    pit.killCount = pit.killCount + 1
    Timers:CreateTimer(60, function()
      BossSpawner:SpawnBossAtPit(pit, bossTier)
    end)
  end)
end
