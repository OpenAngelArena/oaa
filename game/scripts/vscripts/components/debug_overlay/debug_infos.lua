
if DebugInfos == nil then
  DebugPrint( 'creating new DebugInfos object' )
  DebugInfos = class({})
end

function DebugInfos:Init()
  -- Map
  DebugOverlay:AddGroup("root", {
    Name = "Map",
    DisplayName = "Map"
  })
  DebugOverlay:AddEntry("Map", {
    Name = "MapName",
    DisplayName = "Name",
    Value = GetMapName()
  })
  DebugOverlay:AddEntry("Map", {
    Name = "MapBounds",
    DisplayName = "Boundaries",
    Value = GetWorldMinX() .. "," .. GetWorldMinY() .. ":" .. GetWorldMaxX() .. "," .. GetWorldMaxY()
  })
  DebugOverlay:AddEntry("Map", {
    Name = "MapDimensions",
    DisplayName = "Dimensions",
    Value = math.abs(GetWorldMinX()) + math.abs(GetWorldMaxX()) .. "," .. math.abs(GetWorldMinY()) + math.abs(GetWorldMaxY())
  })
  -- Game
  DebugOverlay:AddGroup("root", {
    Name = "Game",
    DisplayName = "Game"
  })
  DebugOverlay:AddEntry("Game", {
    Name = "RealTime",
    DisplayName = "Time",
    Value = GetSystemDate() .. " " .. GetSystemTime()
  })
  DebugOverlay:AddEntry("Game", {
    Name = "ServerTime",
    DisplayName = "Server Time",
    Value = Time()
  })
  DebugOverlay:AddEntry("Game", {
    Name = "FrameTime",
    DisplayName = "Frame Time",
    Value = FrameTime(),
    autoUpdate = true,
    updateCallback = function () return FrameTime() end
  })
  DebugOverlay:AddEntry("Game", {
    Name = "GameLength",
    DisplayName = "Game Length",
    Value = GameRules.GameLength
  })
  DebugOverlay:AddEntry("Game", {
    Name = "GameTime",
    DisplayName = "Game Time",
    Value = GameRules:GetGameTime(),
    autoUpdate = true,
    updateCallback = function () return GameRules:GetGameTime() end
  })
  DebugOverlay:AddEntry("Game", {
    Name = "GameDOTATime",
    DisplayName = "Game DOTA Time",
    Value = GameRules:GetDOTATime(true, true),
    autoUpdate = true,
    updateCallback = function () return GameRules:GetDOTATime(true, true) end
  })
  -- Teams
  DebugOverlay:AddGroup("root", {
    Name = "TeamList",
    DisplayName = "Team",
  })
  for teamID=DOTA_TEAM_GOODGUYS,DOTA_TEAM_BADGUYS do
    local groupName = "Team" .. teamID
    local function addEntry(name, value)
      DebugOverlay:AddEntry(groupName, {
        Name = groupName .. name,
        DisplayName = name,
        Value = value,
      })
    end
    local function addUpdaterEntry(name, value, callback)
      DebugOverlay:AddEntry(groupName, {
        Name = groupName .. name,
        DisplayName = name,
        Value = value,
        autoUpdate = true,
        updateCallback = callback
      })
    end

    DebugOverlay:AddGroup("TeamList", {
      Name = groupName,
      DisplayName = "Team " .. teamID .. ", the " .. GetShortTeamName(teamID)
    })

    addEntry("Name", GetTeamName(teamID))
    addUpdaterEntry("Kills", 0, function ()
      return GetTeamHeroKills(teamID)
    end)
    addUpdaterEntry("Points", 0, function()
      return PointsManager:GetPoints(teamID)
    end)

  end
  -- players
  DebugOverlay:AddGroup("root", {
    Name = "PlayerList",
    DisplayName = "Players",
    Color = "#FFFF00"
  })
  PlayerResource:GetAllTeamPlayerIDs():each(function(playerID)
    local groupName = "Player" .. playerID
    -- Add player value entry
    local function addEntry(name, value)
      DebugOverlay:AddEntry(groupName, {
        Name = groupName .. name,
        DisplayName = name,
        Value = value,
      })
    end
    -- Add player value entry with auto updater
    local function addUpdaterEntry(name, value, callback)
      DebugOverlay:AddEntry(groupName, {
        Name = groupName .. name,
        DisplayName = name,
        Value = value,
        autoUpdate = true,
        updateCallback = callback
      })
    end

    DebugOverlay:AddGroup("PlayerList", {
      Name = groupName,
      DisplayName = "Player " .. playerID
    })

    addEntry("Name", PlayerResource:GetPlayerName(playerID))
    addEntry("SteamID", PlayerResource:GetSteamID(playerID))
    addEntry("Hero", PlayerResource:GetSelectedHeroName(playerID))
    addUpdaterEntry("Level", 0, function ()
      return PlayerResource:GetLevel(playerID)
    end)
    addUpdaterEntry("Bottles", 0, function ()
      return BottleCounter:GetBottles(playerID)
    end)
    addUpdaterEntry("Gold", 0, function ()
      return Gold:GetGold(playerID)
    end)
    addUpdaterEntry("KillStreak", 0, function ()
      return PlayerResource:GetSelectedHeroEntity(playerID):GetStreak()
    end)
  end)
end
