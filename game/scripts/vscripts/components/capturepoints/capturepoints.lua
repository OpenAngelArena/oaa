LinkLuaModifier("modifier_oaa_thinker", "modifiers/modifier_oaa_thinker.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_standard_capture_point", "modifiers/modifier_standard_capture_point.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_standard_capture_point_dummy_stuff", "modifiers/modifier_standard_capture_point_dummy_stuff.lua", LUA_MODIFIER_MOTION_NONE)

CAPTUREPOINT_IS_STARTING = 60
CapturePoints = CapturePoints or class({})

-- local Zones = {
  -- { left = Vector( -1280, -1000, 0), right = Vector( 1280, 1000, 0) }, --Zones
  -- { left = Vector( -1920, -768, 0), right = Vector( 1920, 768, 0) },
  -- { left = Vector( -2176, -384, 0), right = Vector( 2176, 384, 0) },
  -- { left = Vector( -960, -1280, 0), right = Vector( 1152, 1180, 0) },
  -- { left = Vector( -640, -1664, 0), right = Vector( 640, 1800, 0) },
  -- { left = Vector( -2048, -1408, 0), right = Vector( 1792, 1280, 0) },
  -- { left = Vector( -2304, -2048, 0), right = Vector( 2304, 2048, 0) },  -- in the stairs
  -- { left = Vector( -1700, -2300, 0), right = Vector( 1920, 1920, 0) },
  -- { left = Vector( -1408, -3200, 128), right = Vector( 1408, 3200, 128) },
  -- { left = Vector( -2492, -3216, 128), right = Vector( 1892, 3016, 128) },
  -- { left = Vector( -2304, -2944, 128), right = Vector( 2304, 2944, 128) },
  -- { left = Vector( -1566, -3584, 128), right = Vector( 1566, 3584, 128) },
  -- { left = Vector( -1152, -4096, 128), right = Vector( 1152, 4096, 128) },
  -- { left = Vector( -2650, -3072, 128), right = Vector( 2650, 3072, 128) },
  -- { left = Vector( -3584, -3072, 128), right = Vector( 3496, 3072, 128) },
  -- { left = Vector( -4992, -3200, 128), right = Vector( 4992, 3200, 128) },
  -- { left = Vector( -2047, 670, 0), right = Vector( 2052, -625, 0) },
  -- { left = Vector( -1920, 768, 0), right = Vector( 1920, -768, 0) },  -- same as the second one
  -- { left = Vector( -2176, 384, 0), right = Vector( 2176, -384, 0) },
  -- { left = Vector( -1024, 1280, 0), right = Vector( 1152, -1280, 0) },
  -- { left = Vector( -1024, 1664, 0), right = Vector( 1024, -1664, 0) },
  -- { left = Vector( -1664, 1280, 0), right = Vector( 2192, -1380, 0) },
  -- { left = Vector( -1726, 1924, 0), right = Vector( 1798, -2007, 0) },
  -- { left = Vector( -1664, 1920, 0), right = Vector( 1664, -1920, 0) },
  -- { left = Vector( -1408, 3200, 128), right = Vector( 1408, -3200, 128) },
  -- { left = Vector( -1792, 2816, 128), right = Vector( 2000, -2816, 128) },
  -- { left = Vector( -2304, 2944, 128), right = Vector( 2304, -2944, 128) },
  -- { left = Vector( -1566, 3584, 128), right = Vector( 1566, -3584, 128) },
  -- { left = Vector( -1152, 4096, 128), right = Vector( 1152, -4096, 128) },
  -- { left = Vector( -3121, 3885, 128), right = Vector( 2709, -3830, 128) },
  -- { left = Vector( -3584, 3072, 128), right = Vector( 3363, -3228, 128) },
  -- { left = Vector( -4992, 3200, 128), right = Vector( 4992, -3200, 128) }}

--local NumZones = 32
local LiveZones = 0
local Start = Event()
local PrepareCapture = Event()
local CaptureFinished = Event()
--local CurrentZones = {}
CapturePoints.onPreparing = PrepareCapture.listen
CapturePoints.onStart = Start.listen
CapturePoints.onEnd = CaptureFinished.listen

