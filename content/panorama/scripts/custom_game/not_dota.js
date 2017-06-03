/* global FindDotaHudElement */

function hideBattlePassTowers () {
  FindDotaHudElement('BattlePassTowers').style.visibility = 'collapse';
}

(function () {
  hideBattlePassTowers();
})();
