LinkLuaModifier("modifier_ardm", "modifiers/modifier_ardm.lua", LUA_MODIFIER_MOTION_NONE )

ARDMMode = ARDMMode or class({})

local PrecacheHeroEvent = Event()

function ARDMMode:Init (allHeroes)
  self.hasPrecached = false
  self.allHeroes = allHeroes
  self.estimatedExperience = {}

  Debug:EnableDebugging()

  GameEvents:OnHeroSelection(function ()
    self:PrecacheAllHeroes(allHeroes, function ()
      DebugPrint('Done precaching')
      self.hasPrecached = true
      PrecacheHeroEvent.broadcast(#allHeroes)
    end)
  end)

  self.heroPool = {
    [DOTA_TEAM_GOODGUYS] = {},
    [DOTA_TEAM_BADGUYS] = {}
  }

  GameEvents:OnHeroInGame(function (npc)
    local teamId = npc:GetTeam()
    if teamId == DOTA_TEAM_NEUTRALS or npc:GetUnitName() == FORCE_PICKED_HERO then
      return
    end

    npc:AddNewModifier(npc, nil, "modifier_ardm", {})
  end)

  GameEvents:OnHeroKilled(function (keys)
    local teamId = keys.killed:GetTeam()
    if not keys.killed:IsReincarnating() and teamId ~= DOTA_TEAM_NEUTRALS then
      local playerId = keys.killed:GetPlayerID()
      -- rerandom!
      local oldHero = PlayerResource:GetSelectedHeroEntity(playerId)
      local newHeroName = self:GetRandomHero(teamId)

      local modardm = oldHero:FindModifierByName("modifier_ardm")
      if modardm then
        modardm.hero = newHeroName
      end
    end
  end)

  self:ReloadHeroPool(DOTA_TEAM_GOODGUYS)
  self:ReloadHeroPool(DOTA_TEAM_BADGUYS)
end

function ARDMMode:ReloadHeroPool (teamId)
  for hero,primaryAttr in pairs(self.allHeroes) do
    self.heroPool[teamId][hero] = true
  end
end

function ARDMMode:PrecacheAllHeroes (heroList, cb)
  local heroCount = 0
  for hero,primaryAttr in pairs(heroList) do
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

  for hero,primaryAttr in pairs(heroList) do
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
  for hero,v in pairs(self.heroPool[teamId]) do
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
