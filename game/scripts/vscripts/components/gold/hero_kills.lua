-- Taken from bb template
if HeroKillGold == nil then
  DebugPrint ( 'Creating new HeroKillGold object.' )
  HeroKillGold = class({})
  Debug.EnabledModules['gold:hero_kills'] = false
end

function HeroKillGold:Init()
  self.moduleName = "Hero Kill Gold"
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
      killedHeroName = "also nil ??????"
    end
    print("HeroKillGold: Killer is nil and killed hero is: "..killedHeroName)
    return
  end

  -- Every entity has GetTeamNumber
  local killerTeam = killerEntity:GetTeamNumber()
  local killedTeam = killedHero:GetTeamNumber()

  if killerTeam == killedTeam then
    -- Hero is denied
    return
  end

  if killedHero:IsClone() then
    killedHero = killedHero:GetCloneSource()
  end

  if killedHero:IsReincarnating() or killedHero:IsTempestDouble() then
    return
  end

  if killerTeam == DOTA_TEAM_NEUTRALS or killedTeam == DOTA_TEAM_NEUTRALS then
    return
  end

  -- playerID is -1 for the fountains, buildings, bottle statues, dummy units etc.
  -- GetPlayerOwnerID will return -1 for those kind of stuff
  local killerPlayerID = killerEntity:GetPlayerOwnerID()
  local killedPlayerID = killedHero:GetPlayerOwnerID()

  if killedPlayerID == -1 then
    return
  end

  -- Variables related to the killed hero
  local streak = math.min(StreakTable.max, killedHero:GetStreak())
  local streakValue = StreakTable[streak]
  local killedHeroLevel = killedHero:GetLevel()
  local killedHeroLevelFactor = (100 * killedHeroLevel)/14
  local numAttackers = killedHero:GetNumAttackers()

  local rewardPlayerIDs -- The IDs of the players that will get a piece of the base gold bounty if the killer is not a player
  local rewardHeroes -- The heroes that will get a piece of the base gold bounty or full bounty
  local distributeCount = 1

  -- Heroes around the killed hero
  local heroes = FindHeroesInRadius(
    killerTeam,
    killedHero:GetAbsOrigin(),
    nil,
    HERO_KILL_GOLD_RADIUS,
    DOTA_UNIT_TARGET_TEAM_FRIENDLY,
    DOTA_UNIT_TARGET_HERO,
    bit.bor(DOTA_UNIT_TARGET_FLAG_NOT_ILLUSIONS, DOTA_UNIT_TARGET_FLAG_INVULNERABLE, DOTA_UNIT_TARGET_FLAG_OUT_OF_WORLD),
    FIND_ANY_ORDER,
    false
  )

  -- Handle non-player kills (when killerPlayerID is -1)
  -- in OAA those are: fountains, buildings, bottle statues, dummy units etc.)
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
  else
    local killerHero = PlayerResource:GetSelectedHeroEntity(killerPlayerID)

    -- When last hit by a hero, that hero should always receive assist gold, regardless of distance
    local killerIsInHeroesTable = iter(heroes)
                                    :map(CallMethod("GetPlayerOwnerID"))
                                    :contains(killerPlayerID)
    if not killerIsInHeroesTable then
      table.insert(heroes, killerHero)
    end

    rewardHeroes = iter({killerHero})
  end

  local baseGold = math.floor((40 + streakValue + (killedHeroLevel * 8)) / distributeCount)

  -- Grant the base last hit bounty
  -- Player that killed the hero gets the full bounty; non-player kills split the bounty between attackers;
  if rewardHeroes then
    for _, hero in rewardHeroes:unwrap() do
      -- Check for Gold spark
      local spark = hero:FindModifierByName("modifier_spark_gold")
      local specific_base_gold = baseGold
      if spark then
        specific_base_gold = math.floor(baseGold + baseGold * spark.hero_kill_bonus_gold)
      end

      Gold:ModifyGold(hero, specific_base_gold, true, DOTA_ModifyGold_RoshanKill)

      DebugPrint("Base gold bounty that "..hero:GetUnitName().." gained is: "..specific_base_gold)

      local killerPlayer = hero:GetPlayerOwner()
      if killerPlayer then
        SendOverheadEventMessage(killerPlayer, OVERHEAD_ALERT_GOLD, killedHero, specific_base_gold, killerPlayer)
      end
    end
  end

  local function sortByNetworth (a, b)
    return a:GetNetworth() > b:GetNetworth()
  end

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
  --local nwFactor = math.min(1, math.max(0, (killedTeamNW / killerTeamNW) - 1))
  -- (Team NW disadvantage / 4000) has a maximum of 1
  --local teamNWDisadvantage = math.min(math.max(0, killedTeamNW - killerTeamNW) / 4000, 1)

  local killedNWRanking = index(killedNetworth, entireKilledTeamNW)

  -- don't know why this is nil sometimes but it's breaking things
  if not killedNWRanking then
    --local function catWithComma(string1, string2)
      --return string1 .. ", " .. string2
    --end
    --local killedTeamNWString = reduce(catWithComma, head(entireKilledTeamNW), tail(entireKilledTeamNW))
    --local killedPlayerIDsString = reduce(catWithComma, head(killedPlayerIDs), tail(killedPlayerIDs))
    --killedTeamNWString = "[" .. killedTeamNWString .. "]"
    killedNWRanking = #entireKilledTeamNW
  end

  DebugPrint('Killed hero networth is: '..killedNetworth .. '. This hero is in ' .. killedNWRanking .. 'th place in the enemy networth table: ')
  DebugPrintTable(entireKilledTeamNW)

  -- Modify the kill toast message for non-player kills (assist gold is not shown for non-player kills)
  -- rewardPlayerIDs is nil for player kills
  if rewardPlayerIDs then
    DebugPrint("Overriding kill toast message for non-player kills")
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

  local assist_table = {}
  local assist_count = 1
  if rewardPlayerIDs then
    -- Assist gold when the killer is not a player
    assist_table = rewardHeroes:totable()
    assist_count = distributeCount
  else
    -- Assist gold when the killer belongs to a player
    assist_table = heroes
    assist_count = #heroes
  end

  table.sort(assist_table, sortByNetworth)

  DebugPrint(assist_count .. ' heroes getting assist gold')

  local parameters = AssistGoldTable[math.min(AssistGoldTable.max, assist_count)]

  -- Split assist gold (ipairs is used instead of pairs because order matters)
  for nwRank, hero in ipairs(assist_table) do
    if hero then
      -- assist gold = base + (bounty based on dying hero's level) * killerNwRankingFactor[assisting hero's networth rank] * killedNwRankingFactor + comeback bonus
      local assistGold = parameters.base + 0.9*(killedHeroLevelFactor/assist_count) * parameters.killerNwRankingFactor[math.min(nwRank, #parameters.killerNwRankingFactor)] * parameters.killedNwRankingFactor[math.min(killedNWRanking, #parameters.killedNwRankingFactor)]
      DebugPrint("Base assist gold: (" .. parameters.base .. ' + 0.9*(' .. math.max(1, 6 - assist_count) .. ' * ' .. killedHeroLevelFactor .. ') * ' .. parameters.killerNwRankingFactor[math.min(nwRank, #parameters.killerNwRankingFactor)] .. ' * ' .. parameters.killedNwRankingFactor[math.min(killedNWRanking, #parameters.killedNwRankingFactor)] .. ' = ' .. assistGold)
      local assistComebackGold = 0
      if killedTeamNW > killerTeamNW then
        assistComebackGold = (parameters.killedNwFactor * killedNetworth + parameters.comebackBase)/assist_count
        DebugPrint("Comeback assist gold: (" .. parameters.killedNwFactor .. " * " .. killedNetworth .. " + " .. parameters.comebackBase .. ") / " .. assist_count .. ' = ' .. assistComebackGold)
      end
      assistGold = assistGold + assistComebackGold
      assistGold = math.floor(assistGold)
      DebugPrint("Total assist gold for "..hero:GetUnitName().." is: "..assistGold)

      -- Modify gold displayed in kill toast message for player last hits
      if hero:GetPlayerOwnerID() == killerPlayerID then
        DebugPrint("Overriding kill toast message for the player kill")
        CustomGameEventManager:Send_ServerToAllClients(
          "override_hero_bounty_toast",
          {
            rewardIDs = {killerPlayerID},
            killedID = killedPlayerID,
            goldBounty = baseGold + assistGold,
            displayHeroes = true,
            rewardTeam = killerTeam,
          })
      end

      -- Check for Gold spark
      local spark = hero:FindModifierByName("modifier_spark_gold")
      local specific_assist_gold = assistGold
      if spark then
        specific_assist_gold = math.floor(assistGold + assistGold * spark.hero_kill_bonus_gold)
      end

      Gold:ModifyGold(hero, specific_assist_gold, true, DOTA_ModifyGold_RoshanKill)

      local player = hero:GetPlayerOwner()
      if player then
        SendOverheadEventMessage(player, OVERHEAD_ALERT_GOLD, hero, specific_assist_gold, player)
      end
    end
  end
end
