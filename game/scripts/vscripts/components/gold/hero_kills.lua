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
  if keys.killer:GetTeam() == keys.killed:GetTeam() then
    return
  end
  if keys.killed:IsReincarnating() then
    return
  end
  if keys.killed:GetTeam() == DOTA_TEAM_NEUTRALS or keys.killer:GetTeam() == DOTA_TEAM_NEUTRALS then
    return
  end

  local killerPlayer = keys.killer:GetPlayerOwner()
  local killedPlayer = keys.killed:GetPlayerOwner()
  if not killedPlayer then
    -- the killed thing wasn't a player even though it's definitely a player lololololol ???????
    return
  end

  local killerHero = nil
  local killerHeroID = nil

  if killerPlayer then
    killerHero = killerPlayer:GetAssignedHero()
    killerHeroID = killerHero:GetPlayerOwnerID()
  end

  local killerTeam = keys.killer:GetTeamNumber()
  local killedHero = killedPlayer:GetAssignedHero()
  local killedTeam = killedHero:GetTeamNumber()

  local killedNetworth = killedHero:GetNetworth()
  local streak = math.min(StreakTable.max, killedHero:GetStreak())
  local streakValue = StreakTable[streak]
  local killedHeroLevel = killedHero:GetLevel()
  local baseGold = 110 + streakValue + (killedHeroLevel * 8)

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

  local function sortByNetworth (a, b)
    return a:GetNetworth() > b:GetNetworth()
  end

  table.sort(heroes, sortByNetworth)

  local foundKiller = false
  each(function (hero)
    if not foundKiller and hero:GetPlayerOwnerID() == killerHeroID then
      foundKiller = true
    end
  end, heroes)

  if not foundKiller and killerHero then
    table.insert(heroes, killerHero)
  end

  DebugPrint(#heroes .. ' heroes getting assist gold')

  local parameters = AssistGoldTable[math.min(AssistGoldTable.max, #heroes)]

  local function getHeroNetworth (playerId)
    local hero = PlayerResource:GetSelectedHeroEntity(playerId)
    if not hero then
      return 0
    end
    return hero:GetNetworth()
  end

  -- NW factor is defined as (enemy team net worth / allied team net worth) - 1 and has a minimum of zero and a maximum of 1.
  local entireKilledTeamNW = map(getHeroNetworth, PlayerResource:GetPlayerIDsForTeam(killedTeam))
  entireKilledTeamNW = entireKilledTeamNW:totable()
  table.sort(entireKilledTeamNW)

  local killerTeamNW = reduce(operator.add, 0, map(getHeroNetworth, PlayerResource:GetPlayerIDsForTeam(killerTeam)))
  local killedTeamNW = reduce(operator.add, 0, entireKilledTeamNW)
  local nwFactor = math.min(1, math.max(0, (killedTeamNW / killerTeamNW) - 1))
  -- (Team NW disadvantage / 4000) has a maximum of 1
  local teamNWDisadvantage = math.min(math.max(0, killedTeamNW - killerTeamNW) / 4000, 1)


  local killedNWRanking = false
  local index = #entireKilledTeamNW
  each(function (nw)
    if killedNWRanking == false then
      if nw == killedNetworth then
        killedNWRanking = index
      end
      index = index - 1
    end
  end, entireKilledTeamNW)

  DebugPrint(killedNetworth .. ' hero is in ' .. killedNWRanking .. 'th place of')
  DebugPrintTable(entireKilledTeamNW)

  index = 0
  each(function (hero)
    --[[
      base = 140,
      nwMult = 0.0375,
      advantageMult = 100,
      advantageFactor = 4000,
      nwMultBase = 1.2,
      nwMultMult = 0.1,
      nwRankingFactor = { 1 }
    ]]
    index = index + 1
    -- 5 Heroes: [20 Gold + (1 × dying hero's level) + (0.0225 × dying hero's NW × NW factor) + (25 Gold × team NW disadvantage / 4000)]
    local assistGold = (parameters.base + (math.max(1, 6 - #heroes) * killedHeroLevel) + (parameters.nwMult * killedNetworth * nwFactor) + (parameters.advantageMult * teamNWDisadvantage))
    DebugPrint('(' .. parameters.base .. ' + (' .. math.max(1, 6 - #heroes) .. ' * ' .. killedHeroLevel .. ') + (' .. parameters.nwMult .. ' * ' .. killedNetworth .. ' * ' .. nwFactor .. ') + (' .. parameters.advantageMult .. ' * ' .. teamNWDisadvantage .. '))) = ' .. assistGold)
    -- × [1.2 - 0.1 × (dying hero's NW ranking - 1)] × [NW ranking factor]
    DebugPrint(assistGold .. ' * (' .. parameters.nwMultBase .. ' - ' .. parameters.nwMultMult .. ' * (' .. killedNWRanking .. ' - 1)) * ' .. parameters.nwRankingFactor[math.min(index, #parameters.nwRankingFactor)] .. ' = ...')
    assistGold = assistGold * (parameters.nwMultBase - parameters.nwMultMult * (killedNWRanking - 1)) * parameters.nwRankingFactor[math.min(index, #parameters.nwRankingFactor)]
    DebugPrint(assistGold)

    if hero:GetPlayerOwnerID() == killerHeroID then
      assistGold = assistGold + baseGold
    end

    Gold:ModifyGold(hero, assistGold, true, DOTA_ModifyGold_RoshanKill)
    SendOverheadEventMessage(hero:GetPlayerOwner(), OVERHEAD_ALERT_GOLD, keys.killed, math.floor(assistGold), hero:GetPlayerOwner())

  end, heroes)
end
