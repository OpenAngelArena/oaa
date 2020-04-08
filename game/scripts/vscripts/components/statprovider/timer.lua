HudTimer = HudTimer or class({})

local DOTA_CLOCK_SKEW = 0 - PREGAME_TIME
local CLOCK_SYNC_INTERVAL = 120

HudTimer.registeredListeners = {}
HudTimer.exactRegisteredListeners = {}

function HudTimer:Init()
  Debug:EnableDebugging()

  self.isPaused = false
  self.gameTime = DOTA_CLOCK_SKEW
  Debug:EnableDebugging()

  local startingOffset = math.floor(GameRules:GetDOTATime(true, true)) - self.gameTime

  DebugPrint('Using an initial clock skew of ' .. startingOffset .. ' at ' .. self.gameTime)
  self.IsGameInProgress = false


  Timers:CreateTimer(1 - GameRules:GetDOTATime(true, true) % 1, function()
    local gameState = GameRules:State_Get()
    if (gameState ~= DOTA_GAMERULES_STATE_GAME_IN_PROGRESS and gameState ~= DOTA_GAMERULES_STATE_PRE_GAME) or self.isPaused then
      return 1
    end

    if self.IsGameInProgress == false and gameState == DOTA_GAMERULES_STATE_GAME_IN_PROGRESS then
      self.gameTime = 0
      startingOffset = math.floor(GameRules:GetDOTATime(true, true))
      self.IsGameInProgress =true
    end

    local timeToNextDuel = Duels:GetNextDuelTime()
    if timeToNextDuel == nil then timeToNextDuel = 0 else timeToNextDuel = timeToNextDuel - self.gameTime end
    if timeToNextDuel < 0 then timeToNextDuel = 0 end

    local timeToNextCapture = CapturePoints:GetCaptureTime()
    if timeToNextCapture == nil then timeToNextCapture = 0 else timeToNextCapture = timeToNextCapture - self.gameTime end
    if timeToNextCapture < 0 then timeToNextCapture = 0 end

    local floorGameTime = math.floor(GameRules:GetDOTATime(true, true))
    if not self.isPaused then
      local newGameTime = floorGameTime - startingOffset
      if self.gameTime ~= newGameTime then
        self.gameTime = newGameTime
        self:SendOnThe(self.gameTime)
        self:SendAt(self.gameTime)
      end
    end

    CustomNetTables:SetTableValue( 'timer', 'data', {
      time = self.gameTime,
      isDay = GameRules:IsDaytime(),
      isNightstalker = GameRules:IsNightstalkerNight(),
      killLimit = PointsManager:GetLimit(),
      timeToNextDuel = timeToNextDuel,
      timeToNextCapture = timeToNextCapture
    })

    local gameMinuteOffset = (math.floor(GameRules:GetDOTATime(true, true) - DOTA_CLOCK_SKEW) % CLOCK_SYNC_INTERVAL)
    local localMinuteOffset = math.floor(self.gameTime) % CLOCK_SYNC_INTERVAL

    if self.gameTime > 0 and gameMinuteOffset ~= localMinuteOffset then
      Debug:EnableDebugging()
      DebugPrint('Clock skew detected! ' .. gameMinuteOffset .. ' / ' .. localMinuteOffset)
    end

    return 1
  end)
end

function HudTimer:At (timing, callback)
  if not self.exactRegisteredListeners[timing] then
    self.exactRegisteredListeners[timing] = Event()
  end
  return self.exactRegisteredListeners[timing].listen(callback)
end

function HudTimer:OnThe (timing, callback)
  if not self.registeredListeners[timing] then
    self.registeredListeners[timing] = Event()
  end
  return self.registeredListeners[timing].listen(callback)
end

function HudTimer:GetState ()
  return {
    time = self:GetGameTime(),
    day = GameRules:GetTimeOfDay()
  }
end

function HudTimer:LoadState (state)
  self:SetGameTime(state.time)
  GameRules:SetTimeOfDay(state.day)
end

function HudTimer:Pause()
  self.isPaused = true
end

function HudTimer:Resume()
  self.isPaused = false
end

function HudTimer:SetGameTime(gameTime)
  self.gameTime = gameTime
end

function HudTimer:GetGameTime()
  return self.gameTime
end

function HudTimer:SendAt (time)
  if self.exactRegisteredListeners[time] then
    self.exactRegisteredListeners[time].broadcast(true)
    self.exactRegisteredListeners[time] = nil
  end
end
function HudTimer:SendOnThe (time)
  for timing,callback in pairs(self.registeredListeners) do
    if time % tonumber(timing) == 0 then
      callback.broadcast(true)
    end
  end
end
