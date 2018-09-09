/* global GameEvents */
'use strict';

(function () {
  GameEvents.Subscribe('custom_dota_hud_error_message', DisplayHudError);
}());

function DisplayHudError (data) {
  GameEvents.SendEventClientSide('dota_hud_error_message', data);
}
