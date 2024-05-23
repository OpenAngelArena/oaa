/* global $, GameEvents, Game, DOTA_GameState */
'use strict';

// this doesn't seem to do anything. maybe the discord panel is under the picking screen and strategy screen
// or it's never created before the player loads in;
function ShowHideDiscord () {
  const context = $.GetContextPanel();
  if (Game.GameStateIsBefore(DOTA_GameState.DOTA_GAMERULES_STATE_STRATEGY_TIME)) {
    context.visible = false;
  } else {
    context.visible = true;
  }
}

(function () {
  GameEvents.Subscribe('game_rules_state_change', ShowHideDiscord);
  const context = $.GetContextPanel();
  if (Game.IsHUDFlipped()) {
    context.style.marginLeft = '21%';
  }
})();
