HudTimer = HudTimer or class({})

function HudTimer:Init()
  self.isPaused = false
  self.gameTime = 0
  Timers:CreateTimer(function()
    local timeToNextDuel = Duels:GetNextDuelTime()
    if timeToNextDuel == nil then timeToNextDuel = 0 else timeToNextDuel = timeToNextDuel - self.gameTime end
    if timeToNextDuel < 0 then timeToNextDuel = 0 end

    local timeToNextCapture = CapturePoints:GetCaptureTime()
    if timeToNextCapture == nil then timeToNextCapture = 0 else timeToNextCapture = timeToNextCapture - self.gameTime end
    if timeToNextCapture < 0 then timeToNextCapture = 0 end

    CustomNetTables:SetTableValue( 'timer', 'data', {
      time = self.gameTime,
      isDay = GameRules:IsDaytime(),
      isNightstalker = GameRules:IsNightstalkerNight(),
      killLimit = PointsManager:GetLimit(),
      timeToNextDuel = timeToNextDuel,
      timeToNextCapture = timeToNextCapture
    })

    if not self.isPaused then
      self.gameTime = self.gameTime + 1
    end

    return 1
  end)
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
