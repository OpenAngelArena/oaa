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

  local killerHero = keys.killer
  local killedHero = keys.killed
  local killerTeam = killerHero:GetTeamNumber()
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

  local killerPlayerID = killerHero:GetPlayerOwnerID()
  local killedPlayerID = killedHero:GetPlayerOwnerID()
  local killedNetworth = killedHero:GetNetworth()
  local streak = math.min(StreakTable.max, killedHero:GetStreak())
  local streakValue = StreakTable[streak]
  local killedHeroLevel = killedHero:GetLevel()
  local baseGold = math.floor(110 + streakValue + (killedHeroLevel * 8))
  local IsValidTeamPlayerID = partial(PlayerResource.IsValidTeamPlayerID, PlayerResource)

  if IsValidTeamPlayerID(killerPlayerID) then
    -- Grant the base last hit bounty
    Gold:ModifyGold(killerHero, baseGold, true, DOTA_ModifyGold_RoshanKill)
    local killerPlayer = killerHero:GetPlayerOwner()
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

  local killerIsInHeroesTable = iter(heroes)
                                  :map(CallMethod("GetPlayerOwnerID"))
                                  :contains(killerPlayerID)

  if IsValidTeamPlayerID(killerPlayerID) and not killerIsInHeroesTable then
    table.insert(heroes, killerHero)
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

  -- NW factor is defined as (enemy team net worth / allied team net worth) - 1 and has a minimum of zero and a maximum of 1.
  local entireKilledTeamNW = map(getHeroNetworth, PlayerResource:GetPlayerIDsForTeam(killedTeam))
  entireKilledTeamNW = entireKilledTeamNW:totable()
  -- Sort entireKilledTeamNW in descending order
  table.sort(entireKilledTeamNW, op.gt)

  local killerTeamNW = sum(map(getHeroNetworth, PlayerResource:GetPlayerIDsForTeam(killerTeam)))
  local killedTeamNW = sum(entireKilledTeamNW)
  local nwFactor = math.min(1, math.max(0, (killedTeamNW / killerTeamNW) - 1))
  -- (Team NW disadvantage / 4000) has a maximum of 1
  local teamNWDisadvantage = math.min(math.max(0, killedTeamNW - killerTeamNW) / 4000, 1)

  local killedNWRanking = index(killedNetworth, entireKilledTeamNW)

  DebugPrint(killedNetworth .. ' hero is in ' .. killedNWRanking .. 'th place of')
  DebugPrintTable(entireKilledTeamNW)

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

    -- Change the gold value displayed in the kill toast message
    if hero:GetPlayerOwnerID() == killerPlayerID then
      CustomGameEventManager:Send_ServerToAllClients("override_hero_bounty_toast", {killerID = killerPlayerID, killedID = killedPlayerID, goldBounty = baseGold + assistGold})
    end

    Gold:ModifyGold(hero, assistGold, true, DOTA_ModifyGold_RoshanKill)
    local player = hero:GetPlayerOwner()
    if player then
      SendOverheadEventMessage(player, OVERHEAD_ALERT_GOLD, hero, assistGold, player)
    end
  end
end
