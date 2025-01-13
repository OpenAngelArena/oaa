/* global $, GameEvents, Players, HasModifier, GetStackCount, Game, Entities */

'use strict';

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

  const cpLabel = $('#CorePointsText');
  const corePoints = args.cp;

  // Convert to string to ensure consistent display
  cpLabel.text = String(corePoints);
}

// this happens when a player selects any unit
function ShowCorePointsOnSelected () {
  const currentlySelectedUnit = Players.GetLocalPlayerPortraitUnit();
  $.Msg('Selected Unit:', currentlySelectedUnit);

  if (!Entities.IsValidEntity(currentlySelectedUnit)) {
    $.Msg('Invalid entity');
    return;
  }

  const modifier = 'modifier_core_points_counter_oaa';
  $.Msg('Has modifier:', HasModifier(currentlySelectedUnit, modifier));
  $.Msg('Team check:', Entities.GetTeamNumber(currentlySelectedUnit), Players.GetTeam(Players.GetLocalPlayer()));

  if (HasModifier(currentlySelectedUnit, modifier) &&
      Entities.GetTeamNumber(currentlySelectedUnit) === Players.GetTeam(Players.GetLocalPlayer())) {
    const corePoints = GetStackCount(currentlySelectedUnit, modifier);
    $.Msg('Core Points:', corePoints);
    // Only update if we got a valid number
    if (!isNaN(corePoints)) {
      $('#CorePointsText').text = String(corePoints);
    }
  } else {
    $('#CorePointsText').text = '0';
  }
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
    $('#CorePointsText').style.transform = 'scaleX(-1)';
    $('#CorePointsIcon').style.transform = 'scaleX(-1)';
  }
})();
