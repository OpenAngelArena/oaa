/* global $, FindDotaHudElement, Game, DOTA_GameState, GameUI, DotaDefaultUIElement_t, GameEvents */
'use strict';

function HidePickScreen () {
  const pregame = FindDotaHudElement('PreGame');
  if (Game.GameStateIsBefore(DOTA_GameState.DOTA_GAMERULES_STATE_HERO_SELECTION)) {
    pregame.visible = false;
  } else if (Game.GameStateIs(DOTA_GameState.DOTA_GAMERULES_STATE_HERO_SELECTION)) {
    pregame.visible = true;
  } else if (Game.GameStateIsAfter(DOTA_GameState.DOTA_GAMERULES_STATE_STRATEGY_TIME)) {
    pregame.visible = false;
  }
}

(function () {
  // Uncomment any of the following lines in order to disable that portion of the default UI

  GameUI.SetDefaultUIEnabled(DotaDefaultUIElement_t.DOTA_DEFAULT_UI_TOP_TIMEOFDAY, false); // Time of day (clock).
  // GameUI.SetDefaultUIEnabled( DotaDefaultUIElement_t.DOTA_DEFAULT_UI_TOP_HEROES, true );     //Heroes and team score at the top of the HUD.
  // GameUI.SetDefaultUIEnabled( DotaDefaultUIElement_t.DOTA_DEFAULT_UI_FLYOUT_SCOREBOARD, false );      //Lefthand flyout scoreboard.
  // GameUI.SetDefaultUIEnabled( DotaDefaultUIElement_t.DOTA_DEFAULT_UI_ACTION_PANEL, false );     //Hero actions UI.
  // GameUI.SetDefaultUIEnabled( DotaDefaultUIElement_t.DOTA_DEFAULT_UI_ACTION_MINIMAP, false );     //Minimap.
  // GameUI.SetDefaultUIEnabled( DotaDefaultUIElement_t.DOTA_DEFAULT_UI_INVENTORY_PANEL, false );      //Entire Inventory UI
  // GameUI.SetDefaultUIEnabled( DotaDefaultUIElement_t.DOTA_DEFAULT_UI_INVENTORY_SHOP, false );     //Shop portion of the Inventory.
  // GameUI.SetDefaultUIEnabled( DotaDefaultUIElement_t.DOTA_DEFAULT_UI_INVENTORY_ITEMS, false );      //Player items.
  GameUI.SetDefaultUIEnabled( DotaDefaultUIElement_t.DOTA_DEFAULT_UI_INVENTORY_QUICKBUY, false );     //Quickbuy.
  // GameUI.SetDefaultUIEnabled( DotaDefaultUIElement_t.DOTA_DEFAULT_UI_INVENTORY_COURIER, false );      //Courier controls.
  // GameUI.SetDefaultUIEnabled( DotaDefaultUIElement_t.DOTA_DEFAULT_UI_INVENTORY_PROTECT, false );      //Glyph.
  // GameUI.SetDefaultUIEnabled( DotaDefaultUIElement_t.DOTA_DEFAULT_UI_INVENTORY_GOLD, false );     //Gold display.
  // GameUI.SetDefaultUIEnabled( DotaDefaultUIElement_t.DOTA_DEFAULT_UI_SHOP_SUGGESTEDITEMS, false );      //Suggested items shop panel.
  GameUI.SetDefaultUIEnabled(DotaDefaultUIElement_t.DOTA_DEFAULT_UI_HERO_SELECTION_TEAMS, false); // Hero selection Radiant and Dire player lists.
  GameUI.SetDefaultUIEnabled(DotaDefaultUIElement_t.DOTA_DEFAULT_UI_HERO_SELECTION_GAME_NAME, false); // Hero selection game mode name display.
  // GameUI.SetDefaultUIEnabled( DotaDefaultUIElement_t.DOTA_DEFAULT_UI_HERO_SELECTION_CLOCK, false );     //Hero selection clock.
  // GameUI.SetDefaultUIEnabled( DotaDefaultUIElement_t.DOTA_DEFAULT_UI_TOP_MENU_BUTTONS, false );     //Top-left menu buttons in the HUD.
  GameUI.SetDefaultUIEnabled(DotaDefaultUIElement_t.DOTA_DEFAULT_UI_ENDGAME, false); // Endgame scoreboard.
  // GameUI.SetDefaultUIEnabled( DotaDefaultUIElement_t.DOTA_DEFAULT_UI_TOP_BAR_BACKGROUND, false );     //Top-left menu buttons in the HUD.

  // These lines set up the panorama colors used by each team (for game select/setup, etc)
  // GameUI.CustomUIConfig().team_colors = {}
  // GameUI.CustomUIConfig().team_colors[DOTATeam_t.DOTA_TEAM_GOODGUYS] = "#3dd296;";
  // GameUI.CustomUIConfig().team_colors[DOTATeam_t.DOTA_TEAM_BADGUYS ] = "#F3C909;";
  // GameUI.CustomUIConfig().team_colors[DOTATeam_t.DOTA_TEAM_CUSTOM_1] = "#c54da8;";
  // GameUI.CustomUIConfig().team_colors[DOTATeam_t.DOTA_TEAM_CUSTOM_2] = "#FF6C00;";
  // GameUI.CustomUIConfig().team_colors[DOTATeam_t.DOTA_TEAM_CUSTOM_3] = "#3455FF;";
  // GameUI.CustomUIConfig().team_colors[DOTATeam_t.DOTA_TEAM_CUSTOM_4] = "#65d413;";
  // GameUI.CustomUIConfig().team_colors[DOTATeam_t.DOTA_TEAM_CUSTOM_5] = "#815336;";
  // GameUI.CustomUIConfig().team_colors[DOTATeam_t.DOTA_TEAM_CUSTOM_6] = "#1bc0d8;";
  // GameUI.CustomUIConfig().team_colors[DOTATeam_t.DOTA_TEAM_CUSTOM_7] = "#c7e40d;";
  // GameUI.CustomUIConfig().team_colors[DOTATeam_t.DOTA_TEAM_CUSTOM_8] = "#8c2af4;";

  // Hook Print function
  GameEvents.Subscribe('vconsole', function (keys) {
    let text = '';
    switch (keys.type) {
      case 'print':
        for (const x in keys.data) text += keys.data[x] + '\t';
        $.Msg('[Server] ' + text);
        break;
      case 'error':
        for (const x in keys.data) text += keys.data[x] + '\n';
        $.Msg('[Server] ' + text);
        break;
    }
  });
  $.Msg('Now receiving Server Messages.');

  // Hiding vanilla picking screen
  GameEvents.Subscribe('game_rules_state_change', HidePickScreen);
  // Cheat Mode Check
  GameEvents.Subscribe('onGameInCheatMode', function () {
    $.Msg('This Match is in Cheat Mode!');
  });
})();
