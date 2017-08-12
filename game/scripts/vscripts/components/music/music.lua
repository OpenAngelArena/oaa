if Music == nil then
  Debug.EnabledModules['music:music'] = true
  DebugPrint ( 'Creating new Music object.' )
  Music = class({})
end

function Music:Init ()
  DebugPrint('Init music')
  PlayerResource:GetAllTeamPlayerIDs():each(function(playerID)
    CustomNetTables:SetTableValue('music', 'mute', {playerID = 0})
  end)
  CustomGameEventManager:RegisterListener("music_mute", Dynamic_Wrap(self, "MuteHandler"))
  Music:SetMusic("valve_dota_001.music.ui_world_map", "by VALVe")
end

function Music:SetMusic(title, subtitle)
  Music.currentTrack = title

  PlayerResource:GetAllTeamPlayerIDs():each(function(playerID)
    if CustomNetTables:GetTableValue('music', 'mute').playerID == 0 then
      EmitSoundOnClient(title, PlayerResource:GetPlayer(playerID))
    end
  end)

  --StopSoundOn
  CustomNetTables:SetTableValue("music", "info", { title = title, subtitle = subtitle })
end

function Music:MuteHandler(keys)
  playerID = keys.playerID
  CustomNetTables:SetTableValue('music', 'mute', {playerID = keys.mute})
  StopSoundOn(Music.currentTrack, PlayerResource:GetPlayer(playerID))
end
