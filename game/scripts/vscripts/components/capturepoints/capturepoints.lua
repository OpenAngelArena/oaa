LinkLuaModifier("modifier_oaa_thinker", "modifiers/modifier_oaa_thinker.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_standard_capture_point", "modifiers/modifier_standard_capture_point.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_standard_capture_point_dummy_stuff", "modifiers/modifier_standard_capture_point_dummy_stuff.lua", LUA_MODIFIER_MOTION_NONE)

CAPTUREPOINT_IS_STARTING = 60
CapturePoints = CapturePoints or class({})

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
  self.moduleName = "CapturePoints"

  self.currentCapture = nil
  self.NumCaptures = 0

  CapturePoints.nextCaptureTime = INITIAL_CAPTURE_POINT_DELAY
  HudTimer:At(INITIAL_CAPTURE_POINT_DELAY - 60, function ()
    CapturePoints:ScheduleCapture()
  end)

  -- Add chat commands to force start and end captures
  ChatCommand:LinkDevCommand("-capture", Dynamic_Wrap(self, "ScheduleCapture"), self)
  ChatCommand:LinkDevCommand("-end_capture", Dynamic_Wrap(self, "EndCapture"), self)
end

function CapturePoints:GetState ()
  local state = {}

  state.captures = self.NumCaptures

  return state
end

