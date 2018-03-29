--LinkLuaModifier("modifier_standard_capture_point", "modifiers/modifier_standard_capture_point.lua", LUA_MODIFIER_MOTION_NONE)

CAPTUREPOINT_IS_STARTING = 60
CapturePoints = CapturePoints or {}
local zoneNames = {
  "random",
  "randomMir",
}

local UninteruptedStart = Event()
local WaitForDuel = Event()
local PrepareCapture = Event()
local EndCapture = Event()

CapturePoints.onPreparing = PrepareCapture.listen
CapturePoints.onWait = WaitForDuel.listen
CapturePoints.onStart = UninteruptedStart.listen
CapturePoints.onEnd = EndCapture.listen

function CapturePoints:Init ()
  Debug.EnabledModules['components:*']  = true
  DebugPrint('Init capture point')

  self.currentCapture = nil

  Timers:CreateTimer(INITIAL_CAPTURE_POINT_DELAY - CAPTURE_FIRST_WARN - 80, function ()
    self:StartCapture()
  end)

  -- Add chat commands to force start and end duels
  ChatCommand:LinkCommand("-capture", Dynamic_Wrap(self, "StartCapture"), self)
  ChatCommand:LinkCommand("-end_capture", Dynamic_Wrap(self, "EndCapture"), self)
end

function CapturePoints:IsActive ()
  if not self.currentCapture or self.currentCapture == CAPTUREPOINT_IS_STARTING then
    return false
  end
  return true
end

function CapturePoints:StartCapture()
  if self.startCaptureTimer then
    Timers:RemoveTimer(self.startCaptureTimer)
    self.startCaptureTimer = nil
  end

  self.startCaptureTimer = Timers:CreateTimer(CAPTURE_INTERVAL, function ()
    self:StartCapture()
  end)

  if self.currentCapture then
    DebugPrint ('There is already a capture running')
    return
  end
  self.currentCapture = CAPTUREPOINT_IS_STARTING
--if not Dual:DuelPreparingEvent

  PrepareCapture.broadcast(true)

  self.currentCapture = {
    y = 1
  }
  Notifications:TopToAll({text="Capture Points will start in 1 minute!", duration=3.0, style={color="blue", ["font-size"]="70px"}})

  Timers:CreateTimer(CAPTURE_SECOND_WARN, function ()
    Notifications:TopToAll({text="A Capture Points will start in 30 seconds!", duration=3.0, style={color="blue", ["font-size"]="70px"}})
  end)

  Timers:CreateTimer(CAPTURE_FIRST_WARN, function ()
    self:ActuallyStartCapture()
  end)

end

function CapturePoints:ActuallyStartCapture()
  Notifications:TopToAll({text="Capture Points Active!", duration=3.0, style={color="blue", ["font-size"]="70px"}})
  DebugPrint ('CaptureStarted')
  UninteruptedStart.broadcast(self.currentCapture)

  Timers:CreateTimer(30, function ()
    self:EndCapture()
  end)
end

function CapturePoints:EndCapture ()
  if self.currentCapture == nil then
    DebugPrint ('There is no Capture running')
    return
  end
  Notifications:TopToAll({text="Capture Ended", duration=3.0, style={color="blue", ["font-size"]="110px"}})
  DebugPrint('Capture Point has ended')

  local nextCapturePointIn = CAPTURE_INTERVAL

  local currentCapture = self.currentCapture
  self.currentCapture = nil

  Timers:CreateTimer(0.1, function ()
    DebugPrint('Ending dual')
    -- Remove Modifier

    EndCapture.broadcast(currentCapture)
  end)
end
