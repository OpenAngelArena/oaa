if HeroProgression == nil then
    HeroProgression = class({})
    Debug.EnabledModules['progression:*'] = false
end

GameEvents:OnPlayerLevelUp(function(keys)
  Debug:EnableDebugging()
  -- dota_player_gained_level:
  --"player_id"
  --"level"
  --"hero_entindex"
  local playerID = keys.player_id or keys.PlayerID -- just in case Valve randomly changes it again
  local player
  if keys.player then
    player = EntIndexToHScript(keys.player)
  else
    player = PlayerResource:GetPlayer(playerID)
  end
  local hero
  if keys.hero_entindex then
    hero = EntIndexToHScript(keys.hero_entindex)
  else
    hero = player:GetAssignedHero()
  end
  local level = keys.level
  local playerLevel = PlayerResource:GetLevel(playerID)

  -- Skip processing if the level of the unit is reported as less than the player level
  -- This is to prevent levelling of illusions from causing repeated processing on main hero
  if level <= playerLevel then
    return
  end

--  HeroProgression:ReduceStatGain(hero, level)
  HeroProgression:ProcessAbilityPointGain(hero, level)
end)
-- GameEvents:OnNPCSpawned(function(keys)
  -- local npc = EntIndexToHScript(keys.entindex)
--  HeroProgression:ReduceIllusionStats(npc)
-- end)

function HeroProgression:RegisterCustomLevellingPatterns()
  self.customLevellingPatterns['npc_dota_hero_invoker'] = (function(level)
    -- Invoker gets all dem ability points
    return true
  end)
end

function HeroProgression:Init()
  self.statNames = {
    "Strength",
    "Agility",
    "Intellect"
  }
  self.customLevellingPatterns = {}
  self.statStorage = {} -- Cache for calculated reduced stats
  self.XPStorage = tomap(zip(PlayerResource:GetAllTeamPlayerIDs(), duplicate(0)))

  local function GivePlayerExperience (playerID)
    if not HeroProgression.XPStorage[playerID] or PlayerResource:GetConnectionState(playerID) ~= DOTA_CONNECTION_STATE_CONNECTED then
      return
    end
    local hero = PlayerResource:GetSelectedHeroEntity(playerID)

    if hero then
      hero:AddExperience(HeroProgression.XPStorage[playerID], DOTA_ModifyXP_Unspecified, false, true)
      HeroProgression.XPStorage[playerID] = 0
    else
      Timers:CreateTimer(partial(GivePlayerExperience, playerID), 1)
    end
  end
  GameEvents:OnPlayerReconnect(function(keys)
    local playerID = keys.PlayerID
    GivePlayerExperience(playerID)
  end)

  FilterManager:AddFilter(FilterManager.ModifyExperience, self, Dynamic_Wrap(HeroProgression, "ExperienceFilter"))
  self:RegisterCustomLevellingPatterns()
end

function HeroProgression.GetBaseStat(entity, statName)
  return entity["GetBase" .. statName](entity)
end

function HeroProgression.SetBaseStat(entity, statName, statValue)
  entity["SetBase" .. statName](entity, statValue)
end

function HeroProgression.GetStatGain(entity, statName)
  return entity["Get" .. statName .. "Gain"](entity)
end

function HeroProgression.ModifyStat(entity, statName, modifyAmount)
  entity["Modify" .. statName](entity, modifyAmount)
end

