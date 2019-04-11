-- create module
if Music == nil then
  Debug.EnabledModules['music:music'] = true
  DebugPrint ( 'Creating new Music object.' )
  Music = class({})
end

local backgroundTimer = nil

-- Initialize
function Music:Init ()
  DebugPrint('Init music')
  Music.currentTrack = ""
  -- Set everyone unmuted
  local muteTable = {}
  PlayerResource:GetAllTeamPlayerIDs():each(function(playerID)
    muteTable[playerID] = 0
  end)
  CustomNetTables:SetTableValue('music', 'mute', muteTable)
  --to recompile all music

  ChatCommand:LinkDevCommand("-compile_music", Dynamic_Wrap(Music, "Recompile"), Music)
  -- register mute button receiver
  CustomGameEventManager:RegisterListener("music_mute", Dynamic_Wrap(self, "MuteHandler"))
  -- Start first song
  Music:PlayBackground(1, 7)
end

-- Play song command
-- USAGE: Music:SetMusic(i)
-- i = number from music_list
function Music:SetMusic(itemnumber)
  return Music:PlayBackground(itemnumber, itemnumber)
end

-- Play backgrouhnd Song
-- USAGE: Music:SetMusic(i, j)
-- i = start number from music_list
-- j = end number from list
function Music:PlayBackground(start, stop)
  local itemnumber = RandomInt(start, stop)
  DebugPrint('Playing' .. itemnumber)
  -- If player is not muted, stop his current song and play new one for him
  PlayerResource:GetAllTeamPlayerIDs():each(function(playerID)
    local muteTable = CustomNetTables:GetTableValue('music', 'mute')
    local splayerID = tostring(playerID)
    if not muteTable[splayerID] or muteTable[splayerID] == 0 then
      StopSoundOn(Music.currentTrack, PlayerResource:GetPlayer(playerID))
      EmitSoundOnClient(MusicList[itemnumber][2], PlayerResource:GetPlayer(playerID))
    end
  end)
  if backgroundTimer then
    Timers:RemoveTimer(backgroundTimer)
    backgroundTimer = nil
  end
  if MusicList[itemnumber][4] then
    backgroundTimer = Timers:CreateTimer(MusicList[itemnumber][4], function()
      Music:PlayBackground(start, stop)
    end)
  end
  -- Update current song
  Music.currentTrack = MusicList[itemnumber][2]
  -- Send its name to clients
  CustomNetTables:SetTableValue("music", "info", { title = MusicList[itemnumber][1], subtitle = MusicList[itemnumber][3] })
end

-- match has ended, set music for winners/losers
function Music:FinishMatch(teamID)
  local itemnumber = 10
  DebugPrint('Playing' .. itemnumber)
  if backgroundTimer then
    Timers:RemoveTimer(backgroundTimer)
    backgroundTimer = nil
  end

  PlayerResource:GetAllTeamPlayerIDs():each(function(playerID)
    StopSoundOn(Music.currentTrack, PlayerResource:GetPlayer(playerID))
    if PlayerResource:GetPlayer(playerID) and PlayerResource:GetPlayer(playerID):GetTeam() == teamID then
      -- team won
      EmitSoundOnClient(MusicList[itemnumber+1][2], PlayerResource:GetPlayer(playerID))
    else
      --team lost
      EmitSoundOnClient(MusicList[itemnumber][2], PlayerResource:GetPlayer(playerID))
    end
  end)

  -- Update current song
  Music.currentTrack = MusicList[itemnumber][2]
  -- Send its name to clients
  CustomNetTables:SetTableValue("music", "info", { title = MusicList[itemnumber][1], subtitle = MusicList[itemnumber][3] })
end

-- Receives mute requests
function Music:MuteHandler(keys)
  local playerID = keys.PlayerID
  DebugPrintTable(keys)
  --sets his state
  local muteTable = CustomNetTables:GetTableValue('music', 'mute')
  muteTable[tostring(playerID)] = keys.mute
  CustomNetTables:SetTableValue('music', 'mute', muteTable)
  if keys.mute == 1 then
    -- stops song if he muted
    StopSoundOn(Music.currentTrack, PlayerResource:GetPlayer(playerID))
  else
    -- play it again, if he unmuted
    EmitSoundOnClient(Music.currentTrack, PlayerResource:GetPlayer(playerID))
  end
end

-- Receives mute requests
function Music:Recompile(keys)
  for key,value in pairs(MusicList) do
    DebugPrint('Playing' .. key)
    EmitSoundOnClient(MusicList[key][2], PlayerResource:GetPlayer(0))
  end
end
