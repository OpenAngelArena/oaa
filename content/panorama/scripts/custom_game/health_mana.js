/* global FindDotaHudElement, GameEvents, Players, CustomNetTables, DOTA_GameState */
'use strict';

let HealthRegenLabel = null;
let ManaRegenLabel = null;

// subscribe only after the game start (fix loading problems)
GameEvents.Subscribe('oaa_state_change', function (args) {
  if (args.newState >= DOTA_GameState.DOTA_GAMERULES_STATE_GAME_IN_PROGRESS) {
    const HealthManaContainer = FindDotaHudElement('HealthManaContainer');

    // Populate global elements
    HealthRegenLabel = HealthManaContainer.FindChildTraverse('HealthRegenLabel');
    ManaRegenLabel = HealthManaContainer.FindChildTraverse('ManaRegenLabel');

    // Subscribe
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

    CustomNetTables.SubscribeNetTableListener('entity_stats', onEntityStatChange);
  }
});

function HandleStatChange () {
  const selectedEntity = Players.GetLocalPlayerPortraitUnit();
  GameEvents.SendCustomGameEventToServer('statprovider_entities_request', {
    entity: selectedEntity
  });
  onEntityStatChange(null, selectedEntity, CustomNetTables.GetTableValue('entity_stats', selectedEntity));
}

function onEntityStatChange (arg, updatedEntity, data) {
  const selectedEntity = Players.GetLocalPlayerPortraitUnit();
  if (String(updatedEntity) !== String(selectedEntity) || !data) { return; }

  if (HealthRegenLabel !== null) {
    HealthRegenLabel.text = FormatRegen(data.HealthRegen);
  }

  if (ManaRegenLabel !== null) {
    ManaRegenLabel.text = FormatRegen(data.ManaRegen);
  }
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
