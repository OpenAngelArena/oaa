/* global $, Game, DOTA_GameState, GameUI, Players */

let particles = {}

function CheckForAltPress () {
  if (Game.GameStateIsAfter(DOTA_GameState.DOTA_GAMERULES_STATE_TEAM_SHOWCASE)) {
    if (GameUI.IsAltDown()) {
      const buildings = Entities.GetAllBuildingEntities():
    } else {

    }
  }
}

(function () {
  $.RegisterForUnhandledEvent('DOTAHudUpdate', CheckForAltPress);
})();
