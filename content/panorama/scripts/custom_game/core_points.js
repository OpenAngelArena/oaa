/* global $, GameEvents, Players, HasModifier, GetStackCount, Game, Entities */

'use strict';

// this happens for every core points change
function OnCorePointsChanged (args) {
  const currentlySelectedUnit = Players.GetLocalPlayerPortraitUnit();
  // If currently selected unit is not the player's hero then don't continue
  if (currentlySelectedUnit !== Players.GetPlayerHeroEntityIndex(Players.GetLocalPlayer())) return;
  const cpLabel = $('#CorePointsText');
  const corePoints = args.cp;
  if (typeof corePoints === 'number' || typeof corePoints === 'string') {
    cpLabel.text = corePoints;
  } else {
    // Received argument is invalid, do stuff below
    ShowCorePointsOnSelected();
  }
}

// this happens when a player selects any unit
function ShowCorePointsOnSelected () {
  const currentlySelectedUnit = Players.GetLocalPlayerPortraitUnit();
  // If currently selected unit is invalid then don't continue
  if (!Entities.IsValidEntity(currentlySelectedUnit)) return;
  const modifier = 'modifier_core_points_counter_oaa';
  const cpLabel = $('#CorePointsText');
  // Show core points only if currently selected unit has the modifier and if it is on the player's team
  if (HasModifier(currentlySelectedUnit, modifier) && Entities.GetTeamNumber(currentlySelectedUnit) === Players.GetTeam(Players.GetLocalPlayer())) {
    $.Schedule(0.03, function () {
      const corePoints = GetStackCount(currentlySelectedUnit, modifier);
      cpLabel.text = corePoints;
    });
  } else {
    cpLabel.text = 0;
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
