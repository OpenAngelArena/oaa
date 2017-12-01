
if DebugInfos == nil then
  DebugPrint( 'creating new DebugInfos object' )
  DebugInfos = class({})
end

function DebugInfos:Init()
  DebugOverlay:AddEntry("root", {
    Name = "MapName",
    DisplayName = "Map",
    Value = GetMapName()
  })
  DebugOverlay:AddEntry("root", {
    Name = "ServerTime",
    DisplayName = "Server Time",
    Value = GetSystemDate() .. " " .. GetSystemTime()
  })
  DebugOverlay:AddEntry("root", {
    Name = "GameLength",
    DisplayName = "Game Length",
    Value = GameRules.GameLength
  })
  DebugOverlay:AddGroup("root", {
    Name = "PlayerList",
    DisplayName = "Players",
    Color = "#FFFF00"
  })
  PlayerResource:GetAllTeamPlayerIDs():each(function(playerID)
    local groupName = "Player" .. playerID
    -- Add player value entry
    local function addPV(name, value)
      DebugOverlay:AddEntry(groupName, {
        Name = groupName .. name,
        DisplayName = name,
        Value = value,
      })
    end
    -- Add player value entry with auto updater
    local function addPVAU(name, value, callback)
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

    addPV("Name", PlayerResource:GetPlayerName(playerID))
    addPV("SteamID", PlayerResource:GetSteamID(playerID))
    addPV("Hero", PlayerResource:GetSelectedHeroName(playerID))
    addPVAU("Level", 0, function ()
      return PlayerResource:GetLevel(playerID)
    end)
    addPVAU("Bottles", 0, function ()
      return BottleCounter:GetBottles(playerID)
    end)
    addPVAU("Gold", 0, function ()
      return Gold:GetGold(playerID)
    end)
    addPVAU("KillStreak", 0, function ()
      return PlayerResource:GetSelectedHeroEntity(playerID):GetStreak()
    end)
  end)
end
