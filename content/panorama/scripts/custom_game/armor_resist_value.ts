/* global GameEvents, Entities, FindDotaHudElement, $, Players */
'use strict';

(function () {
  let statsTooltipRegion = FindDotaHudElement('stats_tooltip_region');
  // Create a child panel to occupy the same space so that we can listen for mouse over events
  let hookPanel = $.CreatePanel('Panel', statsTooltipRegion, 'stats_tooltip_region_hook');
  hookPanel.SetPanelEvent(PanelEvent.ON_MOUSE_OVER, () => $.Schedule(0.1, UpdateTooltipPhysicalResistanceValue));
  hookPanel.style.width = '100%';
  hookPanel.style.height = '100%';

  GameEvents.Subscribe('dota_portrait_unit_stats_changed', UpdateAltDisplayPhysicalResistanceValue);
  GameEvents.Subscribe('dota_portrait_unit_modifiers_changed', UpdateAltDisplayPhysicalResistanceValue);
  GameEvents.Subscribe('dota_player_update_hero_selection', UpdateAltDisplayPhysicalResistanceValue);
  GameEvents.Subscribe('dota_player_update_selected_unit', UpdateAltDisplayPhysicalResistanceValue);
  GameEvents.Subscribe('dota_player_update_query_unit', UpdateAltDisplayPhysicalResistanceValue);
}())

function UpdateTooltipPhysicalResistanceValue () {
  let physicalResistLabel = <LabelPanel>FindDotaHudElement('PhysicalResist');
  if (physicalResistLabel != null) {
    let unitArmor = Entities.GetPhysicalArmorValue(Players.GetLocalPlayerPortraitUnit());
    let physicalResistance = Math.round(0.05 * unitArmor / (1 + 0.05 * Math.abs(unitArmor)) * 100);
    physicalResistLabel.text = physicalResistance + '%';
  }
}

function UpdateAltDisplayPhysicalResistanceValue () {
  let physicalResistLabel = <LabelPanel>FindDotaHudElement('PhysicalDamageResist');
  if (physicalResistLabel != null) {
    let unitArmor = Entities.GetPhysicalArmorValue(Players.GetLocalPlayerPortraitUnit());
    let physicalResistance = Math.round(0.05 * unitArmor / (1 + 0.05 * Math.abs(unitArmor)) * 100);
    physicalResistLabel.text = physicalResistance + '%';
  }
}
