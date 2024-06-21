/* global GameEvents, $, FindDotaHudElement, Entities, Players */

'use strict';

(function () {
  GameEvents.Subscribe('ability_level_error', DisplayAbilityLevelError);
  GameEvents.Subscribe('check_level_up', CheckLevelUpBubbles);
  // Handle unit selection changes clientside because server can't get a player's selected units
  GameEvents.Subscribe('dota_player_update_query_unit', CheckLevelUpOnSelectionChange);
  GameEvents.Subscribe('dota_player_update_selected_unit', CheckLevelUpOnSelectionChange);
}());

function DisplayAbilityLevelError (data) {
  // Localise hero level requirement error message and insert hero level number
  const errorMessageText = $.Localize('#dota_hud_error_ability_cant_upgrade_hero_level').replace('%s1', data.requiredLevel);

  const errorData = { reason: 80, message: errorMessageText };
  GameEvents.SendEventClientSide('dota_hud_error_message', errorData);
}

function CheckLevelUpBubbles (data) {
  const canLevelUp = data.canLevelUp;

  const abilitiesPanel = FindDotaHudElement('abilities');
  abilitiesPanel.ApplyStyles(false);
  $.Schedule(0.1, function () {
    abilitiesPanel.Children().forEach(function (abilityPanel, i) {
      const requiredLevel = canLevelUp[i + 1];
      abilityPanel.FindChildTraverse('AbilityLevelContainer').Children().forEach(function (levelDot) {
        levelDot.style.border = null;
        levelDot.style['border-radius'] = null;
        levelDot.style['box-shadow'] = null;
      });
      if (requiredLevel === -1 || data.level < requiredLevel) {
        abilityPanel.RemoveClass('could_level_up');
        abilityPanel.FindChildTraverse('LevelUpTab').style.opacity = 0;
        abilityPanel.FindChildTraverse('LevelUpLight').style.opacity = 0;
        abilityPanel.FindChildTraverse('LevelUpBurstFXContainer').style.visibility = 'collapse';
        const levelDot = abilityPanel.FindChildrenWithClassTraverse('next_level')[0];
        if (levelDot) {
          levelDot.style.border = '0px none black';
          levelDot.style['border-radius'] = '1px';
          levelDot.style['box-shadow'] = 'none';
          levelDot.style['background-image'] = 'none';
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
  const playerID = Players.GetLocalPlayer();
  const selectedEntity = Players.GetLocalPlayerPortraitUnit();
  if (selectedEntity !== undefined) {
    if (Entities.GetPlayerOwnerID(selectedEntity) === playerID && Entities.IsRealHero(selectedEntity)) {
      const level = Entities.GetLevel(selectedEntity);
      GameEvents.SendCustomGameEventToServer('check_level_up_selection', {
        selectedEntity: selectedEntity,
        level: level
      });
    }
  }
}