function CapturePoints:LoadState (state)
  self.NumCaptures = state.captures
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
  for playerId = 0, DOTA_MAX_TEAM_PLAYERS-1 do
    if PlayerResource:IsValidPlayerID(playerId) then
      local player = PlayerResource:GetPlayer(playerId)
      if player and not player:IsNull() then
        if player:GetAssignedHero() then
          if player:GetTeam() == DOTA_TEAM_BADGUYS then
            MinimapEvent(DOTA_TEAM_BADGUYS, player:GetAssignedHero(), CurrentZones.left.x, CurrentZones.left.y, DOTA_MINIMAP_EVENT_HINT_LOCATION, 3)
            Timers:CreateTimer(3.2, function ()
              if player and not player:IsNull() then
                MinimapEvent(DOTA_TEAM_BADGUYS, player:GetAssignedHero(), CurrentZones.right.x, CurrentZones.right.y, DOTA_MINIMAP_EVENT_HINT_LOCATION , 3)
              end
            end)
          else
            MinimapEvent(DOTA_TEAM_GOODGUYS, player:GetAssignedHero(), CurrentZones.left.x, CurrentZones.left.y, DOTA_MINIMAP_EVENT_HINT_LOCATION, 3)
            Timers:CreateTimer(3.2, function ()
              if player and not player:IsNull() then
                MinimapEvent(DOTA_TEAM_GOODGUYS, player:GetAssignedHero(), CurrentZones.right.x, CurrentZones.right.y, DOTA_MINIMAP_EVENT_HINT_LOCATION , 3)
              end
            end)
          end
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
    CapturePoints:ScheduleCapture()
  end)

  if self.currentCapture then
    DebugPrint ('There is already a capture running')
    return
  end

  self.currentCapture = CAPTUREPOINT_IS_STARTING
  Debug:EnableDebugging()
  -- DebugPrint('Capture number... ' .. self.NumCaptures)
  -- Chooses random zone
  CurrentZones = Zones[RandomInt(1, NumZones)]
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
      if CapturePoints.unlistenDuel then
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
  self:MinimapPing()
  Timers:CreateTimer(CAPTURE_FIRST_WARN - CAPTURE_SECOND_WARN, function ()
    Notifications:TopToAll({text="#capturepoints_imminent_warning", duration=3.0, style={color="red", ["font-size"]="70px"}, replacement_map={seconds_to_cp = CAPTURE_SECOND_WARN}})
    CapturePoints:MinimapPing()
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
  if CorePointsManager then
    CorePointsManager:GiveCorePointsToWholeTeam(CorePointsManager:GetCorePointValueOfUpdgradeCore(item), teamId)
  else
    PlayerResource:GetPlayerIDsForTeam(teamId):each(function (playerId)
      local hero = PlayerResource:GetSelectedHeroEntity(playerId)

      if hero then
        hero:AddItemByName(item)
      end
    end)
  end
end

function CapturePoints:Reward(teamId)
  local team = GetShortTeamName(teamId)
  if not IsPlayerTeam(teamId) then
    return
  end

  local pointReWard = math.min(self.NumCaptures + 1, PlayerResource:SafeGetTeamPlayerCount())
  PointsManager:AddPoints(teamId, pointReWard)

  if self.NumCaptures == 1 then
    self:GiveItemToWholeTeam("item_upgrade_core", teamId)
  elseif self.NumCaptures == 2 then
    self:GiveItemToWholeTeam("item_upgrade_core_2", teamId)
  elseif self.NumCaptures == 3 then
    self:GiveItemToWholeTeam("item_upgrade_core_3", teamId)
  elseif self.NumCaptures >= 4 then
    self:GiveItemToWholeTeam("item_upgrade_core_4", teamId)
  end

  LiveZones = LiveZones - 1
  if LiveZones <= 0 then
    CapturePoints:EndCapture()
  end
end

function CapturePoints:ActuallyStartCapture()
  LiveZones = 2
  self.NumCaptures = self.NumCaptures + 1
  Notifications:TopToAll({text="#capturepoints_start", duration=3.0, style={color="red", ["font-size"]="80px"}})
  self:MinimapPing()
  DebugPrint ('CaptureStarted')
  Start.broadcast(self.currentCapture)

  local leftVector = GetGroundPosition(Vector(CurrentZones.left.x, CurrentZones.left.y, CurrentZones.left.z + 384), nil)
  local rightVector = GetGroundPosition(Vector(CurrentZones.right.x, CurrentZones.right.y, CurrentZones.right.z + 384), nil)

  local fountains = Entities:FindAllByClassname("ent_dota_fountain")
  local radiant_fountain
  local dire_fountain
  for _, entity in pairs(fountains) do
    if entity:GetTeamNumber() == DOTA_TEAM_GOODGUYS then
      radiant_fountain = entity
    elseif entity:GetTeamNumber() == DOTA_TEAM_BADGUYS then
      dire_fountain = entity
    end
  end

  --local radiant_capture_point = CreateModifierThinker(nil, nil, "modifier_standard_capture_point", nil, leftVector, DOTA_TEAM_SPECTATOR, false)
  local radiant_capture_point = CreateUnitByName("npc_dota_custom_dummy_unit", leftVector, false, nil, nil, DOTA_TEAM_SPECTATOR)
  radiant_capture_point:AddNewModifier(radiant_fountain, nil, "modifier_oaa_thinker", {})
  --local capturePointModifier1 = radiant_capture_point:FindModifierByName("modifier_standard_capture_point")
  local capturePointModifier1 = radiant_capture_point:AddNewModifier(radiant_fountain, nil, "modifier_standard_capture_point", {})
  capturePointModifier1:SetCallback(partial(self.Reward, self))

  -- Give the radiant_capture_point some vision so that spectators can always see the capture point
  radiant_capture_point:SetDayTimeVisionRange(1)
  radiant_capture_point:SetNightTimeVisionRange(1)

  -- Give vision to the Radiant team with a dummy unit
  self.radiant_dummy = CreateUnitByName("npc_dota_custom_dummy_unit", leftVector, false, radiant_fountain, radiant_fountain, DOTA_TEAM_GOODGUYS)
  self.radiant_dummy:AddNewModifier(radiant_fountain, nil, "modifier_standard_capture_point_dummy_stuff", {})

  --local dire_capture_point = CreateModifierThinker(nil, nil, "modifier_standard_capture_point", nil, rightVector, DOTA_TEAM_SPECTATOR, false)
  local dire_capture_point = CreateUnitByName("npc_dota_custom_dummy_unit", rightVector, false, nil, nil, DOTA_TEAM_SPECTATOR)
  dire_capture_point:AddNewModifier(dire_fountain, nil, "modifier_oaa_thinker", {})
  --local capturePointModifier2 = dire_capture_point:FindModifierByName("modifier_standard_capture_point")
  local capturePointModifier2 = dire_capture_point:AddNewModifier(dire_fountain, nil, "modifier_standard_capture_point", {})
  capturePointModifier2:SetCallback(partial(self.Reward, self))

  -- Give the dire_capture_point some vision so that spectators can always see the capture point
  dire_capture_point:SetDayTimeVisionRange(1)
  dire_capture_point:SetNightTimeVisionRange(1)

  -- Give vision to the Dire team with a dummy unit
  self.dire_dummy = CreateUnitByName("npc_dota_custom_dummy_unit", rightVector, false, dire_fountain, dire_fountain, DOTA_TEAM_BADGUYS)
  self.dire_dummy:AddNewModifier(dire_fountain, nil, "modifier_standard_capture_point_dummy_stuff", {})
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

  -- Remove vision over capture points
  self.radiant_dummy:AddNewModifier(self.radiant_dummy, nil, "modifier_kill", {duration = 0.1})
  self.dire_dummy:AddNewModifier(self.dire_dummy, nil, "modifier_kill", {duration = 0.1})
end
