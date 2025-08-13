/* global  GameEvents, DOTALimits_t, Game, DOTA_GameState, Players, FindDotaHudElement, is10v10 */

function OverrideHeroImage (panel) {
  if (panel) {
    const name = panel.heroname;
    if (name === 'sohei' || name === 'electrician' || name === 'eul' || name === 'bubble_witch') {
      panel.style.backgroundImage = 'url("file://{images}/heroes/npc_dota_hero_' + name + '.png")';
      panel.style.backgroundSize = '100% 100%';
    }
  }
}

function OverrideHeroImagesForTeam (team) {
  if (team) {
    let i;
    for (i = 0; i < DOTALimits_t.DOTA_MAX_TEAM_PLAYERS - 1; i++) {
      const topBarPanel = FindDotaHudElement(team + 'Player' + i);
      if (topBarPanel && Players.IsValidPlayerID(i)) {
        const panel = topBarPanel.FindChildTraverse('HeroImage');
        OverrideHeroImage(panel);
      }
    }
  }
}

function OverrideTopBarHeroImages () {
  if (Game.GameStateIsAfter(DOTA_GameState.DOTA_GAMERULES_STATE_TEAM_SHOWCASE)) {
    OverrideHeroImagesForTeam('Radiant');
    OverrideHeroImagesForTeam('Dire');
  }
}

(function () {
  if (is10v10()) {
    FindDotaHudElement('TopBarLeftFlare').style.visibility = 'collapse';
    FindDotaHudElement('TopBarRightFlare').style.visibility = 'collapse';
    FindDotaHudElement('TopBarRadiantTeamContainer').style.marginLeft = '-35px';
    FindDotaHudElement('TopBarRadiantTeamContainer').style.marginRight = '0px';
    FindDotaHudElement('TopBarDireTeamContainer').style.marginLeft = '35px';
    FindDotaHudElement('TopBarDireTeamContainer').style.marginRight = '-35px';
  }
  GameEvents.Subscribe('game_rules_state_change', OverrideTopBarHeroImages);
  GameEvents.Subscribe('player_connect_full', OverrideTopBarHeroImages);
})();
