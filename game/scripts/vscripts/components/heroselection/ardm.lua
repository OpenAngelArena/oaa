LinkLuaModifier("modifier_ardm", "modifiers/modifier_ardm.lua", LUA_MODIFIER_MOTION_NONE )

ARDMMode = ARDMMode or class({})

local PrecacheHeroEvent = Event()

function ARDMMode:Init (allHeroes)
  self.hasPrecached = false
  self.allHeroes = allHeroes
  self.addedmodifier = {}

  Debug:EnableDebugging()

  self.heroPool = {
    [DOTA_TEAM_GOODGUYS] = {},
    [DOTA_TEAM_BADGUYS] = {}
  }

  --GameEvents:OnHeroSelection(ARDMMode.StartPrecache)
  GameEvents:OnHeroInGame(ARDMMode.ApplyARDMmodifier)
  GameEvents:OnHeroKilled(ARDMMode.ChangeHero)

  self:ReloadHeroPool(DOTA_TEAM_GOODGUYS)
  self:ReloadHeroPool(DOTA_TEAM_BADGUYS)
end

function ARDMMode.StartPrecache()
  local allHeroes = ARDMMode.allHeroes
  ARDMMode:PrecacheAllHeroes(allHeroes, function ()
    DebugPrint('Done precaching')
    ARDMMode.hasPrecached = true
    PrecacheHeroEvent.broadcast(#allHeroes)
  end)
end

function ARDMMode.ApplyARDMmodifier(hero)
  if hero:GetTeamNumber() == DOTA_TEAM_NEUTRALS then
    return
  end

  if hero:IsTempestDouble() or hero:IsClone() then
    return
  end

  local playerID = hero:GetPlayerOwnerID()
  if ARDMMode.addedmodifier[playerID] then
    return
  end

  -- if hero:GetUnitName() == FORCE_PICKED_HERO then
    -- return
  -- end

  if not hero:HasModifier("modifier_ardm") then
    hero:AddNewModifier(hero, nil, "modifier_ardm", {})
  end

  ARDMMode.addedmodifier[playerID] = true
end

function ARDMMode.ChangeHero(event)
  if not event.killed then
    return
  end

  local killed_hero = event.killed
  local team = killed_hero:GetTeamNumber()
  local playerID = killed_hero:GetPlayerOwnerID()

  if killed_hero:IsClone() then
    killed_hero = killed_hero:GetCloneSource()
  end

  if killed_hero:IsReincarnating() or killed_hero:IsTempestDouble() then
    return
  end

  if team == DOTA_TEAM_NEUTRALS then
    return
  end

  if not killed_hero:HasModifier("modifier_ardm") and not ARDMMode.addedmodifier[playerID] then
    DebugPrint("Killed hero "..killed_hero:GetUnitName().." doesn't have ARDM modifier for some reason.")
    return
  end

  local new_hero_name = ARDMMode:GetRandomHero(team)

  local ardm_mod = killed_hero:FindModifierByName("modifier_ardm")
  if ardm_mod then
    ardm_mod.hero = new_hero_name
  end
end

function ARDMMode:ReloadHeroPool (teamId)
  for hero, primaryAttr in pairs(self.allHeroes) do
    self.heroPool[teamId][hero] = true
  end
end

function ARDMMode:PrecacheAllHeroes (heroList, cb)
  Debug:EnableDebugging()
  local heroCount = 0
  DebugPrint("herolist table:")
  for hero, primaryAttr in pairs(heroList) do
    print(hero, primaryAttr)
    heroCount = heroCount + 1
  end
  local done = after(heroCount, cb)

  DebugPrint('Starting precache process...')

  local function precacheUnit (hero)
    PrecacheUnitByNameAsync(hero, function ()
      DebugPrint('precached this hero! ' .. hero)
      done()
    end)
  end

  for hero, primaryAttr in pairs(heroList) do
    precacheUnit(hero)
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
  local n = 0
  local heroPool = {}
  for hero, v in pairs(self.heroPool[teamId]) do
    n = n + 1
    heroPool[n] = hero
  end

  if #heroPool < 1 then
    self:ReloadHeroPool(teamId)
    return self:GetRandomHero()
  end

  local hero = heroPool[RandomInt(1, #heroPool)]
  self.heroPool[teamId][hero] = nil

  return hero
end