function CapturePoints:Init ()
  -- Debug.EnableDebugging()
  DebugPrint('Init capture point')
  self.moduleName = "CapturePoints"

  self.currentCapture = nil
  self.NumCaptures = 0
  self.CapturePointLocation = Vector(0, 0, 0)

  self.nextCaptureTime = self:GetInitialDelay()
  self.CaptureLocationSearchDuration = 20

  local captureWarningTime = self.nextCaptureTime - 60
  local captureSearchStartTime = captureWarningTime - self.CaptureLocationSearchDuration

  HudTimer:At(captureSearchStartTime, function ()
    CapturePoints:StartSearchingForCaptureLocation()
  end)

  HudTimer:At(captureWarningTime, function ()
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

--Pings Minimap about zones
function CapturePoints:MinimapPing()
  local location = self.CapturePointLocation -- CurrentZones.left
  --Timers:CreateTimer(3.2, function ()
    --Minimap:SpawnCaptureIcon(CurrentZones.right)
  --end)
  Minimap:SpawnCaptureIcon(location)
  for playerId = 0, DOTA_MAX_TEAM_PLAYERS-1 do
    if PlayerResource:IsValidPlayerID(playerId) then
      local player = PlayerResource:GetPlayer(playerId)
      if player and not player:IsNull() then
        if player:GetAssignedHero() then
          if player:GetTeam() == DOTA_TEAM_BADGUYS then
            MinimapEvent(DOTA_TEAM_BADGUYS, player:GetAssignedHero(), location.x, location.y, DOTA_MINIMAP_EVENT_HINT_LOCATION, 3)
            --Timers:CreateTimer(3.2, function ()
              --if player and not player:IsNull() then
                --MinimapEvent(DOTA_TEAM_BADGUYS, player:GetAssignedHero(), CurrentZones.right.x, CurrentZones.right.y, DOTA_MINIMAP_EVENT_HINT_LOCATION , 3)
              --end
            --end)
          else
            MinimapEvent(DOTA_TEAM_GOODGUYS, player:GetAssignedHero(), location.x, location.y, DOTA_MINIMAP_EVENT_HINT_LOCATION, 3)
            --Timers:CreateTimer(3.2, function ()
              --if player and not player:IsNull() then
                --MinimapEvent(DOTA_TEAM_GOODGUYS, player:GetAssignedHero(), CurrentZones.right.x, CurrentZones.right.y, DOTA_MINIMAP_EVENT_HINT_LOCATION , 3)
              --end
            --end)
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

  local captureInterval = self:GetCapturePointIntervalTime()
  local captureSearchStartTime = captureInterval - self.CaptureLocationSearchDuration

  self.nextCaptureTime = HudTimer:GetGameTime() + captureInterval + CAPTURE_FIRST_WARN

  Timers:CreateTimer(captureSearchStartTime, function ()
    CapturePoints:StartSearchingForCaptureLocation()
  end)

  self.scheduleCaptureTimer = Timers:CreateTimer(captureInterval, function ()
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
  --CurrentZones = Zones[RandomInt(1, NumZones)]

  -- If statemant checks for duel interference
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
    CapturePoints:ActuallyStartCapture()
    CapturePoints.nextCaptureTime = HudTimer:GetGameTime() + CapturePoints:GetCapturePointIntervalTime() + CAPTURE_FIRST_WARN
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
  LiveZones = 1
  self.NumCaptures = self.NumCaptures + 1
  Notifications:TopToAll({text="#capturepoints_start", duration=3.0, style={color="red", ["font-size"]="80px"}})
  self:MinimapPing()
  DebugPrint ('CaptureStarted')
  Start.broadcast(self.currentCapture)

  local location = self.CapturePointLocation
  local spawnVector = GetGroundPosition(Vector(location.x, location.y, location.z + 384), nil)
  --local leftVector = GetGroundPosition(Vector(CurrentZones.left.x, CurrentZones.left.y, CurrentZones.left.z + 384), nil)
  --local rightVector = GetGroundPosition(Vector(CurrentZones.right.x, CurrentZones.right.y, CurrentZones.right.z + 384), nil)

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

  local closer_fountain = radiant_fountain
  if self:DistanceFromFountain(spawnVector, DOTA_TEAM_BADGUYS) < self:DistanceFromFountain(spawnVector, DOTA_TEAM_GOODGUYS) then
    closer_fountain = dire_fountain
  end

  local capture_point = CreateUnitByName("npc_dota_custom_dummy_unit", spawnVector, false, nil, nil, DOTA_TEAM_SPECTATOR)
  capture_point:AddNewModifier(closer_fountain, nil, "modifier_oaa_thinker", {})
  local capturePointModifier = capture_point:AddNewModifier(closer_fountain, nil, "modifier_standard_capture_point", {})
  capturePointModifier:SetCallback(partial(self.Reward, self))

  -- Give the capture_point some vision so that spectators can always see the capture point
  capture_point:SetDayTimeVisionRange(1)
  capture_point:SetNightTimeVisionRange(1)

  local isGoodLead = PointsManager:GetPoints(DOTA_TEAM_GOODGUYS) > PointsManager:GetPoints(DOTA_TEAM_BADGUYS)

  if not isGoodLead then
    -- Give vision to the Radiant team with a dummy unit
    self.radiant_dummy = CreateUnitByName("npc_dota_custom_dummy_unit", spawnVector, false, radiant_fountain, radiant_fountain, DOTA_TEAM_GOODGUYS)
    self.radiant_dummy:AddNewModifier(radiant_fountain, nil, "modifier_standard_capture_point_dummy_stuff", {})
  else
    -- Give vision to the Dire team with a dummy unit
    self.dire_dummy = CreateUnitByName("npc_dota_custom_dummy_unit", spawnVector, false, dire_fountain, dire_fountain, DOTA_TEAM_BADGUYS)
    self.dire_dummy:AddNewModifier(dire_fountain, nil, "modifier_standard_capture_point_dummy_stuff", {})
  end

  --local radiant_capture_point = CreateUnitByName("npc_dota_custom_dummy_unit", leftVector, false, nil, nil, DOTA_TEAM_SPECTATOR)
  --radiant_capture_point:AddNewModifier(radiant_fountain, nil, "modifier_oaa_thinker", {})
  --local capturePointModifier1 = radiant_capture_point:AddNewModifier(radiant_fountain, nil, "modifier_standard_capture_point", {})
  --capturePointModifier1:SetCallback(partial(self.Reward, self))

  -- Give the radiant_capture_point some vision so that spectators can always see the capture point
  --radiant_capture_point:SetDayTimeVisionRange(1)
  --radiant_capture_point:SetNightTimeVisionRange(1)

  -- Give vision to the Radiant team with a dummy unit
  --self.radiant_dummy = CreateUnitByName("npc_dota_custom_dummy_unit", leftVector, false, radiant_fountain, radiant_fountain, DOTA_TEAM_GOODGUYS)
  --self.radiant_dummy:AddNewModifier(radiant_fountain, nil, "modifier_standard_capture_point_dummy_stuff", {})

  --local dire_capture_point = CreateUnitByName("npc_dota_custom_dummy_unit", rightVector, false, nil, nil, DOTA_TEAM_SPECTATOR)
  --dire_capture_point:AddNewModifier(dire_fountain, nil, "modifier_oaa_thinker", {})
  --local capturePointModifier2 = dire_capture_point:AddNewModifier(dire_fountain, nil, "modifier_standard_capture_point", {})
  --capturePointModifier2:SetCallback(partial(self.Reward, self))

  -- Give the dire_capture_point some vision so that spectators can always see the capture point
  --dire_capture_point:SetDayTimeVisionRange(1)
  --dire_capture_point:SetNightTimeVisionRange(1)

  -- Give vision to the Dire team with a dummy unit
  --self.dire_dummy = CreateUnitByName("npc_dota_custom_dummy_unit", rightVector, false, dire_fountain, dire_fountain, DOTA_TEAM_BADGUYS)
  --self.dire_dummy:AddNewModifier(dire_fountain, nil, "modifier_standard_capture_point_dummy_stuff", {})
end

function CapturePoints:EndCapture()
  if self.currentCapture == nil then
    DebugPrint ('There is no Capture running')
    return
  end
  Notifications:TopToAll({text="#capturepoints_end", duration=3.0, style={color="blue", ["font-size"]="110px"}})
  DebugPrint('Capture Point has ended')
  CaptureFinished.broadcast(self.currentCapture)
  self.currentCapture = nil

  -- Remove vision over capture points
  if self.radiant_dummy and not self.radiant_dummy:IsNull() then
    self.radiant_dummy:ForceKillOAA(false)
  end
  if self.dire_dummy and not self.dire_dummy:IsNull() then
    self.dire_dummy:ForceKillOAA(false)
  end
end

function CapturePoints:StartSearchingForCaptureLocation()
  local defaultPosition = Vector(0, 0, 0)
  local maxDistanceFromFountain = self:DistanceFromFountain(defaultPosition, DOTA_TEAM_GOODGUYS) -- 6656
  --print("maxDistanceFromFountain is : "..tostring(maxDistanceFromFountain))
  local minDistanceFromFountain = 800 -- X: 6206
  local maxY = 4100
  local maxX = maxDistanceFromFountain - 500 -- 6156
  local minY = 0
  local minX = 0

  local scoreDiff = math.abs(PointsManager:GetPoints(DOTA_TEAM_GOODGUYS) - PointsManager:GetPoints(DOTA_TEAM_BADGUYS))
  local isGoodLead = PointsManager:GetPoints(DOTA_TEAM_GOODGUYS) > PointsManager:GetPoints(DOTA_TEAM_BADGUYS)

  if scoreDiff >= 20 then
    maxDistanceFromFountain = maxDistanceFromFountain / 3.8 -- 1751.58 -> X: 4904.22
    minX = math.floor(maxX * 4 / 5) -- 4924
  elseif scoreDiff >= 15 then
    minDistanceFromFountain = maxDistanceFromFountain / 5 -- 1331.2 -> X: 5324.8
    maxDistanceFromFountain = maxDistanceFromFountain / 1.5 -- 4437.34 -> X: 2218.67
    minX = math.floor(maxX * 2 / 5) -- 2462
    maxX = math.ceil(maxX * 4 / 5)  -- 4925
  elseif scoreDiff >= 10 then
    minDistanceFromFountain = maxDistanceFromFountain / 1.7 -- 3915.3 -> X: 2740.7
    maxDistanceFromFountain = maxDistanceFromFountain / 1.2 -- 5546.67 -> X: 1109.34
    minX = math.floor(maxX / 5) -- 1231
    maxX = math.ceil(maxX * 2 / 5)  -- 2462
  elseif scoreDiff >= 5 then
    minDistanceFromFountain = maxDistanceFromFountain / 1.25 -- 5324.8 -> X: 1331.2
    maxX = math.ceil(maxX / 5) -- 1232
  else
    minX = 0
    maxX = 0
  end

  defaultPosition = Vector(math.floor((minX + maxX) / 2), minY, 0)
  if not isGoodLead then
    defaultPosition.x = 0 - defaultPosition.x
  end

  local loopCount = 0
  local maxSearchDuration = self.CaptureLocationSearchDuration
  local searchInterval = 2 -- depends how long FindBestCapturePointLocation lasts and that depends mostly on duration of DistanceFromFountain and IsZonePathable checks
  local maxLoops = math.floor(maxSearchDuration / searchInterval) - 1

  Timers:CreateTimer(function ()
    local position = CapturePoints:FindBestCapturePointLocation(minX, maxX, minY, maxY, minDistanceFromFountain, maxDistanceFromFountain, isGoodLead)

    loopCount = loopCount + 1

    if not position and loopCount < maxLoops then
      return searchInterval -- repeat FindBestCapturePointLocation every searchInterval seconds
    end

    if loopCount == maxLoops then
      DebugPrint('Couldnt find a valid capture point location, using default...')
      position = defaultPosition
    else
      DebugPrint('Found capture point location after ' .. loopCount .. ' tries')
    end

    CapturePoints.CapturePointLocation = position
  end)
end

function CapturePoints:FindBestCapturePointLocation(minX, maxX, minY, maxY, minDistance, maxDistance, isGoodLead)
  local fountainTeam = DOTA_TEAM_GOODGUYS
  if isGoodLead then
    fountainTeam = DOTA_TEAM_BADGUYS
  end

  local position = Vector(RandomInt(minX, maxX), RandomInt(minY, maxY), 100)
  if RandomInt(0, 1) == 0 then
    position.y = 0 - position.y
  end
  if not isGoodLead then
    position.x = 0 - position.x
  end

  if self:DistanceFromFountain(position, fountainTeam) >= maxDistance or self:DistanceFromFountain(position, fountainTeam) <= minDistance or not self:IsZonePathable(position) then
    return nil
  end

  return position
end

function CapturePoints:IsLocationInFountain(location)
  if not location then
    return nil
  end

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

  local radiant_fountain_trigger = Entities:FindByName(nil, "fountain_good_trigger")
  local dire_fountain_trigger = Entities:FindByName(nil, "fountain_bad_trigger")

  if radiant_fountain_trigger then
    if IsInTrigger(location, radiant_fountain_trigger) then
      return true
    end
  else
    print("Radiant fountain trigger not found or referenced name is wrong.")
    if radiant_fountain then
      if (radiant_fountain:GetAbsOrigin() - location):Length2D() <= 400 then
        return true
      end
    end
  end

  if dire_fountain_trigger then
    if IsInTrigger(location, dire_fountain_trigger) then
      return true
    end
  else
    print("Dire fountain trigger not found or referenced name is wrong.")
    if dire_fountain then
      if (dire_fountain:GetAbsOrigin() - location):Length2D() <= 400 then
        return true
      end
    end
  end

  return false
end

function CapturePoints:DistanceFromFountain(location, team)
  if not location or not team then
    return nil
  end
  local fountains = Entities:FindAllByClassname("ent_dota_fountain")
  local fountain
  for _, entity in pairs(fountains) do
    if entity:GetTeamNumber() == team then
      fountain = entity
    end
  end
  if not fountain then
    return nil
  end

  return (fountain:GetAbsOrigin() - location):Length2D()
end

function CapturePoints:IsZonePathable(location)
  local zone_radius = CAPTURE_POINT_RADIUS or 300
  local zone_center = location
  local counter = 0
  local pathable_points = math.floor(math.pi * zone_radius^2)
  local min_pathable_points = pathable_points * 75/100
  for i = 1, zone_radius do
    for j = 1, zone_radius do
      local pos1 = GetGroundPosition(Vector(zone_center.x + i, zone_center.y + j, 384), nil)
      local pos2 = GetGroundPosition(Vector(zone_center.x + i, zone_center.y - j, 384), nil)
      local pos3 = GetGroundPosition(Vector(zone_center.x - i, zone_center.y + j, 384), nil)
      local pos4 = GetGroundPosition(Vector(zone_center.x - i, zone_center.y - j, 384), nil)
      if (pos1.x - zone_center.x)^2 + (pos1.y - zone_center.y)^2 <= zone_radius^2 then
        -- pos1 is inside the circle
        if not GridNav:IsBlocked(pos1) and GridNav:IsTraversable(pos1) then
          counter = counter + 1
        end
      end
      if (pos2.x - zone_center.x)^2 + (pos2.y - zone_center.y)^2 <= zone_radius^2 then
        -- pos2 is inside the circle
        if not GridNav:IsBlocked(pos2) and GridNav:IsTraversable(pos2) then
          counter = counter + 1
        end
      end
      if (pos3.x - zone_center.x)^2 + (pos3.y - zone_center.y)^2 <= zone_radius^2 then
        -- pos3 is inside the circle
        if not GridNav:IsBlocked(pos3) and GridNav:IsTraversable(pos3) then
          counter = counter + 1
        end
      end
      if (pos4.x - zone_center.x)^2 + (pos4.y - zone_center.y)^2 <= zone_radius^2 then
        -- test_pos is inside the circle
        if not GridNav:IsBlocked(pos4) and GridNav:IsTraversable(pos4) then
          counter = counter + 1
        end
      end

      if counter >= min_pathable_points then
        break
      end
    end
    if counter >= min_pathable_points then
      break
    end
  end

  if counter >= min_pathable_points then
    return true
  end

  return false
end

function CapturePoints:GetInitialDelay()
  if CAPTURE_POINTS_AND_DUELS_NO_OVERLAP then
    if Duels then
      return Duels:GetDuelTimeout(1) + Duels:GetDuelIntervalTime() + Duels:GetDuelTimeout() + 10
    else
      if GetMapName() == "1v1" then
        return ONE_V_ONE_DUEL_TIMEOUT + ONE_V_ONE_DUEL_INTERVAL + ONE_V_ONE_DUEL_TIMEOUT + 10
      end
      return FIRST_DUEL_TIMEOUT + DUEL_INTERVAL + DUEL_TIMEOUT + 10
    end
  end

  if GetMapName() == "1v1" then
    return ONE_V_ONE_INITIAL_CAPTURE_POINT_DELAY
  end

  return INITIAL_CAPTURE_POINT_DELAY
end

function CapturePoints:GetCapturePointIntervalTime()
  if CAPTURE_POINTS_AND_DUELS_NO_OVERLAP then
    if Duels then
      return Duels:GetDuelIntervalTime()
    else
      if GetMapName() == "1v1" then
        return ONE_V_ONE_DUEL_INTERVAL
      end
      return DUEL_INTERVAL
    end
  end

  if GetMapName() == "1v1" then
    return ONE_V_ONE_CAPTURE_INTERVAL
  end

  return CAPTURE_INTERVAL
end
