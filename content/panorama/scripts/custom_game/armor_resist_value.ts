/* global GameEvents, FindDotaHudElement */
'use strict';

(function () {
  let stats_tooltip_region = FindDotaHudElement('stats_tooltip_region');
  // Create a child panel to occupy the same space so that we can listen for mouse over events
  let hook_panel = $.CreatePanel('Panel', stats_tooltip_region, 'stats_tooltip_region_hook');
  hook_panel.SetPanelEvent(PanelEvent.ON_MOUSE_OVER, () => $.Schedule(0.1, UpdateTooltipPhysicalResistanceValue));
  hook_panel.style.width = '100%';
  hook_panel.style.height = '100%';

  GameEvents.Subscribe('dota_portrait_unit_stats_changed', UpdateAltDisplayPhysicalResistanceValue);
  GameEvents.Subscribe('dota_portrait_unit_modifiers_changed', UpdateAltDisplayPhysicalResistanceValue);
  GameEvents.Subscribe('dota_player_update_hero_selection', UpdateAltDisplayPhysicalResistanceValue);
  GameEvents.Subscribe('dota_player_update_selected_unit', UpdateAltDisplayPhysicalResistanceValue);
}())

function UpdateTooltipPhysicalResistanceValue() {
  let physical_resist_label = <LabelPanel>FindDotaHudElement('PhysicalResist');
  if (physical_resist_label != null) {
    let unit_armor = Entities.GetPhysicalArmorValue(Players.GetLocalPlayerPortraitUnit());
    let physical_resistance = Math.round(0.05 * unit_armor / (1 + 0.05 * unit_armor) * 100);
    physical_resist_label.text = physical_resistance + '%';
  }
}

function UpdateAltDisplayPhysicalResistanceValue() {
  let physical_resist_label = <LabelPanel>FindDotaHudElement('PhysicalDamageResist');
  if (physical_resist_label != null) {
    let unit_armor = Entities.GetPhysicalArmorValue(Players.GetLocalPlayerPortraitUnit());
    let physical_resistance = Math.round(0.05 * unit_armor / (1 + 0.05 * unit_armor) * 100);
    physical_resist_label.text = physical_resistance + '%';
  }
}
