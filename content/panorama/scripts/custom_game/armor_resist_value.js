/* global GameEvents, Entities, FindDotaHudElement, $, Players, Buffs */
'use strict';
(function () {
  var statsTooltipRegion = FindDotaHudElement('stats_tooltip_region');
  // Create a child panel to occupy the same space so that we can listen for mouse over events
  var hookPanel = $.CreatePanel('Panel', statsTooltipRegion, 'stats_tooltip_region_hook');
  hookPanel.SetPanelEvent('onmouseover' /* ON_MOUSE_OVER */, function () { return $.Schedule(0.1, UpdateTooltipPhysicalResistanceValue); });
  hookPanel.style.width = '100%';
  hookPanel.style.height = '100%';
  GameEvents.Subscribe('dota_portrait_unit_stats_changed', UpdateAltDisplayPhysicalResistanceValue);
  GameEvents.Subscribe('dota_portrait_unit_modifiers_changed', UpdateAltDisplayPhysicalResistanceValue);
  GameEvents.Subscribe('dota_player_update_hero_selection', UpdateAltDisplayPhysicalResistanceValue);
  GameEvents.Subscribe('dota_player_update_selected_unit', UpdateAltDisplayPhysicalResistanceValue);
  GameEvents.Subscribe('dota_player_update_query_unit', UpdateAltDisplayPhysicalResistanceValue);
}());
function UpdateTooltipPhysicalResistanceValue () {
  var physicalResistLabel = FindDotaHudElement('PhysicalResist');
  var unit = Players.GetLocalPlayerPortraitUnit();
  if (physicalResistLabel != null) {
    var unitArmor = Entities.GetPhysicalArmorValue(unit);
    var physicalResistance;
    if (HasModifier(unit, 'modifier_legacy_armor')) {
      physicalResistance = Math.round(0.05 * unitArmor / (1 + 0.05 * Math.abs(unitArmor)) * 100);
      physicalResistLabel.text = physicalResistance + '%';
    } else {
      physicalResistance = Math.round(0.052 * unitArmor / (0.9 + 0.048 * Math.abs(unitArmor)) * 100);
      physicalResistLabel.text = physicalResistance + '%';
    }
  }
}
function UpdateAltDisplayPhysicalResistanceValue () {
  var physicalResistLabel = FindDotaHudElement('PhysicalDamageResist');
  var unit = Players.GetLocalPlayerPortraitUnit();
  if (physicalResistLabel != null) {
    var unitArmor = Entities.GetPhysicalArmorValue(unit);
    var physicalResistance;
    if (HasModifier(unit, 'modifier_legacy_armor')) {
      physicalResistance = Math.round(0.05 * unitArmor / (1 + 0.05 * Math.abs(unitArmor)) * 100);
      physicalResistLabel.text = physicalResistance + '%';
    } else {
      physicalResistance = Math.round(0.052 * unitArmor / (0.9 + 0.048 * Math.abs(unitArmor)) * 100);
      physicalResistLabel.text = physicalResistance + '%';
    }
  }
}

function FindModifier (unit, modifier) {
  for (var i = 0; i < Entities.GetNumBuffs(unit); i++) {
    if (Buffs.GetName(unit, Entities.GetBuff(unit, i)) === modifier) {
      return Entities.GetBuff(unit, i);
    }
  }
}

function HasModifier (unit, modifier) {
  return !!FindModifier(unit, modifier);
}
