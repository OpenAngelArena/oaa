/* global $, GameEvents, Players, HasModifier, GetStackCount, Game, Entities, CLICK_BEHAVIORS */

'use strict';

let isWindowCurrentlyOpen = false;
const corePointsTextPanel = $('#CorePointsText');
const corePointsIconPanel = $('#CorePointsIcon');
const exchangeWindow = $('#CorePointsExchangePanel');
const cssOpen = 'visible_overlay';

// this happens for every core points change
function OnCorePointsChanged (args) {
  // Add validation for args
  if (!args || typeof args.cp === 'undefined') {
    ShowCorePointsOnSelected();
    return;
  }

  const currentlySelectedUnit = Players.GetLocalPlayerPortraitUnit();
  // If currently selected unit is not the player's hero then don't continue
  if (currentlySelectedUnit !== Players.GetPlayerHeroEntityIndex(Players.GetLocalPlayer())) return;

  const corePoints = args.cp;

  // Convert to string to ensure consistent display
  corePointsTextPanel.text = String(corePoints);
}

// this happens when a player selects any unit
function ShowCorePointsOnSelected () {
  const player = Players.GetLocalPlayer();
  let currentlySelectedUnit = Players.GetQueryUnit(player);
  if (currentlySelectedUnit === -1) {
    currentlySelectedUnit = Players.GetLocalPlayerPortraitUnit();
  }
  // $.Msg('Selected Unit:', currentlySelectedUnit);

  if (!Entities.IsValidEntity(currentlySelectedUnit)) {
    $.Msg('Invalid entity was selected');
    return;
  }

  const modifier = 'modifier_core_points_counter_oaa';
  // $.Msg('Has modifier:', HasModifier(currentlySelectedUnit, modifier));
  // $.Msg('Team check:', Entities.GetTeamNumber(currentlySelectedUnit), Players.GetTeam(player));

  // Show core points only if currently selected unit has the modifier and if it is on the player's team
  if (HasModifier(currentlySelectedUnit, modifier) && Entities.GetTeamNumber(currentlySelectedUnit) === Players.GetTeam(player)) {
    const corePoints = GetStackCount(currentlySelectedUnit, modifier);
    // $.Msg('Core Points:', corePoints);
    // Only update if we got a valid number
    if (!isNaN(corePoints)) {
      corePointsTextPanel.text = String(corePoints);
    }
  } else {
    corePointsTextPanel.text = '0';
  }
}

function ToggleExchangeWindow () {
  const currentEntity = Players.GetLocalPlayerPortraitUnit();
  // Currently closed: open!
  if (!isWindowCurrentlyOpen) {
    // Prevent opening window if a hero is not selected
    if (Entities.IsValidEntity(currentEntity) && Entities.IsHero(currentEntity)) {
      isWindowCurrentlyOpen = true;
      exchangeWindow.AddClass(cssOpen);
      Game.EmitSound('ui_chat_slide_in');
    }
  } else { // Currently open: close!
    isWindowCurrentlyOpen = false;
    exchangeWindow.RemoveClass(cssOpen);
    Game.EmitSound('ui_chat_slide_out');
  }
}

function buyUpgradeCore (tier) {
  GameEvents.SendCustomGameEventToServer('oaa_purchase_core', { tier: tier });
}

(function () {
  GameEvents.Subscribe('core_point_number_changed', OnCorePointsChanged);
  GameEvents.Subscribe('dota_player_update_query_unit', ShowCorePointsOnSelected);
  GameEvents.Subscribe('dota_player_update_selected_unit', ShowCorePointsOnSelected);

  if (Game.IsHUDFlipped()) {
    const context = $.GetContextPanel();
    context.style.align = 'left bottom';
    context.style.marginRight = '0px';
    context.style.marginLeft = '290px';
    context.style.transform = 'scaleX(-1)';
    corePointsTextPanel.style.transform = 'scaleX(-1)';
    corePointsIconPanel.style.transform = 'scaleX(-1)';
    exchangeWindow.style.transform = 'scaleX(-1)';
  }

  corePointsTextPanel.SetPanelEvent('onactivate', function () { ToggleExchangeWindow(); });
  corePointsTextPanel.SetPanelEvent('oncontextmenu', function () { ToggleExchangeWindow(); });
  corePointsIconPanel.SetPanelEvent('onactivate', function () { ToggleExchangeWindow(); });
  corePointsIconPanel.SetPanelEvent('oncontextmenu', function () { ToggleExchangeWindow(); });

  $('#CorePointRow1').SetPanelEvent('onactivate', function () { buyUpgradeCore(1); });
  $('#CorePointRow1').SetPanelEvent('oncontextmenu', function () { buyUpgradeCore(1); });
  $('#CorePointRow2').SetPanelEvent('onactivate', function () { buyUpgradeCore(2); });
  $('#CorePointRow2').SetPanelEvent('oncontextmenu', function () { buyUpgradeCore(2); });
  $('#CorePointRow3').SetPanelEvent('onactivate', function () { buyUpgradeCore(3); });
  $('#CorePointRow3').SetPanelEvent('oncontextmenu', function () { buyUpgradeCore(3); });
  $('#CorePointRow4').SetPanelEvent('onactivate', function () { buyUpgradeCore(4); });
  $('#CorePointRow4').SetPanelEvent('oncontextmenu', function () { buyUpgradeCore(4); });
  $('#CorePointRow5').SetPanelEvent('onactivate', function () { buyUpgradeCore(5); });
  $('#CorePointRow5').SetPanelEvent('oncontextmenu', function () { buyUpgradeCore(5); });

  // Allow mouse clicks outside the window to close it.
  GameUI.SetMouseCallback(function (event, value) {
    if (isWindowCurrentlyOpen && value === CLICK_BEHAVIORS.DOTA_CLICK_BEHAVIOR_NONE) {
      if (event === 'pressed') {
        const cursorPos = GameUI.GetCursorPosition();
        if (cursorPos[0] < exchangeWindow.actualxoffset || exchangeWindow.actualxoffset + exchangeWindow.contentwidth < cursorPos[0] || cursorPos[1] < exchangeWindow.actualyoffset || exchangeWindow.actualyoffset + exchangeWindow.contentheight < cursorPos[1]) {
          $.Schedule(0, function () {
            ToggleExchangeWindow();
          });
        }
      }
    }

    return false;
  });
})();
