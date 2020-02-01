LinkLuaModifier("modifier_standard_capture_point", "modifiers/modifier_standard_capture_point.lua", LUA_MODIFIER_MOTION_NONE)

CAPTUREPOINT_IS_STARTING = 60
CapturePoints = CapturePoints or {}
--local FirstZones = {
  --left = Vector(-3584, 0, 256),
  --right = Vector(3584, 0, 256),
--}
local Zones = {
-- TODO, change this. These should be zones in the map or programatically generated
-- hard coded is a bad in-between with the disadvantages of both
  { left = Vector( -1280, -1000, 0), right = Vector( 1280, 1000, 0) }, --Zones
  { left = Vector( -1920, -768, 0), right = Vector( 1920, 768, 0) },
  { left = Vector( -2176, -384, 0), right = Vector( 2176, 384, 0) },
  { left = Vector( -960, -1280, 0), right = Vector( 1152, 1180, 0) },
  { left = Vector( -640, -1664, 0), right = Vector( 640, 1800, 0) },
  { left = Vector( -2048, -1408, 0), right = Vector( 1792, 1280, 0) },
  { left = Vector( -2304, -2048, 0), right = Vector( 2304, 2048, 0) },  -- in the stairs
  { left = Vector( -1700, -2300, 0), right = Vector( 1920, 1920, 0) },
  { left = Vector( -1408, -3200, 128), right = Vector( 1408, 3200, 128) },
  { left = Vector( -2492, -3216, 128), right = Vector( 1892, 3016, 128) },
  { left = Vector( -2304, -2944, 128), right = Vector( 2304, 2944, 128) },
  { left = Vector( -1566, -3584, 128), right = Vector( 1566, 3584, 128) },
  { left = Vector( -1152, -4096, 128), right = Vector( 1152, 4096, 128) },
  { left = Vector( -2650, -3072, 128), right = Vector( 2650, 3072, 128) },
  { left = Vector( -3584, -3072, 128), right = Vector( 3496, 3072, 128) },
  { left = Vector( -4992, -3200, 128), right = Vector( 4992, 3200, 128) },
  { left = Vector( -2047, 670, 0), right = Vector( 2052, -625, 0) },
  { left = Vector( -1920, 768, 0), right = Vector( 1920, -768, 0) },  -- same as the second one
  { left = Vector( -2176, 384, 0), right = Vector( 2176, -384, 0) },
  { left = Vector( -1024, 1280, 0), right = Vector( 1152, -1280, 0) },
  { left = Vector( -1024, 1664, 0), right = Vector( 1024, -1664, 0) },
  { left = Vector( -1664, 1280, 0), right = Vector( 2192, -1380, 0) },
  { left = Vector( -1726, 1924, 0), right = Vector( 1798, -2007, 0) },
  { left = Vector( -1664, 1920, 0), right = Vector( 1664, -1920, 0) },
  { left = Vector( -1408, 3200, 128), right = Vector( 1408, -3200, 128) },
  { left = Vector( -1792, 2816, 128), right = Vector( 2000, -2816, 128) },
  { left = Vector( -2304, 2944, 128), right = Vector( 2304, -2944, 128) },
  { left = Vector( -1566, 3584, 128), right = Vector( 1566, -3584, 128) },
  { left = Vector( -1152, 4096, 128), right = Vector( 1152, -4096, 128) },
  { left = Vector( -3121, 3885, 128), right = Vector( 2709, -3830, 128) },
  { left = Vector( -3584, 3072, 128), right = Vector( 3363, -3228, 128) },
  { left = Vector( -4992, 3200, 128), right = Vector( 4992, -3200, 128) }}

local NumZones = 32
local NumCaptures = 0
local LiveZones = 0
local Start = Event()
local PrepareCapture = Event()
local CaptureFinished = Event()
local CurrentZones = {}
CapturePoints.onPreparing = PrepareCapture.listen
CapturePoints.onStart = Start.listen
CapturePoints.onEnd = CaptureFinished.listen

function CapturePoints:Init ()
  -- Debug.EnableDebugging()
  DebugPrint('Init capture point')

  self.currentCapture = nil

  CapturePoints.nextCaptureTime = INITIAL_CAPTURE_POINT_DELAY
  HudTimer:At(INITIAL_CAPTURE_POINT_DELAY - 60, function ()
    self:ScheduleCapture()
  end)

  -- Add chat commands to force start and end captures
  ChatCommand:LinkDevCommand("-capture", Dynamic_Wrap(self, "ScheduleCapture"), self)
  ChatCommand:LinkDevCommand("-end_capture", Dynamic_Wrap(self, "EndCapture"), self)
