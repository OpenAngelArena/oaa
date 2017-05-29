/* global FindDotaHudElement, GameEvents */

(function () {
  GameEvents.Subscribe('game_rules_state_change', MoveGameInfo);
}());

function MoveGameInfo () {
  FindDotaHudElement('GameInfoButton').style.transform = 'translateY(20%)';
}
