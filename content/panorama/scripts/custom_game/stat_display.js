/* global $ CustomNetTables Game Players */

(function () {
  if (Game.GetLocalPlayerID() !== -1) {
    CustomNetTables.SubscribeNetTableListener('stat_display_player', onPlayerStatChange);
    CustomNetTables.SubscribeNetTableListener('stat_display_team', onTeamStatChange);
  } else {
    $.GetContextPanel().FindChildTraverse('OAAStatDisplay').GetParent().RemoveAndDeleteChildren();
  }
}());

function onPlayerStatChange (table, key, data) {
  var playerID = Game.GetLocalPlayerID();
  UpdateStatDisplay(key, data.value[playerID] || 0);
}

function onTeamStatChange (table, key, data) {
  var playerID = Game.GetLocalPlayerID();
  var teamID = Players.GetTeam(playerID);
  UpdateStatDisplay(key, data.value[teamID] || 0);
}

function UpdateStatDisplay (name, value) {
  var display = $('#OAAStatDisplay');

  display.FindChildTraverse(name + 'Row').FindChildTraverse('QuickStatLabelValue').text = value;
}
