/* global $ CustomNetTables Game */

(function () {
  CustomNetTables.SubscribeNetTableListener('stat_display', onStatChange);
}());

function onStatChange (table, key, data) {
  /* for (var entry in data.value) {
    $.Msg(entry);
  } */
  var playerID = Game.GetLocalPlayerID();
  // $.Msg('onStatChange:');
  // $.Msg(playerID + ' : ' + key + ' = ' + JSON.stringify(data.value, null, 2));
  UpdateStatDisplay(key, data.value[playerID] || 0);
}

function UpdateStatDisplay (name, value) {
  var display = $('#OAAStatDisplay');

  // $.Msg('Looking for QuickStatLabelValue of ' + name + 'Row');
  display.FindChildTraverse(name + 'Row').FindChildTraverse('QuickStatLabelValue').text = value;
}
