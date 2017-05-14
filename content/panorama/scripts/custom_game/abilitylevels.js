/* global GameEvents, $, FindDotaHudElement */

'use strict';

(function () {
  GameEvents.Subscribe('ability_level_error', DisplayAbilityLevelError);
  GameEvents.Subscribe('check_level_up', CheckLevelUpBubbles);
}());

function DisplayAbilityLevelError (data) {
  // Localise hero level requirement error message and insert hero level number
  var errorMessageText = $.Localize('#dota_hud_error_ability_cant_upgrade_hero_level').replace('%s1', data.requiredLevel);

  var errorData = {reason: 80, message: errorMessageText};
  GameEvents.SendEventClientSide('dota_hud_error_message', errorData);
}

function CheckLevelUpBubbles (data) {
  var canLevelUp = data.canLevelUp;

  var abilitiesPanel = FindDotaHudElement('abilities');
  $.Schedule(0.1, function () {
    abilitiesPanel.Children().forEach(function (abilityPanel, i) {
      var requiredLevel = canLevelUp[i + 1];
      if (!abilityPanel.BHasClass('could_level_up') || requiredLevel === -1 || data.level < requiredLevel) {
        abilityPanel.FindChildTraverse('LevelUpTab').style.opacity = 0;
        abilityPanel.FindChildTraverse('LevelUpLight').style.opacity = 0;
        abilityPanel.FindChildTraverse('LevelUpBurstFXContainer').style.opacity = 0;
      } else {
        abilityPanel.FindChildTraverse('LevelUpTab').style.opacity = 1;
        abilityPanel.FindChildTraverse('LevelUpLight').style.opacity = 1;
        abilityPanel.FindChildTraverse('LevelUpBurstFXContainer').style.opacity = 1;
      }
    });
  });
}
