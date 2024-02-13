/* global $, CustomNetTables, Game, GameEvents, DOTA_GameState */
'use strict';

function HideInfo () {
  const context = $.GetContextPanel();
  if (Game.GameStateIs(DOTA_GameState.DOTA_GAMERULES_STATE_GAME_IN_PROGRESS) || Game.GameStateIsAfter(DOTA_GameState.DOTA_GAMERULES_STATE_GAME_IN_PROGRESS)) {
    context.style.opacity = 0;
    context.style.visibility = 'collapse';
  }
}

(function () {
  const context = $.GetContextPanel();
  context.FindChildTraverse('InfoVersion').text = 'Version: ' + CustomNetTables.GetTableValue('info', 'version').value + ' ';
  context.FindChildTraverse('InfoMap').text = 'Map: ' + Game.GetMapInfo().map_display_name + ' ';
  context.FindChildTraverse('InfoDateTime').text = 'Gametime: ' + CustomNetTables.GetTableValue('info', 'datetime').value + ' ';
  context.FindChildTraverse('InfoMode').text = CustomNetTables.GetTableValue('info', 'mode').value + ' ';

  GameEvents.Subscribe('game_rules_state_change', HideInfo);
})();
