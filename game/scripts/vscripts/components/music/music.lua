-- create module
if Music == nil then
  Debug.EnabledModules['music:music'] = true
  DebugPrint ( 'Creating new Music object.' )
  Music = class({})
end

-- Initialize
function Music:Init ()
  DebugPrint('Init music')
  Music.currentTrack = ""
  -- Set everyone unmuted
  PlayerResource:GetAllTeamPlayerIDs():each(function(playerID)
    CustomNetTables:SetTableValue('music', 'mute', {playerID = 0})
  end)
  -- register mute button receiver
  CustomGameEventManager:RegisterListener("music_mute", Dynamic_Wrap(self, "MuteHandler"))
  -- Start first song
  Music:SetMusic("valve_dota_001.music.ui_world_map", "by VALVe")
end

-- Play song command
function Music:SetMusic(title, subtitle)

  -- If player is not muted, stop his current song and play new one for him
  PlayerResource:GetAllTeamPlayerIDs():each(function(playerID)
    if CustomNetTables:GetTableValue('music', 'mute').playerID == 0 then
      StopSoundOn(Music.currentTrack, PlayerResource:GetPlayer(playerID))
      EmitSoundOnClient(title, PlayerResource:GetPlayer(playerID))
    end
  end)

  -- Update current song
  Music.currentTrack = title
  -- Send its name to clients
  CustomNetTables:SetTableValue("music", "info", { title = title, subtitle = subtitle })
end

-- Receives mute requests
function Music:MuteHandler(keys)
  local playerID = keys.playerID
  --sets his state
  CustomNetTables:SetTableValue('music', 'mute', {playerID = keys.mute})
  if keys.mute == 1 then
    -- stops song if he muted
    StopSoundOn(Music.currentTrack, PlayerResource:GetPlayer(playerID))
  else
    -- play it again, if he unmuted
    EmitSoundOnClient(Music.currentTrack, PlayerResource:GetPlayer(playerID))
  end
end
