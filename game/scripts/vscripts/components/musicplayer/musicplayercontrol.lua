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
end

function MusicPlayerControl:ChangeMusicStatus_Player(playerID, newStatus)
  DebugPrint ( '[musicplayer/musicplayercontrol] Changing music status of player ' .. playerID .. ' to ' .. newStatus .. '. ' )
  CustomGameEventManager:Send_ServerToPlayer(PlayerResource:GetPlayer(playerID), 'musicplayer_change_music_status', { newStatus })
end

function MusicPlayerControl:ChangeMusicStatus_Team(teamID, newStatus)
  DebugPrint ( '[musicplayer/musicplayercontrol] Changing music status of team ' .. teamID .. ' to ' .. newStatus .. '. ' )
  CustomGameEventManager:Send_ServerToTeam(teamID, 'musicplayer_change_music_status', { newStatus })
end

function MusicPlayerControl:ChangeMusicStatus_All(newStatus)
  DebugPrint ( '[musicplayer/musicplayercontrol] Changing music status of all players to ' .. newStatus .. '. ' )
  CustomGameEventManager:Send_ServerToAllClients('musicplayer_change_music_status', { newStatus })
end