end

function CapturePoints:GetState ()
  local state = {}

  state.captures = NumCaptures

  return state
end

function CapturePoints:LoadState (state)
  NumCaptures = state.captures
end

function CapturePoints:IsActive ()
  if not self.currentCapture or self.currentCapture == CAPTUREPOINT_IS_STARTING then
    return false
  end
  return true
end

function CapturePoints:MinimapPing()
  --Pings Minimap about zones
  Timers:CreateTimer(3.2, function ()
    Minimap:SpawnCaptureIcon(CurrentZones.right)
  end)
  Minimap:SpawnCaptureIcon(CurrentZones.left)
  for playerId = 0,19 do
    local player = PlayerResource:GetPlayer(playerId)
    if player ~= nil then
      if player:GetAssignedHero() then
        if player:GetTeam() == DOTA_TEAM_BADGUYS then
          MinimapEvent(DOTA_TEAM_GOODGUYS, player:GetAssignedHero(), CurrentZones.left.x,  CurrentZones.left.y, DOTA_MINIMAP_EVENT_HINT_LOCATION, 3)
          Timers:CreateTimer(3.2, function ()
            if player ~= nil and not player:IsNull() then
              MinimapEvent(DOTA_TEAM_GOODGUYS, player:GetAssignedHero(), CurrentZones.right.x,  CurrentZones.right.y, DOTA_MINIMAP_EVENT_HINT_LOCATION , 3)
            end
          end)
        else
          MinimapEvent(DOTA_TEAM_GOODGUYS, player:GetAssignedHero(), CurrentZones.left.x,  CurrentZones.left.y, DOTA_MINIMAP_EVENT_HINT_LOCATION, 3)
          Timers:CreateTimer(3.2, function ()
            if player ~= nil and not player:IsNull() then
              MinimapEvent(DOTA_TEAM_GOODGUYS, player:GetAssignedHero(), CurrentZones.right.x,  CurrentZones.right.y, DOTA_MINIMAP_EVENT_HINT_LOCATION , 3)
            end
          end)
        end
      end
    end
  end
end

function CapturePoints:GetCaptureTime()
  if CapturePoints.nextCaptureTime == nil or CapturePoints.nextCaptureTime < 0 then return 0 end
  return CapturePoints.nextCaptureTime
end

function CapturePoints:ScheduleCapture()
  if self.scheduleCaptureTimer then
    Timers:RemoveTimer(self.scheduleCaptureTimer)
    self.scheduleCaptureTimer = nil
  end
  PrepareCapture.broadcast(true)

  CapturePoints.nextCaptureTime = HudTimer:GetGameTime() + CAPTURE_INTERVAL + CAPTURE_FIRST_WARN

  self.scheduleCaptureTimer = Timers:CreateTimer(CAPTURE_INTERVAL, function ()
    self:ScheduleCapture()
  end)

  if self.currentCapture then
    DebugPrint ('There is already a capture running')
    return
  end

  self.currentCapture = CAPTUREPOINT_IS_STARTING
  Debug:EnableDebugging()
  -- DebugPrint('Capture number... ' .. NumCaptures)
  -- if NumCaptures == 0 then
    -- Use tier 1 zones for tier 1
    -- CurrentZones = FirstZones
  -- else
    -- Chooses random zone
  CurrentZones = Zones[RandomInt(1, NumZones)]
  -- end
  --If statemant checks for duel interference
  if not Duels.startDuelTimer then
    CapturePoints:StartCapture("blue")
  elseif Timers.timers[Duels.startDuelTimer] and Timers:RemainingTime(Duels.startDuelTimer) > 90 then
    CapturePoints:StartCapture("red")
  else
    CapturePoints.unlistenDuel = Duels.onEnd(function ()
      Timers:CreateTimer(15, function ()
        CapturePoints:StartCapture("red")
      end)
      if CapturePoints.unlistenDuel ~= nil then
        local unlisten = CapturePoints.unlistenDuel
        unlisten()
        CapturePoints.unlistenDuel = nil
      end
    end)
  end
end

