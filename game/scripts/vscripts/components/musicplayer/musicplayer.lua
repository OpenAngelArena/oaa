--[[
  Author:
    Relacibo
]]

if MusicPlayer == nil then
  DebugPrint ( '[musicplayer/musicplayer] Creating new Clientside MusicPlayer object.' )
  MusicPlayer = class({})
end

function MusicPlayer:Init()
  DebugPrint ( '[musicplayer/musicplayer] Initializing.' )
  DisableDefaultMusic( )

  PlayerTables:CreateTable('musicplayer_music')
  MusicPlayer:Reset()

  -- Events from hud
  CustomGameEventManager:RegisterListener('musicplayer_toggle', DynamicWrap(MusicPlayer, 'OnToggle'))

  -- Events from Serverside lua - probably
  CustomGameEventManager:RegisterListener('musicplayer_change_music_status', DynamicWrap(MusicPlayer, 'OnChangeMusicStatus'))

end

function MusicPlayer:NextTrack()
  -- TODO: Find next Track, which fits the current music status. Currently only mock.
  PlayerTables:SetTableValue("musicplayer_music", {title='test1', artist='test2'})
end

function MusicPlayer:Reset( )
  MusicPlayer.currentMusicStatus = 0
  MusicPlayer.currentTitle = ''
  MusicPlayer.isPlaying = false
  MusicPlayer:NextTrack()
end

function MusicPlayer:OnToggle( )
  DebugPrint ( '[musicplayer/musicplayer] Toggling music. ' )
  self.isPlaying = !self.isPlaying
  DebugPrint ( '[musicplayer/musicplayer] Is music playing? ' .. self.isPlaying)
  -- TODO: Toggle music on/off
end

function MusicPlayer:OnChangeMusicStatus( newStatus )
  -- TODO: Change musicstatus and change music
end

function DisableDefaultMusic( )
  DebugPrint ( '[musicplayer/musicplayercontrol] Disabling default music on all clients.' )
  -- TODO: Disable default music maybe
  PlayerResource:GetPlayer(i):SetMusicStatus(DOTA_MUSIC_STATUS_NONE, 0.0)
end
