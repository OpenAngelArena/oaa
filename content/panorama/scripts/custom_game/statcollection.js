/* global Game, $, GameEvents */

'use strict';

function OnClientCheckIn (args) {
  const playerInfo = Game.GetLocalPlayerInfo();
  let hostInfo = 0;
  if (playerInfo) {
    hostInfo = playerInfo.player_has_host_privileges;
  }

  const payload = {
    modIdentifier: args.modID,
    steamID32: GetSteamID32(),
    isHost: hostInfo,
    matchID: args.matchID,
    schemaVersion: args.schemaVersion
  };

  $.Msg('Sending: ', payload);

  $.AsyncWebRequest('https://api.getdotastats.com/s2_check_in.php',
    {
      type: 'POST',
      data: { payload: JSON.stringify(payload) },
      success: function (data) {
        $.Msg('GDS Reply: ', data);
      }
    });
}

function GetSteamID32 () {
  const playerInfo = Game.GetPlayerInfo(Game.GetLocalPlayerID());

  const steamID64 = playerInfo.player_steamid;
  const steamIDPart = Number(steamID64.substring(3));
  const steamID32 = String(steamIDPart - 61197960265728);

  return steamID32;
}

function Print (msg) {
  $.Msg(msg.content);
}

(function () {
  $.Msg('StatCollection Client Loaded');

  GameEvents.Subscribe('statcollection_client', OnClientCheckIn);
  GameEvents.Subscribe('statcollection_print', Print);
})();
