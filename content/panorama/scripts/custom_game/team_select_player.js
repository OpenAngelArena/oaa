/* global $, Game, DOTATeam_t */

'use strict';

if (typeof module !== 'undefined' && module.exports) {
  module.exports = {
    OnLeaveTeamPressed: OnLeaveTeamPressed
  };
}

// --------------------------------------------------------------------------------------------------
// Handler for when the unssigned players panel is clicked that causes the player to be reassigned
// to the unssigned players team
// --------------------------------------------------------------------------------------------------
function OnLeaveTeamPressed () {
  Game.PlayerJoinTeam(DOTATeam_t.DOTA_TEAM_NOTEAM);
}

// --------------------------------------------------------------------------------------------------
// Update the contents of the player panel when the player information has been modified.
// --------------------------------------------------------------------------------------------------
function OnPlayerDetailsChanged () {
  const playerId = $.GetContextPanel().GetAttributeInt('player_id', -1);
  const playerInfo = Game.GetPlayerInfo(playerId);
  if (!playerInfo) { return; }
  $('#PlayerName').text = playerInfo.player_name;
  $('#PlayerAvatar').steamid = playerInfo.player_steamid;

  $.GetContextPanel().SetHasClass('player_is_local', playerInfo.player_is_local);
  $.GetContextPanel().SetHasClass('player_has_host_privileges', playerInfo.player_has_host_privileges);
}

// --------------------------------------------------------------------------------------------------
// Entry point, update a player panel on creation and register for callbacks when the player details
// are changed.
// --------------------------------------------------------------------------------------------------
(function () {
  OnPlayerDetailsChanged();
  $.RegisterForUnhandledEvent('DOTAGame_PlayerDetailsChanged', OnPlayerDetailsChanged);
})();
