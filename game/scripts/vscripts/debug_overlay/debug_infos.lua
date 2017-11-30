
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
  DebugOverlay:AddGroup("root", {
    Name = "PlayerList",
    DisplayName = "Players",
    Color = "#FFFF00"
  })
  PlayerResource:GetAllTeamPlayerIDs():each(function(playerID)
    local groupName = "Player" .. playerID
    local function addPlayerValue (name, value)
      DebugOverlay:AddEntry(groupName, {
        Name = groupName .. name,
        DisplayName = name,
        Value = value
      })
    end
    DebugOverlay:AddGroup("PlayerList", {
      Name = groupName,
      DisplayName = "Player " .. playerID
    })
    addPlayerValue("Name", PlayerResource:GetPlayerName(playerID))
    addPlayerValue("SteamID", PlayerResource:GetSteamID(playerID))
    addPlayerValue("Hero", PlayerResource:GetSelectedHeroName(playerID))
    addPlayerValue("Level", 0)
    Timers:CreateTimer(0, function()
      DebugOverlay:Update(groupName .. "Level", {
        Value = PlayerResource:GetLevel(playerID),
        forceUpdate = true
      })
      return 5
    end)
  end)
end
