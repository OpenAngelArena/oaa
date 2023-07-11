/* global $, GameEvents, Players, HasModifier, GetStackCount */

'use strict';

function OnCorePointsChanged (args) {
  const unit = Players.GetLocalPlayerPortraitUnit();
  const modifier = 'modifier_core_points_counter_oaa';
  const cpLabel = $('#CorePointsText');
  let corePoints = args.cp;
  if (HasModifier(unit, modifier)) {
    $.Schedule(0.03, function () {
      corePoints = GetStackCount(unit, modifier);
      cpLabel.text = corePoints;
    });
  }

  cpLabel.text = corePoints;
}

(function () {
  GameEvents.Subscribe('core_point_number_changed', OnCorePointsChanged);
  OnCorePointsChanged({ cp: '-' });
})();
