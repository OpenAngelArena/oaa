/* global GameEvents */
'use strict';

(function () {
  GameEvents.Subscribe('custom_dota_hud_error_message', DisplayHudError);
}());

function DisplayHudError (data) {
  GameEvents.SendEventClientSide('dota_hud_error_message', data);
}

// dota_hud_error_message is a game event
// the event data has a reason integer and a message string.
// The message is ignored for most reasons as they have preset messages.
// reason 80 allows a custom message.
// 24 - silenced
// 25 - can't move
// 30 - can't be attacked
// 41 - can't attack
// 46 - target out of range
// 48 - can't target that
// 62 - secret shop not in range
// 63 - not enough gold
// 74 - can't act
// 75 - muted
// 77 - target immune to magic
// 80 - custom "message" argument
