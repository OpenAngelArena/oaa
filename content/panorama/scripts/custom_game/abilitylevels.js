/* global GameEvents, $, FindDotaHudElement, Entities, Players */

'use strict';

(function () {
  GameEvents.Subscribe('ability_level_error', DisplayAbilityLevelError);
  GameEvents.Subscribe('check_level_up', CheckLevelUpBubbles);
  // Handle unit selection changes clientside because server can't get a player's selected units
  GameEvents.Subscribe('dota_player_update_selected_unit', CheckLevelUpOnSelectionChange);
}());

function DisplayAbilityLevelError (data) {
  // Localise hero level requirement error message and insert hero level number
  var errorMessageText = $.Localize('#dota_hud_error_ability_cant_upgrade_hero_level').replace('%s1', data.requiredLevel);

  var errorData = { reason: 80, message: errorMessageText };
  GameEvents.SendEventClientSide('dota_hud_error_message', errorData);
}

function CheckLevelUpBubbles (data) {
  var canLevelUp = data.canLevelUp;

  var abilitiesPanel = FindDotaHudElement('abilities');
  abilitiesPanel.ApplyStyles(false);
  $.Schedule(0.1, function () {
    abilitiesPanel.Children().forEach(function (abilityPanel, i) {
      var requiredLevel = canLevelUp[i + 1];
      abilityPanel.FindChildTraverse('AbilityLevelContainer').Children().forEach(function (levelDot) {
        levelDot.style['border'] = null;
        levelDot.style['border-radius'] = null;
        levelDot.style['box-shadow'] = null;
      });
      if (requiredLevel === -1 || data.level < requiredLevel) {
        abilityPanel.FindChildTraverse('LevelUpTab').style.opacity = 0;
        abilityPanel.FindChildTraverse('LevelUpLight').style.opacity = 0;
        abilityPanel.FindChildTraverse('LevelUpBurstFXContainer').style.visibility = 'collapse';
        var levelDot = abilityPanel.FindChildrenWithClassTraverse('next_level')[0];
        if (levelDot) {
          levelDot.style['border'] = '0px none black';
          levelDot.style['border-radius'] = '1px';
          levelDot.style['box-shadow'] = 'none';
        }
      } else {
        abilityPanel.FindChildTraverse('LevelUpTab').style.opacity = null;
        abilityPanel.FindChildTraverse('LevelUpLight').style.opacity = null;
        abilityPanel.FindChildTraverse('LevelUpBurstFXContainer').style.visibility = null;
      }
    });
  });
  abilitiesPanel.ApplyStyles(true);
}

function CheckLevelUpOnSelectionChange (data) {
  var player = Players.GetLocalPlayer();
  var selectedEntity = Players.GetSelectedEntities(player)[0];

  if (selectedEntity !== undefined) {
    var level = Entities.GetLevel(selectedEntity);
    GameEvents.SendCustomGameEventToServer('check_level_up_selection', {
      selectedEntity: selectedEntity,
      level: level
    });
  }
}