--[[
function HeroProgression:ReduceStatGain(hero, level)
  if level > 25 then
    local reductionFactor = 12 / (level - 25 + 12)

    local statGains = map(partial(self.GetStatGain, hero), self.statNames)

    local reducedStatGains = map(operator.mul, zip(statGains, duplicate(reductionFactor)))
    local statModifications = map(operator.sub, zip(reducedStatGains, statGains))

    foreach(partial(self.ModifyStat, hero), zip(self.statNames, statModifications))
  end
end

function HeroProgression:ReduceIllusionStats(illusionEnt)
  -- Support functions
  local function CalculateStatAt25(unitLevel, currentBaseStat, statGain)
    return currentBaseStat - (unitLevel - 25) * statGain
  end

  local function CalculateReducedStat(unitLevel, statAt25, statGain)
    self.statStorage[statGain] = self.statStorage[statGain] or {}
    local post25Stat = self.statStorage[statGain][unitLevel]
    if not post25Stat then
      post25Stat = statGain * 12 * math.log((2 * (unitLevel - 13) + 1) / (2 * 13 - 1))
      self.statStorage[statGain][unitLevel] = post25Stat
    end
    return statAt25 + post25Stat
  end

  local GetBaseStat = partial(self.GetBaseStat, illusionEnt)
  local SetBaseStat = partial(self.SetBaseStat, illusionEnt)
  local GetStatGain = partial(self.GetStatGain, illusionEnt)

  -- Set one frame delay because illusions won't immediately have the correct level
  local function ReduceStats()
    Timers:CreateTimer(function()
      local currentHealth = illusionEnt:GetHealth()
      local currentMana = illusionEnt:GetMana()
      local illusionLevel = illusionEnt:GetLevel()
      -- No need to do anything if the illusion isn't above level 25
      -- Or if the illusion is a Hybrid
      if illusionLevel <= 25 or illusionEnt:HasModifier("modifier_morph_hybrid_special") then
        return
      end

      local statGains = map(GetStatGain, self.statNames)
      local currentBaseStats = map(GetBaseStat, self.statNames)

      -- Calculate stats after reduction, set them, and call CalculateStatBonus to update health, mana, damage, etc.
      local statsAt25 = illusionEnt.statsAt25 or map(partial(CalculateStatAt25, illusionLevel), zip(currentBaseStats, statGains))
      -- Save level 25 stats as a property on the illusion entity the first time that entity is handled by this function
      -- Mainly used for Arc Warden Tempest Double because it's a persistent entity
      if illusionEnt:IsTempestDouble() then
        illusionEnt.statsAt25 = illusionEnt.statsAt25 or totable(statsAt25)
      end
      local reducedStats = map(partial(CalculateReducedStat, illusionLevel), zip(statsAt25, statGains))

      -- Don't modify strength and agility of Morphling illusions
      if illusionEnt:GetName() == "npc_dota_hero_morphling" then
        SetBaseStat("Intellect", nth(3, reducedStats))
      else
        foreach(SetBaseStat, zip(self.statNames, reducedStats))
      end
      illusionEnt:CalculateStatBonus()
      -- Set health and mana back to the values the illusion spawned with
      illusionEnt:SetHealth(currentHealth)
      illusionEnt:SetMana(currentMana)
    end)
  end

  -- Note: Will not run on very first spawn of Tempest Double in a game due to the flag only being set on the next frame
  if illusionEnt.IsIllusion and (illusionEnt:IsIllusion() or illusionEnt:IsTempestDouble()) and illusionEnt:IsHero() then
    ReduceStats()
  else
    -- Double check for Tempest Double with one frame delay to catch first spawn
    Timers:CreateTimer(function()
      if not illusionEnt:IsNull() and illusionEnt.IsTempestDouble and illusionEnt:IsTempestDouble() then
        ReduceStats()
      end
    end)
  end
end
]]--

function HeroProgression:ShouldGetAnAbilityPoint(hero, level)
  local pattern = HeroProgression.customLevellingPatterns[hero:GetName()]
  if pattern == nil then
    -- normal leveling up until 25
    if level < 25 then
      return true
    end
    -- get 1 point every 3rd level from now on
    return math.fmod(level, 3) == 1
  else
    -- Hero levelling up has a custom levelling pattern
    -- (e.g. Invoker who gets all the skillpoints every level)
    return pattern(level)
  end
end

function HeroProgression:ProcessAbilityPointGain(hero, level)
  DebugPrint('Processing the ability point for ' .. hero:GetName() .. ' at level ' .. level .. ' they have ' .. hero:GetAbilityPoints())
  --[[
  if not self:ShouldGetAnAbilityPoint(hero, level) then
    DebugPrint('...taken it away! (had ' .. hero:GetAbilityPoints() .. ' ability points)')
    hero:SetAbilityPoints(hero:GetAbilityPoints() - 1)
  end
  ]]
  --[[ -- ability points are not spent automatically on the talents at 30
  if level == 30 then
    hero:SetAbilityPoints(hero:GetAbilityPoints() + 4)
  end
  ]]
  if self:ShouldGetAnAbilityPoint(hero, level) and level > 25 then
    DebugPrint('Add 1 ability point (had ' .. hero:GetAbilityPoints() .. ' ability points)')
    hero:SetAbilityPoints(hero:GetAbilityPoints() + 1)
  end
end

function HeroProgression:ExperienceFilter(keys)
  local playerID = keys.player_id_const
  local experience = keys.experience

  if experience then
    if PlayerResource:GetConnectionState(playerID) == DOTA_CONNECTION_STATE_CONNECTED then
      return true
    else
      if not self.XPStorage[playerID] then
        self.XPStorage[playerID] = 0
      end
      self.XPStorage[playerID] = self.XPStorage[playerID] + experience
      return false
    end
  end
end
