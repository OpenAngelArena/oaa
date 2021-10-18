LinkLuaModifier("modifier_ardm", "modifiers/modifier_ardm.lua", LUA_MODIFIER_MOTION_NONE )

ARDMMode = ARDMMode or class({})

local PrecacheHeroEvent = Event()

function ARDMMode:Init ()
  Debug:EnableDebugging()

  -- Define the hero pool
  local ardm_heroes = {}
  local herolistFile = 'scripts/npc/herolist_ardm.txt'
  local herolistTable = LoadKeyValues(herolistFile)
  for key, value in pairs(herolistTable) do
    if value == 1 then
      table.insert(ardm_heroes, key)
    end
  end

  self.allHeroes = ardm_heroes
  self.hasPrecached = false
  self.addedmodifier = {}
  self.heroPool = {
    [DOTA_TEAM_GOODGUYS] = {},
    [DOTA_TEAM_BADGUYS] = {}
  }
  self.playedHeroes = {}

  --GameEvents:OnHeroSelection(ARDMMode.StartPrecache)
  DebugPrint('Start precaching')
  self:StartPrecache()

  -- Register event listeners
  GameEvents:OnHeroInGame(ARDMMode.ApplyARDMmodifier)
  GameEvents:OnHeroKilled(ARDMMode.ScheduleHeroChange)

  self:LoadHeroPoolsForTeams()
end

function ARDMMode:StartPrecache()
  local ardm_heroes = ARDMMode.allHeroes
  ARDMMode:PrecacheAllHeroes(ardm_heroes, function ()
    DebugPrint('Done precaching')
    ARDMMode.hasPrecached = true
    PrecacheHeroEvent.broadcast(#ardm_heroes)
  end)
end

function ARDMMode.ApplyARDMmodifier(hero)
  local hero_team = hero:GetTeamNumber()
  local hero_name = hero:GetUnitName()

  if hero_team == DOTA_TEAM_NEUTRALS then
    return
  end

  if hero:IsTempestDouble() or hero:IsClone() then
    return
  end

  local playerID = hero:GetPlayerOwnerID()
  if ARDMMode.addedmodifier[playerID] then
    return
  end

  if not hero:HasModifier("modifier_ardm") then
    hero:AddNewModifier(hero, nil, "modifier_ardm", {})
  end

  -- Mark the first spawned hero as played - needed because of some edge cases
  table.insert(ARDMMode.playedHeroes, hero_name)

  -- Remove the hero from the pool - needed because of some edge cases
  ARDMMode:RemoveHeroFromThePool(hero_name, hero_team)

  ARDMMode.addedmodifier[playerID] = true
end

function ARDMMode.ScheduleHeroChange(event)
  if not event.killed then
    return
  end

  local killed_hero = event.killed
  local killed_hero_name = killed_hero:GetUnitName()
  local killed_team = killed_hero:GetTeamNumber()
  local playerID = killed_hero:GetPlayerOwnerID()

  if killed_team == DOTA_TEAM_NEUTRALS then
    return
  end

  if killed_hero:IsClone() then
    killed_hero = killed_hero:GetCloneSource()
  end

  if killed_hero:IsReincarnating() or killed_hero:IsTempestDouble() then
    return
  end

  if not killed_hero:HasModifier("modifier_ardm") and not ARDMMode.addedmodifier[playerID] then
    DebugPrint("Killed hero "..tostring(killed_hero_name).." doesn't have ARDM modifier for some reason.")
    return
  end

  -- Mark the killed hero as played
  table.insert(ARDMMode.playedHeroes, killed_hero_name)

  -- Remove the killed hero from the pool
  ARDMMode:RemoveHeroFromThePool(killed_hero_name, killed_team)

  local new_hero_name = ARDMMode:GetRandomHero(killed_team)

  local ardm_mod = killed_hero:FindModifierByName("modifier_ardm")
  if ardm_mod then
    ardm_mod.hero = new_hero_name
    DebugPrint("Killed hero "..tostring(killed_hero_name).." will be changed into "..tostring(new_hero_name))
  end
end

function ARDMMode:LoadHeroPoolsForTeams()
  local number_of_heroes = #self.allHeroes
  local other_team_heroes = self.allHeroes
  local i = 0

  -- Form the hero pool for the Radiant team
  while i <= math.floor(number_of_heroes/2) do
    local random_number = RandomInt(1, number_of_heroes)
    local hero_name = self.allHeroes[random_number]
    if hero_name then
      -- Check if already in the table
      local already = false
      for _, v in pairs(self.heroPool[DOTA_TEAM_GOODGUYS]) do
        if v == hero_name then
          already = true
          break -- break for loop
        end
      end

      if not already then
        table.insert(self.heroPool[DOTA_TEAM_GOODGUYS], hero_name)
        other_team_heroes[random_number] = nil
        i = i + 1
      end
    end
  end

  -- Form the hero pool for the Dire team
  for _, hero_name in pairs(other_team_heroes) do
    if hero_name ~= nil then
      table.insert(self.heroPool[DOTA_TEAM_BADGUYS], hero_name)
    end
  end
end

function ARDMMode:PrecacheAllHeroes (heroList, cb)
  Debug:EnableDebugging()
  local heroCount = 0
  DebugPrint("herolist table:")
  for k, v in pairs(heroList) do
    --print(k, v)
    heroCount = heroCount + 1
  end
  local done = after(heroCount, cb)

  DebugPrint('Starting precache process...')

  local function precacheUnit (hero)
    PrecacheUnitByNameAsync(hero, function ()
      DebugPrint('precached this hero: ' .. hero)
      done()
    end)
  end

  for k, v in pairs(heroList) do
    precacheUnit(v)
  end
end

function ARDMMode:OnPrecache (cb)
  if self.hasPrecached then
    cb()
    -- no unlisten event to return, send noop
    return noop
  end

  return PrecacheHeroEvent.listen(cb)
end

function noop ()
end

function ARDMMode:GetRandomHero (teamId)
  local heroPool = self.heroPool[teamId]
  -- Count non-nil table elements
  local n = 0
  for k, v in pairs(heroPool) do
    if v ~= nil then
      n = n + 1
    end
  end

  -- Check if heroPool has non-nil elements
  if n < 1 then
    --self:ReloadHeroPoolForTeam(teamId)
    return nil
  end

  local random_number = RandomInt(1, #heroPool)
  local hero_name = heroPool[random_number]

  -- Check if this hero name is valid, do all the above again if not
  if not hero_name then
    return self:GetRandomHero(teamId)
  end

  -- Check if this hero was played before
  local played = false
  for _, v in pairs(self.playedHeroes) do
    if v == hero_name then
      played = true
      break -- break for loop
    end
  end

  if played then
    -- Remove the hero from the pool because it was played
    self.heroPool[teamId][random_number] = nil

    -- Do all the above again
    return self:GetRandomHero(teamId)
  end

  return hero_name
end

function ARDMMode:RemoveHeroFromThePool(hero_name, teamId)
  for k, v in pairs(self.heroPool[teamId]) do
    if v ~= nil and v == hero_name then
      self.heroPool[teamId][k] = nil
    end
  end
end
