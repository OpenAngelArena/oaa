-- Taken from bb template
if HeroKillGold == nil then
  DebugPrint ( 'Creating new HeroKillGold object.' )
  HeroKillGold = class({})
  Debug.EnabledModules['gold:hero_kills'] = false
end

function HeroKillGold:Init()
  GameEvents:OnHeroKilled(partial(self.HeroDeathHandler, self))
  FilterManager:AddFilter(FilterManager.ModifyGold, self, Dynamic_Wrap(HeroKillGold, "GoldFilter"))
end

local StreakTable = {
  [0] = 0,
  [1] = 0,
  [2] = 0,
  [3] = 60,
  [4] = 120,
  [5] = 180,
  [6] = 240,
  [7] = 300,
  [8] = 360,
  [9] = 420,
  [10] = 480,

  max = 10
}

--[[
The following parameters are use in this way:
[base + (1 × dying hero's level) + (0.0225 × dying hero's NW × newMult) + (advantageMult × team NW disadvantage / advantageFactor)] × [1.2 - 0.1 × (dying hero's NW ranking - 1)] × nwRankingFactor[heroNWRank]
]]

local AssistGoldTable = {
    [1] = {
      base = 140,
      nwMult = 0.0375,
      advantageMult = 100,
      advantageFactor = 4000,
      nwMultBase = 1.2,
      nwMultMult = 0.1,
      nwRankingFactor = { 1 }
    },
    [2] = {
      base = 70,
      nwMult = 0.0375,
      advantageMult = 75,
      advantageFactor = 4000,
      nwMultBase = 1.2,
      nwMultMult = 0.1,
      nwRankingFactor = { 0.75, 1.25 }
    },
    [3] = {
      base = 35,
      nwMult = 0.0375,
      advantageMult = 50,
      advantageFactor = 4000,
      nwMultBase = 1.2,
      nwMultMult = 0.1,
      nwRankingFactor = { 0.75, 1, 1.25 }
    },
    [4] = {
      base = 25,
      nwMult = 0.03,
      advantageMult = 35,
      advantageFactor = 4000,
      nwMultBase = 1.2,
      nwMultMult = 0.1,
      nwRankingFactor = { 0.75, 0.75, 1.25, 1.25 }
    },
    [5] = {
      base = 20,
      nwMult = 0.0225,
      advantageMult = 35,
      advantageFactor = 4000,
      nwMultBase = 1.2,
      nwMultMult = 0.1,
      nwRankingFactor = { 0.75, 0.75, 1, 1.25, 1.25 }
    },
    max = 5
  }

function HeroKillGold:GoldFilter (keys)
  if keys.reason_const == DOTA_ModifyGold_HeroKill then
    return false
  end
  return true
end

function HeroKillGold:HeroDeathHandler (keys)
  -- points code for reference
  -- if keys.killer:GetTeam() ~= keys.killed:GetTeam() and not keys.killed:IsReincarnating() and keys.killed:GetTeam() ~= DOTA_TEAM_NEUTRALS then
  --   self:AddPoints(keys.killer:GetTeam())
  -- end

  local killerEntity = keys.killer
  local killedHero = keys.killed
  -- killer is sometimes nil for some reason
  if not killerEntity then
    local killedHeroName
    if killedHero then
      killedHeroName = killedHero:GetName()
    else
      killedHeroName = "Killed entity also nil ??????"
    end
    D2CustomLogging:sendPayloadForTracking(D2CustomLogging.LOG_LEVEL_INFO, "HERO DEATH EVENT FIRED WITH NIL KILLER", {
      ErrorMessage = killedHeroName,
      ErrorTime = GetSystemDate() .. " " .. GetSystemTime(),
      GameVersion = GAME_VERSION,
      DedicatedServers = (IsDedicatedServer() and 1) or 0,
      MatchID = tostring(GameRules:GetMatchID())
    })

    return
  end
  local killerTeam = killerEntity:GetTeamNumber()
  local killedTeam = killedHero:GetTeamNumber()
  if killerTeam == killedTeam then
    return
  end
  if killedHero:IsReincarnating() then
    return
  end
  if killerTeam == DOTA_TEAM_NEUTRALS or killedTeam == DOTA_TEAM_NEUTRALS then
    return
  end

  local killerPlayerID = killerEntity:GetPlayerOwnerID()
  local killedPlayerID = killedHero:GetPlayerOwnerID()
  local killerHero = PlayerResource:GetSelectedHeroEntity(killerPlayerID)
  local streak = math.min(StreakTable.max, killedHero:GetStreak())
  local streakValue = StreakTable[streak]
  local killedHeroLevel = killedHero:GetLevel()
  local numAttackers = killedHero:GetNumAttackers()
  local rewardPlayerIDs = iter({killerPlayerID}) -- The IDs of the players that will get a piece of the base gold bounty
  local rewardHeroes = iter({killerHero})
  local distributeCount = 1

  -- Handle non-player kills (usually the fountain in OAA's case)
  if not PlayerResource:IsValidTeamPlayerID(killerPlayerID) then
    if numAttackers == 0 then
      -- Distribute gold to all heroes on the killer team
      rewardPlayerIDs = PlayerResource:GetPlayerIDsForTeam(killerTeam)
      distributeCount = math.max(1, length(rewardPlayerIDs))
    elseif numAttackers == 1 then
      -- Give gold to single hero
      rewardPlayerIDs = iter({killedHero:GetAttacker(0)})
    else
      -- Distribute gold to heroes who assisted in kill
      rewardPlayerIDs = range(0, numAttackers - 1)
                          :map(partial(killedHero.GetAttacker, killedHero))
      distributeCount = numAttackers
    end
    rewardHeroes = map(partial(PlayerResource.GetSelectedHeroEntity, PlayerResource), rewardPlayerIDs)
  end

  local baseGold = math.floor((110 + streakValue + (killedHeroLevel * 8)) / distributeCount)

  -- Grant the base last hit bounty
  for _, hero in rewardHeroes:unwrap() do
    Gold:ModifyGold(hero, baseGold, true, DOTA_ModifyGold_RoshanKill)
    local killerPlayer = hero:GetPlayerOwner()
    if killerPlayer then
      SendOverheadEventMessage(killerPlayer, OVERHEAD_ALERT_GOLD, killedHero, baseGold, killerPlayer)
    end
  end

  local heroes = FindHeroesInRadius(
    killerTeam,
    killedHero:GetAbsOrigin(),
    nil,
    1300,
    DOTA_UNIT_TARGET_TEAM_FRIENDLY,
    DOTA_UNIT_TARGET_ALL,
    DOTA_UNIT_TARGET_FLAG_INVULNERABLE,
    FIND_ANY_ORDER,
    false
  )

  -- When last hit by a hero, that hero should always receive assist gold, regardless of distance
  if PlayerResource:IsValidTeamPlayerID(killerPlayerID) then
    local killerIsInHeroesTable = iter(heroes)
                                    :map(CallMethod("GetPlayerOwnerID"))
                                    :contains(killerPlayerID)

    if not killerIsInHeroesTable then
      table.insert(heroes, killerHero)
    end
  end

  local function sortByNetworth (a, b)
    return a:GetNetworth() > b:GetNetworth()
  end

  table.sort(heroes, sortByNetworth)

  DebugPrint(#heroes .. ' heroes getting assist gold')

  local parameters = AssistGoldTable[math.min(AssistGoldTable.max, #heroes)]

  local function getHeroNetworth (playerId)
    local hero = PlayerResource:GetSelectedHeroEntity(playerId)
    if not hero then
      return 0
    end
    return hero:GetNetworth()
  end

  local killedPlayerIDs = PlayerResource:GetPlayerIDsForTeam(killedTeam)
  local entireKilledTeamNW = map(getHeroNetworth, killedPlayerIDs)
  entireKilledTeamNW = entireKilledTeamNW:totable()
  -- Get the killed hero's networth from entireKilledTeamNW
  local killedNetworth = entireKilledTeamNW[index(killedPlayerID, killedPlayerIDs)]
  -- Sort entireKilledTeamNW in descending order
  table.sort(entireKilledTeamNW, op.gt)

  local killerTeamNW = sum(map(getHeroNetworth, PlayerResource:GetPlayerIDsForTeam(killerTeam)))
  local killedTeamNW = sum(entireKilledTeamNW)
  -- NW factor is defined as (enemy team net worth / allied team net worth) - 1 and has a minimum of zero and a maximum of 1.
  local nwFactor = math.min(1, math.max(0, (killedTeamNW / killerTeamNW) - 1))
  -- (Team NW disadvantage / 4000) has a maximum of 1
  local teamNWDisadvantage = math.min(math.max(0, killedTeamNW - killerTeamNW) / 4000, 1)

  local killedNWRanking = index(killedNetworth, entireKilledTeamNW)

  local function catWithComma(string1, string2)
    return string1 .. ", " .. string2
  end

  -- - don't know why this is nil sometimes but it's breaking things
  if not killedNWRanking then
    local killedTeamNWString = reduce(catWithComma, head(entireKilledTeamNW), tail(entireKilledTeamNW))
    local killedPlayerIDsString = reduce(catWithComma, head(killedPlayerIDs), tail(killedPlayerIDs))
    killedTeamNWString = "[" .. killedTeamNWString .. "]"
    D2CustomLogging:sendPayloadForTracking(D2CustomLogging.LOG_LEVEL_INFO, "COULD NOT FIND KILLED HERO NW", {
      ErrorMessage = "Killed team networth list: " .. killedTeamNWString ", killed player ID: " .. killedPlayerID ", killed team player IDs: " .. killedPlayerIDsString,
      ErrorTime = GetSystemDate() .. " " .. GetSystemTime(),
      GameVersion = GAME_VERSION,
      DedicatedServers = (IsDedicatedServer() and 1) or 0,
      MatchID = tostring(GameRules:GetMatchID())
    })

    killedNWRanking = #entireKilledTeamNW
  end

  DebugPrint(killedNetworth .. ' hero is in ' .. killedNWRanking .. 'th place of')
  DebugPrintTable(entireKilledTeamNW)

  -- Modify the kill toast message to display properly for non-player last hits
  if not PlayerResource:IsValidTeamPlayerID(killerPlayerID) then
    CustomGameEventManager:Send_ServerToAllClients(
      "override_hero_bounty_toast",
      {
        rewardIDs = rewardPlayerIDs:totable(),
        killedID = killedPlayerID,
        goldBounty = baseGold,
        displayHeroes = numAttackers > 0,
        rewardTeam = killerTeam,
      })
  end

  for nwRank, hero in ipairs(heroes) do
    --[[
      base = 140,
      nwMult = 0.0375,
      advantageMult = 100,
      advantageFactor = 4000,
      nwMultBase = 1.2,
      nwMultMult = 0.1,
      nwRankingFactor = { 1 }
    ]]
    -- 5 Heroes: [20 Gold + (1 × dying hero's level) + (0.0225 × dying hero's NW × NW factor) + (25 Gold × team NW disadvantage / 4000)]
    local assistGold = (parameters.base + (math.max(1, 6 - #heroes) * killedHeroLevel) + (parameters.nwMult * killedNetworth * nwFactor) + (parameters.advantageMult * teamNWDisadvantage))
    DebugPrint('(' .. parameters.base .. ' + (' .. math.max(1, 6 - #heroes) .. ' * ' .. killedHeroLevel .. ') + (' .. parameters.nwMult .. ' * ' .. killedNetworth .. ' * ' .. nwFactor .. ') + (' .. parameters.advantageMult .. ' * ' .. teamNWDisadvantage .. '))) = ' .. assistGold)
    -- × [1.2 - 0.1 × (dying hero's NW ranking - 1)] × [NW ranking factor]
    DebugPrint(assistGold .. ' * (' .. parameters.nwMultBase .. ' - ' .. parameters.nwMultMult .. ' * (' .. killedNWRanking .. ' - 1)) * ' .. parameters.nwRankingFactor[math.min(nwRank, #parameters.nwRankingFactor)] .. ' = ...')
    assistGold = assistGold * (parameters.nwMultBase - parameters.nwMultMult * (killedNWRanking - 1)) * parameters.nwRankingFactor[math.min(nwRank, #parameters.nwRankingFactor)]
    assistGold = math.floor(assistGold)
    DebugPrint(assistGold)

    -- Modify gold displayed in kill toast message for player last hits
    if hero:GetPlayerOwnerID() == killerPlayerID then
      CustomGameEventManager:Send_ServerToAllClients(
        "override_hero_bounty_toast",
        {
          rewardIDs = rewardPlayerIDs:totable(),
          killedID = killedPlayerID,
          goldBounty = baseGold + assistGold,
          displayHeroes = numAttackers > 0,
          rewardTeam = killerTeam,
        })
    end

    Gold:ModifyGold(hero, assistGold, true, DOTA_ModifyGold_RoshanKill)
    local player = hero:GetPlayerOwner()
    if player then
      SendOverheadEventMessage(player, OVERHEAD_ALERT_GOLD, hero, assistGold, player)
    end
  end
end
