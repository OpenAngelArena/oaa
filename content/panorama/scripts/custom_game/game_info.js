/* global FindDotaHudElement GameEvents Game */

(function () {
  if (Game.GetLocalPlayerID() === -1) {
    FindDotaHudElement('GameInfoButton').GetParent().RemoveAndDeleteChildren();
  } else {
    FindDotaHudElement('GameInfoButton').style.transform = 'translateY(50%)';
  }
}());
