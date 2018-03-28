HudTimer = HudTimer or class({})

function HudTimer:Init()
  self.isPaused = false
  self.gameTime = 0
  Timers:CreateTimer(function()
    CustomNetTables:SetTableValue( 'timer', 'data', {
      time = self.gameTime,
      isDay = GameRules:IsDaytime(),
      isNightstalker = GameRules:IsNightstalkerNight()
    })

    if not self.isPaused then
      self.gameTime = self.gameTime + 1
    end

    return 1
  end)
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
