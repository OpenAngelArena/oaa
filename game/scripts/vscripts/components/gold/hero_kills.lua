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
  assist gold = base + (bounty based on dying hero's level) * killerNwRankingFactor[assisting hero's networth rank] * killedNwRankingFactor + comeback bonus
  comeback bonus = (killedNwFactor * killed hero's networth + comebackBase) / number of assisting heroes
  With the comeback bonus only being added if the killing team is behind in networth
]]

local AssistGoldTable = {
    [1] = {
      base = 80,
      comebackBase = 70,
      killedNwFactor = 0.026,
      killedNwRankingFactor = { 1.2, 1.05, 0.9, 0.75, 0.6 },
      killerNwRankingFactor = { 1 }
    },
    [2] = {
      base = 40,
      comebackBase = 70,
      killedNwFactor = 0.026,
      killedNwRankingFactor = { 1.2, 1.05, 0.9, 0.75, 0.6 },
      killerNwRankingFactor = { 0.7, 1.3 }
    },
    [3] = {
      base = 20,
      comebackBase = 70,
      killedNwFactor = 0.026,
      killedNwRankingFactor = { 1.2, 1.05, 0.9, 0.75, 0.6 },
      killerNwRankingFactor = { 0.7, 1, 1.3 }
    },
    [4] = {
      base = 14.5,
      comebackBase = 70,
      killedNwFactor = 0.026,
      killedNwRankingFactor = { 1.2, 1.05, 0.9, 0.75, 0.6 },
      killerNwRankingFactor = { 0.7, 0.9, 1.1, 1.3 }
    },
    [5] = {
      base = 11.5,
      comebackBase = 70,
      killedNwFactor = 0.026,
      killedNwRankingFactor = { 1.2, 1.05, 0.9, 0.75, 0.6 },
      killerNwRankingFactor = { 0.7, 0.85, 1, 1.15, 1.3 }
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
  if not keys.killer or not keys.killed then
    return
  end

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
  if killerPlayerID == -1 or killedPlayerID == -1 then
    -- nope
    return
  end
  local killerHero = PlayerResource:GetSelectedHeroEntity(killerPlayerID)
  local streak = math.min(StreakTable.max, killedHero:GetStreak())
  local streakValue = StreakTable[streak]
  local killedHeroLevel = killedHero:GetLevel()
  local killedHeroLevelFactor = (100 * killedHeroLevel)/14
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

  local baseGold = math.floor((40 + streakValue + (killedHeroLevel * 8)) / distributeCount)

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
  if not killedNetworth then
    killedNetworth = 0
  end
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
      ErrorMessage = "Killed team networth list: " .. killedTeamNWString .. ", killed player ID: " .. killedPlayerID .. ", killed team player IDs: " .. killedPlayerIDsString,
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
    -- assist gold = base + (bounty based on dying hero's level) * killerNwRankingFactor[assisting hero's networth rank] * killedNwRankingFactor + comeback bonus
    local assistGold = parameters.base + 0.9*(killedHeroLevelFactor/#heroes) * parameters.killerNwRankingFactor[math.min(nwRank, #parameters.killerNwRankingFactor)] * parameters.killedNwRankingFactor[math.min(killedNWRanking, #parameters.killedNwRankingFactor)]
    DebugPrint("Base assist gold: (" .. parameters.base .. ' + 0.9*(' .. math.max(1, 6 - #heroes) .. ' * ' .. killedHeroLevelFactor .. ') * ' .. parameters.killerNwRankingFactor[math.min(nwRank, #parameters.killerNwRankingFactor)] .. ' * ' .. parameters.killedNwRankingFactor[math.min(killedNWRanking, #parameters.killedNwRankingFactor)] .. ' = ' .. assistGold)
    local assistComebackGold = 0
    if killedTeamNW > killerTeamNW then
      assistComebackGold = (parameters.killedNwFactor * killedNetworth + parameters.comebackBase)/#heroes
      DebugPrint("Comeback assist gold: (" .. parameters.killedNwFactor .. " * " .. killedNetworth .. " + " .. parameters.comebackBase .. ") / " .. #heroes .. ' = ' .. assistComebackGold)
    end
    assistGold = assistGold + assistComebackGold
    assistGold = math.floor(assistGold)
    DebugPrint("Total assist gold: " .. assistGold)

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
