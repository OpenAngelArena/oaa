'use strict';

var console = {
  log: $.Msg.bind($)
};

(function () {
  PlayerTables.SubscribeNetTableListener('team_scores', onScoreChange);
  GameEvents.Subscribe('points_won', onTeamWin);
}());

function onScoreChange(table, data) {
  var limit = data.limit.value;
  var goodguys = data.score.goodguys;
  var badguys = data.score.badguys;

  UpdatePointsHud(limit, goodguys, badguys);
}

function UpdatePointsHud(limit, goodguys, badguys) {
  console.log(GetDotaHud());
  var goodguysLabel = GetDotaHudElement('GoodGuysLabel')
  var badguysLabel = GetDotaHudElement('BadGuysLabel')

}
