/* global GameEvents, Players, Entities, Buffs */

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
  let m = FindModifier(unit, modifier);
  return m ? Buffs.GetStackCount(unit, m) : 0;
}

function OnCorePointsChanged (args) {
  let unit = Players.GetLocalPlayerPortraitUnit();
  let modifier = 'modifier_core_points_counter_oaa';
  let corePoints = args.cp;
  if (HasModifier(unit, modifier)) {
    corePoints = GetStackCount(unit, modifier);
  }

  let cpLabel = $('#CorePointsText');

  cpLabel.text = corePoints;
}

(function () {
  GameEvents.Subscribe('core_point_number_changed', OnCorePointsChanged);
})();
