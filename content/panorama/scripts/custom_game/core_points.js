/* global $, GameEvents, Players, Entities, Buffs */

'use strict';

function FindModifier (unit, modifier) {
  for (let i = 0; i < Entities.GetNumBuffs(unit); i++) {
    if (Buffs.GetName(unit, Entities.GetBuff(unit, i)) === modifier) {
      return Entities.GetBuff(unit, i);
    }
  }
}

function HasModifier (unit, modifier) {
  return !!FindModifier(unit, modifier);
}

function GetStackCount (unit, modifier) {
  const m = FindModifier(unit, modifier);
  return m ? Buffs.GetStackCount(unit, m) : 0;
}

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
