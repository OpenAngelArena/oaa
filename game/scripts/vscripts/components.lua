
-- init time constants
COMPONENT_GAME_SETUP = 1
COMPONENT_TEAM_SELECT = 2
COMPONENT_HERO_SELECT = 3
COMPONENT_STRATEGY = 4
COMPONENT_GAME_IN_PROGRESS = 5

Components = Components or class({})

function Components:Init()
  -- Debug:EnableDebugging()
  if not self.components then
    self.components = {}
    self.initTime = {}
  end
  self.mostRecentPhase = 0

  DebugPrint('Initting component registery system')

  self:ConnectEvent(COMPONENT_GAME_SETUP)()
  self:ConnectEvent(COMPONENT_TEAM_SELECT)()
  GameEvents:OnHeroSelection(self:ConnectEvent(COMPONENT_HERO_SELECT))
  GameEvents:OnPreGame(self:ConnectEvent(COMPONENT_STRATEGY))
  GameEvents:OnGameInProgress(self:ConnectEvent(COMPONENT_GAME_IN_PROGRESS))
end

function Components:Register (name, startup)
  -- Debug:EnableDebugging()
  DebugPrint('Registering ' .. name)
  if not self.components then
    self.components = {}
    self.initTime = {}
    self.mostRecentPhase = 0
  end

  if self.components[name] then
    DebugPrint(name .. ' registered twice')
    return self.components[name]
  end

  self.components[name] = class({})
  if not self.initTime[startup] then
    self.initTime[startup] = {}
  end
  table.insert(self.initTime[startup], name)

  if self.mostRecentPhase >= startup then
    DebugPrint(name .. ' was registered after its init phase!')
    self:InitComponent(self.components[name])
  end

  return self.components[name]
end

function Components:InitComponent (component)
  DebugPrint('Initting this component!')
  if component.Init then
    component:Init()
  else
    DebugPrint('This component has no init function!')
  end
end

function Components:ConnectEvent (event)
  local function handleEvent ()
    self.mostRecentPhase = math.max(self.mostRecentPhase, event)
    if self.initTime[event] then
      for _,name in ipairs(self.initTime[event]) do
        self:InitComponent(self.components[name])
      end
    end
  end

  return handleEvent
end
