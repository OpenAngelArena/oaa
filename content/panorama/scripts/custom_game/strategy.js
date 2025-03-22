/* global GameEvents FindDotaHudElement Game DOTA_GameState */

'use strict';

(function () {
  GameEvents.Subscribe('game_rules_state_change', CheckStrategy);
})();

// function HideStrategy () {
// var bossMarkers = ['Boss1r', 'Boss1d', 'Boss2r', 'Boss2d', 'Boss3r', 'Boss3d', 'Boss4r', 'Boss4d', 'Boss5r', 'Boss5d', 'Duel1', 'Duel2', 'Cave1r', 'Cave1d', 'Cave2r', 'Cave2d', 'Cave3r', 'Cave3d'];

// bossMarkers.forEach(function (element) {
//   FindDotaHudElement(element).style.transform = 'translateY(0)';
//   FindDotaHudElement(element).style.opacity = '1';
// });

// FindDotaHudElement('MainContent').GetParent().style.opacity = '0';
// FindDotaHudElement('MainContent').GetParent().style.transform = 'scaleX(3) scaleY(3) translateY(25%)';
// }

// function GoToStrategy () {
// FindDotaHudElement('MainContent').style.transform = 'translateX(0) translateY(100%)';
// FindDotaHudElement('MainContent').style.opacity = '0';

// $.Schedule(6, function () {
// $('#ARDMLoading').style.opacity = 1;
// });
// }

function CheckStrategy () {
  if (Game.GameStateIsAfter(DOTA_GameState.DOTA_GAMERULES_STATE_HERO_SELECTION)) {
    ShowStrategy();
  }
}

function ShowStrategy () {
  const pregamePanel = FindDotaHudElement('PreGame');
  pregamePanel.style.zIndex = 0; // changing zIndex back so the 'hovering tooltips' work normally
  const headerPanel = pregamePanel.FindChildTraverse('Header');
  if (headerPanel) {
    headerPanel.style.visibility = 'visible';
  }
  const contentPanel = pregamePanel.FindChildTraverse('MainContents');
  if (contentPanel) {
    contentPanel.style.visibility = 'visible';
  }
  const radiantTeamPanel = pregamePanel.FindChildTraverse('RadiantTeamPlayers');
  if (radiantTeamPanel) {
    radiantTeamPanel.style.visibility = 'visible';
  }
  const direTeamPanel = pregamePanel.FindChildTraverse('DireTeamPlayers');
  if (direTeamPanel) {
    direTeamPanel.style.visibility = 'visible';
  }
}
