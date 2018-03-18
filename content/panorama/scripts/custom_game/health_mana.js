/* global FindDotaHudElement, GameEvents, Players, CustomNetTables */
'use strict';

var HudNotFoundException = /** @class */ (function () {
  function HudNotFoundException(message) {
      this.message = message;
  }
  return HudNotFoundException;
}());
function FindDotaHudElement(id) {
  return GetDotaHud().FindChildTraverse(id);
}
function GetDotaHud() {
  var p = $.GetContextPanel();
  while (p !== null && p.id !== 'Hud') {
      p = p.GetParent();
  }
  if (p === null) {
      throw new HudNotFoundException('Could not find Hud root as parent of panel with id: ' + $.GetContextPanel().id);
  }
  else {
      return p;
  }
}

var HealthRegenLabel = null
var ManaRegenLabel = null

// subscribe only after the game start (fix loading problems)
var eventHandler = GameEvents.Subscribe('oaa_state_change', function (args) {
  if (args.newState >= DOTA_GameState.DOTA_GAMERULES_STATE_GAME_IN_PROGRESS) {
    var HealthManaContainer = FindDotaHudElement('HealthManaContainer');

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
  var selectedEntity = Players.GetLocalPlayerPortraitUnit();
  GameEvents.SendCustomGameEventToServer('statprovider_entities_request', {
    entity: selectedEntity
  });
  onEntityStatChange(null, selectedEntity, CustomNetTables.GetTableValue('entity_stats', selectedEntity));
}

function onEntityStatChange (arg, updatedEntity, data) {
  var selectedEntity = Players.GetLocalPlayerPortraitUnit();
  if (String(updatedEntity) !== String(selectedEntity) || !data) { return; }

  if(HealthRegenLabel !== null){
    HealthRegenLabel.text = FormatRegen(data['HealthRegen']);
  }

  if(ManaRegenLabel !== null){
    ManaRegenLabel.text = FormatRegen(data['ManaRegen']);
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
