/* global FindDotaHudElement, GameEvents, $, Players, CustomNetTables */
'use strict';

(function () {
  GameEvents.Subscribe('player_stats_updated', HandleStatChange);
  GameEvents.Subscribe('dota_portrait_unit_stats_changed', HandleStatChange);
  GameEvents.Subscribe('dota_portrait_unit_modifiers_changed', HandleStatChange);
  GameEvents.Subscribe('dota_inventory_changed', HandleStatChange);
  GameEvents.Subscribe('dota_inventory_item_changed', HandleStatChange);
  GameEvents.Subscribe('dota_inventory_changed_query_unit', HandleStatChange);
  GameEvents.Subscribe('dota_player_update_hero_selection', HandleStatChange);
  GameEvents.Subscribe('dota_player_update_selected_unit', HandleStatChange);
  GameEvents.Subscribe('dota_player_update_query_unit', HandleStatChange);
  GameEvents.Subscribe('dota_ability_changed', HandleStatChange);
}());

var HealthManaContainer = FindDotaHudElement('HealthManaContainer');
var HealthRegenLabel = HealthManaContainer.FindChildTraverse('HealthRegenLabel');
var ManaRegenLabel = HealthManaContainer.FindChildTraverse('ManaRegenLabel');
var blockUpdate = {};

function HandleStatChange () {
  var entity = Players.GetLocalPlayerPortraitUnit();
  if (blockUpdate[String(entity)]) {
    return;
  }
  blockUpdate[String(entity)] = true;
  GameEvents.SendCustomGameEventToServer('statprovider_entities_request', {
    entity: entity
  });
  $.Schedule(0.01, function () {
    UpdateRegenDisplays(entity); blockUpdate[String(entity)] = false;
  });
}

function UpdateRegenDisplays (entity) {
  var stats = CustomNetTables.GetTableValue('entity_stats', String(entity));
  if (!stats) {
    return;
  }

  HealthRegenLabel.text = FormatRegen(stats['HealthRegen']);
  ManaRegenLabel.text = FormatRegen(stats['ManaRegen']); // TODO Values are wrong
}

function FormatRegen (number) {
  if (number > 0) {
    number = '+' + number.toFixed(3);
  } else if (number > 0) {
    number = '-' + number.toFixed(3);
  } else {
    number = '±0.00';
  }

  return number;
}