function CapturePoints:StartCapture(color)
  CapturePoints.nextCaptureTime = HudTimer:GetGameTime() + CAPTURE_FIRST_WARN

  self.currentCapture = {
    y = 1
  }
  Notifications:TopToAll({text="#capturepoints_imminent_warning", duration=3.0, style={color="red", ["font-size"]="70px"}, replacement_map={seconds_to_cp = CAPTURE_FIRST_WARN}})
  self:MinimapPing(5)
  Timers:CreateTimer(CAPTURE_FIRST_WARN - CAPTURE_SECOND_WARN, function ()
    Notifications:TopToAll({text="#capturepoints_imminent_warning", duration=3.0, style={color="red", ["font-size"]="70px"}, replacement_map={seconds_to_cp = CAPTURE_SECOND_WARN}})
    self:MinimapPing(5)
  end)

  for index = 0,(CAPTURE_START_COUNTDOWN - 1) do
    Timers:CreateTimer(CAPTURE_FIRST_WARN - CAPTURE_START_COUNTDOWN + index, function ()
      Notifications:TopToAll({text=(CAPTURE_START_COUNTDOWN - index), duration=1.0})
    end)
  end

  Timers:CreateTimer(CAPTURE_FIRST_WARN, function ()
    self:ActuallyStartCapture()
    CapturePoints.nextCaptureTime = HudTimer:GetGameTime() + CAPTURE_INTERVAL + CAPTURE_FIRST_WARN
  end)
end


function CapturePoints:GiveItemToWholeTeam (item, teamId)
  PlayerResource:GetPlayerIDsForTeam(teamId):each(function (playerId)
    local hero = PlayerResource:GetSelectedHeroEntity(playerId)

    if hero then
      hero:AddItemByName(item)
    end
  end)
end

function CapturePoints:Reward(teamId)
  local team = GetShortTeamName(teamId)
  if not IsPlayerTeam(teamId) then
    return
  end

  PointsManager:AddPoints(teamId, NumCaptures)

  if NumCaptures == 1 then
    self:GiveItemToWholeTeam("item_upgrade_core", teamId)
  elseif NumCaptures == 2 then
    self:GiveItemToWholeTeam("item_upgrade_core_2", teamId)
  elseif NumCaptures == 3 then
    self:GiveItemToWholeTeam("item_upgrade_core_3", teamId)
  elseif NumCaptures >= 4 then
    self:GiveItemToWholeTeam("item_upgrade_core_4", teamId)
  end

  LiveZones = LiveZones - 1
  if LiveZones <= 0 then
    CapturePoints:EndCapture()
  end
end

function CapturePoints:ActuallyStartCapture()
  LiveZones = 2
  NumCaptures = NumCaptures + 1
  Notifications:TopToAll({text="#capturepoints_start", duration=3.0, style={color="red", ["font-size"]="80px"}})
  self:MinimapPing()
  DebugPrint ('CaptureStarted')
  Start.broadcast(self.currentCapture)

  local leftVector = Vector(CurrentZones.left.x, CurrentZones.left.y, CurrentZones.left.z + 256)
  local rightVector = Vector(CurrentZones.right.x, CurrentZones.right.y, CurrentZones.right.z + 256)

  -- Create under spectator team so that spectators can always see the capture point
  local capturePointThinker1 = CreateModifierThinker(nil, nil, "modifier_standard_capture_point", nil, leftVector, DOTA_TEAM_SPECTATOR, false)
  local capturePointModifier1 = capturePointThinker1:FindModifierByName("modifier_standard_capture_point")
  capturePointModifier1:SetCallback(partial(self.Reward, self))
  -- Give the thinker some vision so that spectators can always see the capture point
  capturePointThinker1:SetDayTimeVisionRange(1)
  capturePointThinker1:SetNightTimeVisionRange(1)

  local capturePointThinker2 = CreateModifierThinker(nil, nil, "modifier_standard_capture_point", nil,  rightVector, DOTA_TEAM_SPECTATOR, false)
  local capturePointModifier2 = capturePointThinker2:FindModifierByName("modifier_standard_capture_point")
  capturePointModifier2:SetCallback(partial(self.Reward, self))
  -- Give the thinker some vision so that spectators can always see the capture point
  capturePointThinker2:SetDayTimeVisionRange(1)
  capturePointThinker2:SetNightTimeVisionRange(1)
end

function CapturePoints:EndCapture ()
  if self.currentCapture == nil then
    DebugPrint ('There is no Capture running')
    return
  end
  Notifications:TopToAll({text="#capturepoints_end", duration=3.0, style={color="blue", ["font-size"]="110px"}})
  DebugPrint('Capture Point has ended')
  CaptureFinished.broadcast(self.currentCapture)
  local currentCapture = self.currentCapture
  self.currentCapture = nil
end
