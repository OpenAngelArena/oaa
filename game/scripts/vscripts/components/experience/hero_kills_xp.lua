
if HeroKillXP == nil then
  DebugPrint ( 'Creating new HeroKillXP object.' )
  HeroKillXP = class({})
end

function HeroKillXP:Init()
  self.moduleName = "Hero Kill Experience"
  GameEvents:OnHeroKilled(partial(self.HeroDeathHandler, self))
  FilterManager:AddFilter(FilterManager.ModifyExperience, self, Dynamic_Wrap(HeroKillXP, "ExperienceFilter"))
  GameEvents:OnHeroInGame(partial(self.HeroSpawnNoXP, self))
end

function HeroKillXP:HeroSpawnNoXP(hero)
  hero:SetCustomDeathXP(0)
end

function HeroKillXP:ExperienceFilter(keys)
  if keys.reason_const == DOTA_ModifyXP_HeroKill then
    return false
  end
  return true
end

function HeroKillXP:HeroDeathHandler(keys)
  -- Based on HeroKillGold
  if not keys.killer or not keys.killed then
    return
  end

  if Duels:IsActive() and Duels.allowExperienceGain ~= 1 then
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

  local killedHeroXP = killedHero:GetCurrentXP()
  local killedHeroStreak = killedHero:GetStreak()
  local killedHeroLevel = killedHero:GetLevel()

  local killedHeroStreakXP = 0

  if killedHeroStreak > 2 then
    --killedHeroStreakXP = HERO_XP_BOUNTY_STREAK_BASE + HERO_XP_BOUNTY_STREAK_INCREASE * (killedHeroStreak - 3)
    killedHeroStreakXP = killedHeroStreak * killedHeroLevel * HERO_XP_BOUNTY_STREAK_BASE / 3
  end

  if killedHeroStreakXP > HERO_XP_BOUNTY_STREAK_MAX then
    killedHeroStreakXP = HERO_XP_BOUNTY_STREAK_MAX
  end

  local rewardHeroes
  local distributeCount = 1

  -- Heroes around the killed hero
  local heroes = FindHeroesInRadius(
    killerTeam,
    killedHero:GetAbsOrigin(),
    nil,
    HERO_KILL_XP_RADIUS,
    DOTA_UNIT_TARGET_TEAM_FRIENDLY,
    DOTA_UNIT_TARGET_HERO,
    bit.bor(DOTA_UNIT_TARGET_FLAG_NOT_ILLUSIONS, DOTA_UNIT_TARGET_FLAG_INVULNERABLE, DOTA_UNIT_TARGET_FLAG_OUT_OF_WORLD),
    FIND_ANY_ORDER,
    false
  )

  -- Handle non-player kills (when killerPlayerID is -1)
  -- in OAA those are: fountains, buildings, bottle statues, dummy units etc.)
  if not PlayerResource:IsValidTeamPlayerID(killerPlayerID) then
    local rewardPlayerIDs
    local numAttackers = killedHero:GetNumAttackers()
    if numAttackers == 0 then
      -- Distribute xp to all heroes on the killer team
      rewardPlayerIDs = PlayerResource:GetPlayerIDsForTeam(killerTeam)
      distributeCount = math.max(1, length(rewardPlayerIDs))
    elseif numAttackers == 1 then
      -- Give xp to single hero
      rewardPlayerIDs = iter({killedHero:GetAttacker(0)})
    else
      -- Distribute xp to heroes who assisted in kill
      rewardPlayerIDs = range(0, numAttackers - 1)
                          :map(partial(killedHero.GetAttacker, killedHero))
      distributeCount = numAttackers
    end
    rewardHeroes = map(partial(PlayerResource.GetSelectedHeroEntity, PlayerResource), rewardPlayerIDs)
  else
    local killerHero = PlayerResource:GetSelectedHeroEntity(killerPlayerID)

	-- When last hit by a hero from long range (>HERO_KILL_XP_RADIUS), that hero should always receive xp, regardless of distance
    local killerIsInHeroesTable = iter(heroes)
                                  :map(CallMethod("GetPlayerOwnerID"))
                                  :contains(killerPlayerID)
    if not killerIsInHeroesTable then
      table.insert(heroes, killerHero)
    end

    distributeCount = #heroes
  end

  local xp = math.floor((HERO_XP_BOUNTY_BASE + killedHeroStreakXP + (killedHeroXP * HERO_XP_BONUS_FACTOR)) / distributeCount)
  xp = math.max(0, xp)

  -- Non-player kills
  if rewardHeroes then
    for _, hero in rewardHeroes:unwrap() do
      if hero then
        -- Check for XP spark
        local spark = hero:FindModifierByName("modifier_spark_xp")
        local specific_hero_xp = xp
        if spark then
          specific_hero_xp = xp + xp * spark.hero_kill_bonus_xp
        end
        hero:AddExperience(specific_hero_xp, DOTA_ModifyXP_RoshanKill, false, true)
      end
    end
  end

  -- Player kills: Give xp to the killer and to heroes around the killed hero
  -- pairs is used instead of ipairs because order doesn't matter
  for _, hero in pairs(heroes) do
    if hero then
      -- Check for XP spark
      local spark = hero:FindModifierByName("modifier_spark_xp")
      local specific_hero_xp = xp
      if spark then
        specific_hero_xp = math.floor(xp + xp * spark.hero_kill_bonus_xp)
      end
      hero:AddExperience(specific_hero_xp, DOTA_ModifyXP_RoshanKill, false, true)
    end
  end
end
