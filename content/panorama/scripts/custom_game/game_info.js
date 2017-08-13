/* global FindDotaHudElement, GameEvents, Game */
(function () {
  if (Game.GetLocalPlayerID() !== -1) {
    GameEvents.Subscribe('game_rules_state_change', MoveGameInfo);
  } else {
    $.GetContextPanel().FindChildTraverse('GameInfoButton').GetParent().RemoveAndDeleteChildren();
  }
}());

function MoveGameInfo () {
  FindDotaHudElement('GameInfoButton').style.transform = 'translateY(20%)';
}
