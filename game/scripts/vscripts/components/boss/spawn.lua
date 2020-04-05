
-- Taken from bb template
if BossSpawner == nil then
  DebugPrint ( 'creating new BossSpawner object' )
  BossSpawner = class({})

  BossSpawner.CoreItems = {
    'item_upgrade_core',
    'item_upgrade_core_2',
    'item_upgrade_core_3',
    'item_upgrade_core_4',
    'item_upgrade_core_4',
    'item_upgrade_core_4'
  }

  Debug.EnabledModules['boss:spawn'] = false
end

function BossSpawner:Init ()
  HudTimer:At(BOSS_RESPAWN_START, Dynamic_Wrap(BossSpawner, 'SpawnAllBosses'))
  ChatCommand:LinkDevCommand("-spawnbosses", Dynamic_Wrap(self, 'SpawnAllBosses'), self)

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

  local bossPits = Entities:FindAllByName('boss_pit')

  for _,bossPit in ipairs(bossPits) do
    bossPit.killCount = 1 -- 1 index because lua is that person from the internet who doesn't look like their pictures
  end

  self.hasKilledTiers = {
    [1] = false,
    [2] = false,
    [3] = false,
    [4] = false,
    [5] = false,
    [6] = true,
    [7] = true,
  }
end

function BossSpawner:GetState ()
  local state = {}
  local bossPits = Entities:FindAllByName('boss_pit')

  for _,bossPit in ipairs(bossPits) do
    state[self:PitID(bossPit)] = bossPit.killCount
  end

  state.hasKilledTiers = self.hasKilledTiers

  return state
end

function BossSpawner:LoadState (state)
  local bossPits = Entities:FindAllByName('boss_pit')

  for _,bossPit in ipairs(bossPits) do
    bossPit.killCount = state[self:PitID(bossPit)]
  end

  self.hasKilledTiers = state.hasKilledTiers

  BossSpawner:SpawnAllBosses()
end

function BossSpawner:PitID (pit)
  local origin = pit:GetAbsOrigin()
  return origin.x .. '/' .. origin.y .. '/' .. origin.z
end

function BossSpawner:SpawnAllBosses ()
  if BossSpawner.bossesHaveSpawned then
    return
  end
  BossSpawner.bossesHaveSpawned = true

  local bossPits = Entities:FindAllByName('boss_pit')

  for _,bossPit in ipairs(bossPits) do
    Timers:CreateTimer(_ / 10, function ()
      BossSpawner:SpawnBossAtPit(bossPit)
    end)
  end
end

function BossSpawner:SpawnBossAtPit (pit)
  local startTier = pit:GetIntAttr('tier')
  local bossList = pit:GetIntAttr('type')
  local options = Bosses[bossList]
  local tierIndex = math.min(#options, pit.killCount)
  local bossTier = tierIndex - 1 + startTier
  local bossName = options[tierIndex]
  if type(bossName) ~= 'string' then
    -- i had the worst luck today and got all simple_1 bosses in all 4 spots 2 games in a row and thought this was broken
    -- so i removed the simple_1 from the list, and sure enough all 4 spots spawned with tier 2 bosses.
    -- then i realized i only removed simple_1 from one of the two lists, reloaded once more and got all random
    -- it was never broken
    -- 1/3 * 1/3 * 1/3 * 1/3 * 1/3 * 1/3 * 1/3 * 1/3 * 1/2 * 1/2 * 1/3 * 1/3 oods
    -- DebugPrint('There are ' .. #bossName .. 'options for this boss')
    bossName = bossName[RandomInt(1, #bossName)]
  end
  local isProtected = false --bossList == 1 and pit.killCount == 1

  DebugPrint('Spawning ' .. bossName .. ' with protection ' .. tostring(isProtected))
  BossSpawner:SpawnBoss(pit, bossName, bossTier, isProtected)
end

function BossSpawner:SpawnBoss (pit, boss, bossTier, isProtected)
  local bossHandle = CreateUnitByName(boss, pit:GetAbsOrigin(), true, nil, nil, DOTA_TEAM_NEUTRALS)
  bossHandle.BossTier = bossTier

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

  --local heart = CreateItem("item_heart", bossHandle, bossHandle)

  --bossHandle:AddItem(heart)

  --Adding cores to the bosses inventory
  local core = CreateItem(BossSpawner.CoreItems[bossTier], bossHandle, bossHandle)

  if core == nil then
    error('Got bad core, tier must have bad value ' .. tostring(bossTier))
  else
    bossHandle:AddItem(core)
  end

  local resistance = bossHandle:FindAbilityByName("boss_resistance")
  if resistance then
    DebugPrint('Leveling up the boss resistance manager')
    resistance:SetLevel(1)
  end

  local bossAI = BossAI:Create(bossHandle, {
    tier = bossTier,
    customAgro = bossPrefix ~= 'npc_dota_boss_tier_' and bossPrefix ~= 'npc_dota_boss_simpl',
    owner = team,
    isProtected = isProtected
  })

  Minimap:SpawnBossIcon(pit, bossTier)

  local newBossTier = math.min(5, bossTier + 1)

  bossAI.onDeath(function ()
    DebugPrint('Boss has died ' .. pit.killCount .. ' times')
    pit.killCount = pit.killCount + 1
    if not self.hasKilledTiers[bossTier] then
      self.hasKilledTiers[bossTier] = true
      PointsManager:IncreaseLimit(KILL_LIMIT_INCREASE)
    end
    Timers:CreateTimer(BOSS_RESPAWN_TIMER, function()
      BossSpawner:SpawnBossAtPit(pit, bossTier)
    end)
  end)
end
