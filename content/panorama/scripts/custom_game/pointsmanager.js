'use strict';

var console = {
  log: $.Msg.bind($)
};

(function () {
  CustomNetTables.SubscribeNetTableListener('team_scores', onScoreChange);
  GameEvents.Subscribe('points_won', onTeamWin);
}());

function onScoreChange(table, key, data) {
  console.log('[PointsManager] onScoreChange');

  if (key === 'score') {
    var limit = CustomNetTables.GetTableValue('team_scores', 'limit')['value'];
    var goodguys = data['goodguys'];
    var badguys = data['badguys'];
  } else if (key === 'limit') {
    var limit = data['value'];
    var score = CustomNetTables.GetTableValue('team_scores', 'score');
    var goodguys = score['goodguys'];
    var badguys = score['badguys'];
  }

  console.log('limit: ' + limit);
  console.log('goodguys: ' + goodguys);
  console.log('badguys: ' + badguys);

  UpdatePointsHud(limit, goodguys, badguys);
}

function UpdatePointsHud(limit, goodguys, badguys) {
  var goodguysLabel = FindDotaHudElement('TopBarRadiantScore');
  var badguysLabel = FindDotaHudElement('TopBarDireScore');

  // BUG: limit doesnt get displayed correctly
  goodguysLabel.text = goodguys + '\n' + limit;
  badguysLabel.text = badguys + '\n' + limit;
}

function onTeamWin(data) {

}
