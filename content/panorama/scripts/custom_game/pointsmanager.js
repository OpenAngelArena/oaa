/* global $, CustomNetTables */

'use strict';

var HudNotFoundException = /** @class */ (function () {
  function HudNotFoundException (message) {
    this.message = message;
  }
  return HudNotFoundException;
}());
function FindDotaHudElement (id) {
  return GetDotaHud().FindChildTraverse(id);
}
function GetDotaHud () {
  var p = $.GetContextPanel();
  while (p !== null && p.id !== 'Hud') {
    p = p.GetParent();
  }
  if (p === null) {
    throw new HudNotFoundException('Could not find Hud root as parent of panel with id: ' + $.GetContextPanel().id);
  } else {
    return p;
  }
}

(function () {
  CustomNetTables.SubscribeNetTableListener('team_scores', onScoreChange);
}());

function onScoreChange (table, key, data) {
  // console.log('[PointsManager] onScoreChange')

  if (key === 'score') {
    var goodguys = data['goodguys'];
    var badguys = data['badguys'];
    UpdatePointsHud(goodguys, badguys);
  } else if (key === 'limit') {
    // assuming this only happens on gamestart
    var length = data['name'];
    FindDotaHudElement('PreGame').FindChildTraverse('GameModeLabel').text = $.Localize(('#oaa_game_length_' + length + '_title').toLowerCase());
  }
}

function UpdatePointsHud (goodguys, badguys) {
  FindDotaHudElement('TopBarRadiantScore').text = goodguys;
  FindDotaHudElement('RadiantScoreLabel').text = goodguys;
  FindDotaHudElement('TopBarDireScore').text = badguys;
  FindDotaHudElement('DireScoreLabel').text = badguys;
}
