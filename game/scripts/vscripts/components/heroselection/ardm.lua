ARDMMode = ARDMMode or class({})

--local PrecacheHeroEvent = Event()

function ARDMMode:Init ()
  -- ARDM modifiers
  LinkLuaModifier("modifier_ardm", "modifiers/ardm/modifier_ardm.lua", LUA_MODIFIER_MOTION_NONE)
  LinkLuaModifier("modifier_ardm_disable_hero", "modifiers/ardm/modifier_ardm_disable_hero.lua", LUA_MODIFIER_MOTION_NONE)
  LinkLuaModifier("modifier_legion_commander_duel_damage_oaa_ardm", "modifiers/ardm/modifier_legion_commander_duel_damage_oaa_ardm.lua", LUA_MODIFIER_MOTION_NONE)
  LinkLuaModifier("modifier_silencer_int_steal_oaa_ardm", "modifiers/ardm/modifier_silencer_int_steal_oaa_ardm.lua", LUA_MODIFIER_MOTION_NONE)
  LinkLuaModifier("modifier_pudge_flesh_heap_oaa_ardm", "modifiers/ardm/modifier_pudge_flesh_heap_oaa_ardm.lua", LUA_MODIFIER_MOTION_NONE)
  LinkLuaModifier("modifier_slark_essence_shift_oaa_ardm", "modifiers/ardm/modifier_slark_essence_shift_oaa_ardm.lua", LUA_MODIFIER_MOTION_NONE)

  self.playedHeroes = {}
  self.precachedHeroes = {}

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
  --self.hasPrecached = false
  self.addedmodifier = {}
  self.heroPool = {
    [DOTA_TEAM_GOODGUYS] = {},
    [DOTA_TEAM_BADGUYS] = {}
  }

  -- Register event listeners
  GameEvents:OnHeroInGame(partial(self.ApplyARDMmodifier, self))
  GameEvents:OnHeroKilled(partial(self.ScheduleHeroChange, self))
  --GameEvents:OnHeroSelection(partial(self.StartPrecache, self))
  GameEvents:OnPreGame(partial(self.StartPrecache, self))
  --GameEvents:OnGameInProgress(partial(self.PrintTables, self))

  self:LoadHeroPoolsForTeams()
end

function ARDMMode:StartPrecache()
  Debug:EnableDebugging()
  self:PrecacheHeroes(function ()
    DebugPrint('Done precaching')
    GameRules:SendCustomMessage("Finishing with hero precaching...", 0, 0)
    PauseGame(false)
    --ARDMMode.hasPrecached = true
    --PrecacheHeroEvent.broadcast(true)
  end)
end

-- Precache only heroes that need to be precached (ignore banned and starting heroes)
function ARDMMode:PrecacheHeroes(cb)
  Debug:EnableDebugging()
  PauseGame(true)
  GameRules:SendCustomMessage("Started precaching heroes. PLEASE BE PATIENT.", 0, 0)
  DebugPrint('Started precaching heroes')
  local hero_count = #self.allHeroes --- #self.playedHeroes
  local done = after(hero_count, cb)
  for _, hero_name in pairs(self.allHeroes) do
    local playable = true
    for _, banned in pairs(self.playedHeroes) do
      if banned and hero_name == banned then
        DebugPrint(tostring(banned).." was randomed first or banned")
        playable = false
        break
      end
    end
    local precached = false
    for _, v in pairs(self.precachedHeroes) do
      if v and hero_name == v then
        DebugPrint(tostring(v).." was already precached")
        precached = true
        break
      end
    end
    if playable and not precached and hero_name then
      PrecacheUnitByNameAsync(hero_name, function()
        DebugPrint("Finished precaching this hero: "..tostring(hero_name))
        --GameRules:SendCustomMessage("Precached "..tostring(hero_name), 0, 0)
        table.insert(ARDMMode.precachedHeroes, hero_name)
        done()
      end, nil)
    else
      hero_count = hero_count - 1
    end
  end
end

-- Precache all heroes
--[[
function ARDMMode:PrecacheAllHeroes(cb)
  Debug:EnableDebugging()
  local heroCount = #self.allHeroes
  local done = after(heroCount, cb)
  DebugPrint('Starting precache process...')
  for _, hero in pairs(self.allHeroes) do
    if hero then
      PrecacheUnitByNameAsync(hero, function ()
        DebugPrint('precached this hero: ' .. hero)
        done()
      end)
    end
  end
end
]]

function ARDMMode:PrintTables()
  --Debug:EnableDebugging()
  DebugPrint("Played and banned heroes: ")
  DebugPrintTable(self.playedHeroes)
  DebugPrint("Precached heroes: ")
  DebugPrintTable(self.precachedHeroes)
  DebugPrint("All heroes: ")
  DebugPrintTable(self.allHeroes)
  DebugPrint("Radiant heroes: ")
  DebugPrintTable(self.heroPool[DOTA_TEAM_GOODGUYS])
  DebugPrint("Dire heroes: ")
  DebugPrintTable(self.heroPool[DOTA_TEAM_BADGUYS])
end

function ARDMMode:ApplyARDMmodifier(hero)
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

  -- Remove the hero from the pool
  --ARDMMode:RemoveHeroFromThePool(hero_name, hero_team)

  ARDMMode.addedmodifier[playerID] = true
end

function ARDMMode:ScheduleHeroChange(event)
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

  if new_hero_name then
    local precached = false
    for _, v in pairs(ARDMMode.precachedHeroes) do
      if v and new_hero_name == v then
        precached = true
        break
      end
    end
    if not precached then
      PrecacheUnitByNameAsync(new_hero_name, function()
        DebugPrint(tostring(new_hero_name).." has been precached")
        table.insert(ARDMMode.precachedHeroes, new_hero_name)
      end, playerID)
    end
  end

  local ardm_mod = killed_hero:FindModifierByName("modifier_ardm")
  if ardm_mod then
    ardm_mod.hero = new_hero_name
    DebugPrint("Killed hero "..tostring(killed_hero_name).." will be changed into "..tostring(new_hero_name))
  end
end

function ARDMMode:LoadHeroPoolsForTeams()
  local number_of_heroes = #self.allHeroes
  -- Copy the table
  local other_team_heroes = {}
  for k, v in pairs(self.allHeroes) do
    other_team_heroes[k] = self.allHeroes[k]
  end
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

--[[
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
]]

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
    -- This will also happen if herolist file is empty
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
