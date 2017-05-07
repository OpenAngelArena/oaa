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
  var playerID = Players.GetLocalPlayer();
  var entID = Players.GetPlayerHeroEntityIndex(playerID);
  var level = Players.GetLevel(playerID);
  var canLevelUp = data.canLevelUp;

  var abilitiesPanel = FindDotaHudElement('abilities');
  abilitiesPanel.Children().forEach(function (abilityPanel, i) {
    if (data.level < canLevelUp[i + 1]) {
      $.Schedule(0.1, function() {
        abilityPanel.FindChildTraverse('LevelUpTab').style.opacity = 0;
        abilityPanel.FindChildTraverse('LevelUpLight').style.opacity = 0;
        abilityPanel.FindChildTraverse('LevelUpBurstFXContainer').style.opacity = 0;
      });
    }
  });
}
