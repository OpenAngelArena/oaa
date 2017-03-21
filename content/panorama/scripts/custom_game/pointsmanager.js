'use strict';

var console = {
  log: $.Msg.bind($)
};

(function () {
  CustomNetTables.SubscribeNetTableListener('team_scores', onScoreChange);
}());

function onScoreChange(table, key, data) {
  //console.log('[PointsManager] onScoreChange');

  if (key === 'score') {
    var limit = CustomNetTables.GetTableValue('team_scores', 'limit')['value'];
    var goodguys = data['goodguys'];
    var badguys = data['badguys'];
  } else if (key === 'limit') {
    // assuming this only happens on gamestart
    var limit = data['value'];
    var length = data['name'];
    var score = CustomNetTables.GetTableValue('team_scores', 'score');
    FindDotaHudElement('PreGame').FindChildTraverse( 'GameModeLabel' ).text = $.Localize(("#oaa_game_length_" + length + "_title").toLowerCase());
    var goodguys = 0;
    var badguys = 0;
  } 

/*
  console.log('limit: ' + limit);
  console.log('goodguys: ' + goodguys);
  console.log('badguys: ' + badguys);
*/
  UpdatePointsHud(limit, goodguys, badguys);
}

function UpdatePointsHud(limit, goodguys, badguys) {
  var goodguysLabel = FindDotaHudElement('TopBarRadiantScore');
  var badguysLabel = FindDotaHudElement('TopBarDireScore');

  goodguysLabel.style.fontSize = '18px';
  goodguysLabel.style.marginTop = '2px';
  goodguysLabel.style.lineHeight = '17px';
  badguysLabel.style.fontSize = '18px';
  badguysLabel.style.marginTop = '2px';
  badguysLabel.style.lineHeight = '17px';

  goodguysLabel.text = goodguys + '\n' + limit;
  badguysLabel.text = badguys + '\n' + limit;
}
