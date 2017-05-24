
-- Taken from bb template
if BossSpawner == nil then
  DebugPrint ( 'creating new BossSpawner object' )
  BossSpawner = class({})

  Debug.EnabledModules['boss:spawn'] = false
end

function BossSpawner:Init ()
  Timers:CreateTimer(5, Dynamic_Wrap(BossSpawner, 'SpawnAllBosses'))

  local allGoodPlayers = {}
  local allBadPlayers = {}
  local function addToList (list, id)
    list[id] = true
  end
  each(partial(addToList, allGoodPlayers), PlayerResource:GetPlayerIDsForTeam(DOTA_TEAM_BADGUYS))
  each(partial(addToList, allBadPlayers), PlayerResource:GetPlayerIDsForTeam(DOTA_TEAM_GOODGUYS))

  BossSpawner.goodZone2 = ZoneControl:CreateZone('good_safe_pit_2', {
    mode = ZONE_CONTROL_EXCLUSIVE_OUT,
    margin = 300,
    players = allGoodPlayers
  })
  BossSpawner.goodZone1 = ZoneControl:CreateZone('good_safe_pit_1', {
    mode = ZONE_CONTROL_EXCLUSIVE_OUT,
    margin = 300,
    players = allGoodPlayers
  })

  BossSpawner.badZone2 = ZoneControl:CreateZone('bad_safe_pit_2', {
    mode = ZONE_CONTROL_EXCLUSIVE_OUT,
    margin = 300,
    players = allBadPlayers
  })
  BossSpawner.badZone1 = ZoneControl:CreateZone('bad_safe_pit_1', {
    mode = ZONE_CONTROL_EXCLUSIVE_OUT,
    margin = 300,
    players = allBadPlayers
  })
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
  local bossList = pit:GetIntAttr('type')
  local options = Bosses[bossList]
  local tierIndex = math.min(#options, pit.killCount)
  local bossTier = tierIndex - 1 + startTier
  local bossName = options[tierIndex]
  local isProtected = bossList == 1 and pit.killCount == 1

  DebugPrint('Spawning ' .. bossName .. ' with protection ' .. tostring(isProtected))
  BossSpawner:SpawnBoss(pit, bossName, bossTier, isProtected)
end

function BossSpawner:SpawnBoss (pit, boss, bossTier, isProtected)
  local bossHandle = CreateUnitByName(boss, pit:GetAbsOrigin(), true, nil, nil, DOTA_TEAM_NEUTRALS)

  DebugPrint(pit:GetAbsOrigin().x)
  DebugPrint(pit:GetAbsOrigin().y)

  local team = DOTA_TEAM_GOODGUYS
  if pit:GetAbsOrigin().x > 0 then
    team = DOTA_TEAM_BADGUYS
  end

  if pit:GetAbsOrigin().y > 5000 then
    team = DOTA_TEAM_GOODGUYS
  elseif pit:GetAbsOrigin().y < -5000 then
    team = DOTA_TEAM_BADGUYS
  end

  DebugPrint('Boss natively belongs to ' .. team)

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
    customAgro = bossPrefix ~= 'npc_dota_boss_tier_',
    owner = team,
    isProtected = isProtected
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
