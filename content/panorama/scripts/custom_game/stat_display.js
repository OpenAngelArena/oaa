/* global $ CustomNetTables Game Players */

(function () {
  if (Game.GetLocalPlayerID() !== -1) {
    CustomNetTables.SubscribeNetTableListener('stat_display_player', onPlayerStatChange);
    CustomNetTables.SubscribeNetTableListener('stat_display_team', onTeamStatChange);
    if (Game.IsHUDFlipped()) {
      // Listen to shop open/close events
      $.RegisterForUnhandledEvent('DOTAHUDShopOpened', HideStatDisplay);
      $.RegisterForUnhandledEvent('DOTAHUDShopClosed', ShowStatDisplay);
    }
  } else {
    $.GetContextPanel().FindChildTraverse('OAAStatDisplay').GetParent().RemoveAndDeleteChildren();
  }
}());

function onPlayerStatChange (table, key, data) {
  const playerID = Game.GetLocalPlayerID();
  UpdateStatDisplay(key, data.value[playerID] || 0);
}

function onTeamStatChange (table, key, data) {
  const playerID = Game.GetLocalPlayerID();
  const teamID = Players.GetTeam(playerID);
  UpdateStatDisplay(key, data.value[teamID] || 0);
}

function UpdateStatDisplay (name, value) {
  const display = $('#OAAStatDisplay');

  display.FindChildTraverse(name + 'Row').FindChildTraverse('QuickStatLabelValue').text = value;
}

function HideStatDisplay () {
  const customStatsDisplay = $('#OAAStatDisplay').GetParent();
  customStatsDisplay.style.opacity = 0;
  customStatsDisplay.style.visibility = 'collapse';
}

function ShowStatDisplay () {
  const customStatsDisplay = $('#OAAStatDisplay').GetParent();
  customStatsDisplay.style.opacity = 1;
  customStatsDisplay.style.visibility = 'visible';
}
