function FindDotaHudElement (panel) {
  return $.GetContextPanel().GetParent().GetParent().GetParent().FindChildTraverse(panel);
}

function OverrideHeroImage (panel) {
  if (panel) {
    var name = panel.heroname
    if (name == 'sohei' || name == 'electrician') {
      panel.style.backgroundImage = 'url("file://{images}/heroes/npc_dota_hero_' + name + '.png")';
      panel.style.backgroundSize = "100% 100%";
	}
  }
}

function OverrideHeroImagesForTeam (team) {
  if (team) {
    for (i=0; i < DOTALimits_t.DOTA_MAX_TEAM_PLAYERS-1; i++) {
      var top_bar_panel = FindDotaHudElement(team + "Player" + i);
      if (top_bar_panel && Players.IsValidPlayerID(i)) {
        var panel = top_bar_panel.FindChildTraverse('HeroImage');
        OverrideHeroImage(panel)
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

GameEvents.Subscribe('game_rules_state_change', OverrideTopBarHeroImages)
GameEvents.Subscribe('player_connect', OverrideTopBarHeroImages)
GameEvents.Subscribe('player_reconnected', OverrideTopBarHeroImages)