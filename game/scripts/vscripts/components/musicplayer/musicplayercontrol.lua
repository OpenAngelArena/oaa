--[[
  Author:
    Relacibo
]]

if MusicPlayerControl == nil then
  DebugPrint ( '[musicplayer/musicplayercontrol] Creating new MusicPlayerControl object' )
  MusicPlayerControl = class({})
end

function MusicPlayerControl:Init()
  DebugPrint ( '[musicplayer/musicplayercontrol] Initializing.' )
  MusicPlayerControl:InitializePlayer()


  -- Events from hud
  CustomGameEventManager:RegisterListener('musicplayer_toggle', Dynamic_Wrap(MusicPlayerControl, 'OnToggle'))
end

function MusicPlayerControl:NextTrack( playerID )
  MusicPlayerControl.currentTitle = 'Hallo'
  MusicPlayerControl.currentArtist = 'Welt'
  DebugPrint ( '[musicplayer/musicplayercontrol] Changing music to: title:'
  .. MusicPlayerControl.currentTitle .. ', artist:' .. MusicPlayerControl.currentArtist)
end

function MusicPlayerControl:HUDTurnOn( )
  CustomNetTables:SetTableValue( "musicplayer", "player1", {
    musicOn = true,
    title = MusicPlayerControl.currentTitle,
    artist = MusicPlayerControl.currentArtist } )
end

function MusicPlayerControl:HUDTurnOff( )
  CustomNetTables:SetTableValue("musicplayer", "player1", {
    musicOn = false } )
end

function MusicPlayerControl:UpdateHUD( )
  if MusicPlayerControl.isPlaying then
    MusicPlayerControl:HUDTurnOn()
  else
    MusicPlayerControl:HUDTurnOff()
  end
end

function MusicPlayerControl:InitializePlayer( )
  MusicPlayerControl.currentMusicStatus = 0
  MusicPlayerControl.isPlaying = volume == 0
  local volume = Convars:GetFloat("snd_musicvolume")
  MusicPlayerControl:NextTrack()
  MusicPlayerControl:UpdateHUD()
end

function MusicPlayerControl:OnToggle( )

  MusicPlayerControl.isPlaying = not MusicPlayerControl.isPlaying
  if MusicPlayerControl.isPlaying then
    DebugPrint ( '[musicplayer/musicplayercontrol] Toggling music on. ' )
    local volume = MusicPlayerControl.oldVolume or 0.5
    Convars:SetFloat("snd_musicvolume", volume)
  else
    DebugPrint ( '[musicplayer/musicplayercontrol] Toggling music off. ' )
    MusicPlayerControl.oldVolume = Convars:GetFloat("snd_musicvolume")
    Convars:SetFloat("snd_musicvolume", 0.0)
  end
  MusicPlayerControl:UpdateHUD()
end
