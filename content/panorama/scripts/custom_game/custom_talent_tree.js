/* global FindDotaHudElement, $, Players, Entities, Game, Abilities, GameEvents, DOTAKeybindCommand_t, GameUI, CLICK_BEHAVIORS */
'use strict';

const contextPanel = $.GetContextPanel();
const HUDElements = FindDotaHudElement('HUDElements');
const centerBlock = HUDElements.FindChildTraverse('center_block');
// CSS classes
const cssTalendWindowOpen = 'Talent_Window_open';
const cssOverlaySelected = 'visible_overlay';
const cssTalentLearned = 'talentImageLearned';
const cssTalentButtonUpgradeReady = 'upgradeAvailable';
const cssTalentUnlearnable = 'talentImageUnlearnable';
const cssTalentLearnable = 'talentLearnableGlow';
let currentlySelectedUnitID;
let hudButtonContainer;
let hudButton;
let hudOverlay;
let hudScene;
let talentWindow;
let isTalentWindowCurrentlyOpen = false;
let isHudCurrentlyVisible = true;

function RemoveDotaTalentTree () {
  // Find the talent tree
  const talentTree = centerBlock.FindChildTraverse('StatBranch');
  // Collapse the talent tree
  talentTree.style.visibility = 'collapse';
  // Disable clicking on the talent tree
  talentTree.SetPanelEvent('onactivate', function () {});
  // Disable hovering over the talent tree
  talentTree.SetPanelEvent('onmouseover', function () {});
  // Find level up frame for the talent tree
  const levelUpButton = centerBlock.FindChildTraverse('level_stats_frame');
  // Collapse level up button/frame above the talent tree
  levelUpButton.style.visibility = 'collapse';
}

function CreateHudTalentButton () {
  // Find the ability bar
  const abilityBar = centerBlock.FindChildTraverse('StatBranch').GetParent();

	// Delete previous instances of 'talent_btn_container' for testing purposes in tools,
  // because of constant recompiling after every change
  const old = abilityBar.FindChildTraverse('talent_btn_container');
  if (old) {
    old.DeleteAsync(0);
  }

  // New talent button container
  hudButtonContainer = $.CreatePanel('Panel', abilityBar, 'talent_btn_container');
  //const abilityList = abilityBar.FindChildTraverse('StatBranch');
  hudButtonContainer.BLoadLayout("file://{resources}/layout/custom_game/custom_talent_hud.xml", true, false);
  //hudButtonContainer.SetParent(abilityBar);
  //abilityBar.MoveChildAfter(hudButtonContainer, abilityList);

  // Find the button inside the container
  hudButton = hudButtonContainer.FindChildTraverse('talent_hud_btn');
  hudButton.SetPanelEvent('onactivate', function () { ToggleTalentWindow(); });
  hudOverlay = hudButtonContainer.FindChildTraverse('talent_hud_btn_overlay');
  hudScene = hudButtonContainer.FindChildTraverse('talent_hud_scene');
}

/*
function InitializeHeroTalents() {
  // Clear the rows set
  currentlyPickedRowsSet.clear();

  // Delete the current talents, if any
  talentMap.clear();

  if (!talentSetMap.has(currentlySelectedUnitID)) {
    // Count how many abilities this unit actually has
    let abilityCount = 0;
    for (let index = 0; index < Entities.GetAbilityCount(currentlySelectedUnitID); index++) {
      const ability = Entities.GetAbility(currentlySelectedUnitID!, index);
      if (Entities.IsValidEntity(ability)) abilityCount++;
      else break;
    }

    // Assign the last abilities to the array
    let abilitySet: AbilityEntityIndex[] = [];
    let ability;
    for (let index = 0; index < talentsCount; index++) {
      const abilityIndex = abilityCount - talentsCount + index;
      ability = Entities.GetAbility(currentlySelectedUnitID!, abilityIndex);
      abilitySet[index] = ability;
    }

    talentSetMap.set(currentlySelectedUnitID, abilitySet);
  }

  // Find all talents abilities
  const abilitySet = talentSetMap.get(currentlySelectedUnitID)!;

  let rowNum = 1;
  let ability;
  for (let index = 1; index <= talentsCount; index++) {
    // Get talent button
    const talentIDString: string = "#" + abilityTalentButtonID + index;
    const talentButton: DOTAAbilityImage = $(talentIDString) as DOTAAbilityImage;

    // Get amount of abilities that this hero has - talents would always be his last abilities
    ability = abilitySet[index - 1];

    // Map the button to the ability
    talentMap.set(talentButton, ability);

    // Clear the unlearnable style if it has one
    if (talentButton.BHasClass(cssTalentUnlearnable)) {
      talentButton.RemoveClass(cssTalentUnlearnable);
    }

    // Change the image to the ability's texture
    talentButton.abilityname = Abilities.GetAbilityName(ability);

    // If talent is already learned, add the learned class to it
    if (Abilities.GetLevel(ability) > 0) {
      talentButton.AddClass(cssTalentLearned);

      // Mark this row as a row with a learned talent
      currentlyPickedRowsSet.add(rowNum);
    } else {
      // Remove it from talents that weren't learned when switching to another unit
      if (talentButton.BHasClass(cssTalentLearned)) {
        talentButton.RemoveClass(cssTalentLearned);
      }
    }

    // Increment row every two talents
    if (index % 2 == 0) {
      rowNum++;
    }
  }

  // Run again: find all talents that should be disabled. This is needed due to some talents not being attached yet in the first loop
  for (const button of talentMap.keys()) {
    const ability = talentMap.get(button)!;
    if (Abilities.GetLevel(ability) == 0 && currentlyPickedRowsSet.has(GetTalentRow(ability)!)) {
      button.AddClass(cssTalentUnlearnable);
    }
  }

  // Reinitialize button events
  ConfigureTalentAbilityButtons();
}
*/
function GetHeroTalents() {
  const currentlySelectedUnit = Players.GetLocalPlayerPortraitUnit();

  // Do nothing if the current player is not a hero
  if (!Entities.IsHero(currentlySelectedUnit)) return;

  if (currentlySelectedUnit != currentlySelectedUnitID) {
    // Update currently selected hero unit
    currentlySelectedUnitID = currentlySelectedUnit;

    // Update talents
    // InitializeHeroTalents();
  }
}

function ToggleTalentWindow () {
  // Currently closed: open!
  if (!isTalentWindowCurrentlyOpen) {
    GetHeroTalents();
    isTalentWindowCurrentlyOpen = true;
    talentWindow.AddClass(cssTalendWindowOpen);
    hudOverlay.AddClass(cssOverlaySelected);
  } // Currently open: close!
  else {
    isTalentWindowCurrentlyOpen = false;
    talentWindow.RemoveClass(cssTalendWindowOpen);
    Game.EmitSound('ui_chat_slide_out');
    hudOverlay.RemoveClass(cssOverlaySelected);
  }
}

function CanHeroUpgradeAnyTalent () {
  if (currentlySelectedUnitID) {
    // If this is not the hero under the local player's control, return false
    // Allows to see for other heroes in tools
    if (!Game.IsInToolsMode()) {
      if (currentlySelectedUnitID != Players.GetPlayerHeroEntityIndex(Players.GetLocalPlayer())) {
        return false;
      }
    }

    // Ignore illusions
    if (Entities.IsIllusion(currentlySelectedUnitID)) {
      return false;
    }

    // Check if the selected hero has any upgrade points
    if (Entities.GetAbilityPoints(currentlySelectedUnitID) > 0) {
      // Check if any row is unlocked by level
      const level = Entities.GetLevel(currentlySelectedUnitID);
      const requiredLevel = 10;
      if (level >= requiredLevel) {
        return true;
      }
    }
  }

  return false;
}

function AnimateHudTalentButton () {
  if (currentlySelectedUnitID) {
    if (Entities.IsValidEntity(currentlySelectedUnitID) && Entities.IsRealHero(currentlySelectedUnitID) && Entities.IsControllableByPlayer(currentlySelectedUnitID, Players.GetLocalPlayer())) {
      $.Schedule(0, function () {
        if (CanHeroUpgradeAnyTalent()) {
          if (!hudButton.BHasClass(cssTalentButtonUpgradeReady)) {
            hudButton.AddClass(cssTalentButtonUpgradeReady);
            hudScene.AddClass(cssTalentButtonUpgradeReady);
          }
        } else {
          if (hudButton.BHasClass(cssTalentButtonUpgradeReady)) {
            hudButton.RemoveClass(cssTalentButtonUpgradeReady);
            hudScene.RemoveClass(cssTalentButtonUpgradeReady);
          }
        }
      });
    }
  }
}

function CanTalentBeLearned(ability) {
  // If ability is already leveled, return false
  if (Abilities.GetLevel(ability) > 0) {
    return false;
  }

  // If the ability doesn't belong to to the unit being clicked on, return false
  // Only in tools mode: allows to choose talents for other players
  if (!Game.IsInToolsMode()) {
    if (Abilities.GetCaster(ability) != Players.GetPlayerHeroEntityIndex(Players.GetLocalPlayer())) {
      return false;
    }
  }

  // If this is an illusion, return false
  if (Entities.IsIllusion(currentlySelectedUnitID)) {
    return false;
  }

  // If the hero cannot upgrade any talents, return false
  if (!CanHeroUpgradeAnyTalent()) {
    return false;
  }

  // Find which button has the talent and fetch its ID to determine its level requirements
  /*
  let requiredLevel;
  for (const button of talentMap.keys()) {
    if (talentMap.get(button) === ability) {
      requiredLevel = GetTalentRow(ability)! * talentsLevelPerRow;
      break;
    }
  }

  // If ability's level requirement is higher than the hero's level, return false
  const level = Entities.GetLevel(currentlySelectedUnitID);
  if (!requiredLevel || level < requiredLevel) {
    return false;
  }

  // Check if a talent in the same row was picked
  if (currentlyPickedRowsSet.has(GetTalentRow(ability)!)) {
    return false;
  }
  */

  return true;
}

function AnimateLearnableAbilities () {
  /*
  if (currentlySelectedUnitID) {
    if (Entities.IsValidEntity(currentlySelectedUnitID) && Entities.IsRealHero(currentlySelectedUnitID) && Entities.IsControllableByPlayer(currentlySelectedUnitID, Players.GetLocalPlayer())) {
      $.Schedule(0, function () {
        // Cycle between all buttons
        for (const button of talentMap.keys()) {
          const ability = talentMap.get(button);
          if (ability) {
            if (CanTalentBeLearned(ability)) {
              button.AddClass(cssTalentLearnable);
            } else {
              if (button.BHasClass(cssTalentLearnable)) {
                button.RemoveClass(cssTalentLearnable);
              }
            }
          }
        }
      });
    }
  }
  */
}

function AnimateTalentTree () {
  AnimateHudTalentButton();
  AnimateLearnableAbilities();
}

function CloseTalentWindow_UnitDeselected() {
  const unitIDPortrait = Players.GetLocalPlayerPortraitUnit();

  if (isTalentWindowCurrentlyOpen) {
    // If this is another hero, then refill the talent window without closing it
    if (Entities.IsHero(unitIDPortrait)) {
      GetHeroTalents();
    } // Close the window
    else {
      ToggleTalentWindow();
    }
  }
}

function ToggleHud() {
  const currentEntity = Players.GetLocalPlayerPortraitUnit();
  if (isHudCurrentlyVisible) {
    if (!Entities.IsValidEntity(currentEntity) || !Entities.IsHero(currentEntity)) {
      hudButtonContainer.style.visibility = 'collapse';
      isHudCurrentlyVisible = false;
    }
  } else {
    if (Entities.IsValidEntity(currentEntity) && Entities.IsHero(currentEntity)) {
      hudButtonContainer.style.visibility = 'visible';
      isHudCurrentlyVisible = true;
    }
  }
}

function CheckSelectedAndAnimate () {
  CloseTalentWindow_UnitDeselected();
  ToggleHud();
  AnimateHudTalentButton();
  GetHeroTalents();
  AnimateLearnableAbilities();
}

function ConfigureTalentAbilityButtons () {
  // Find all available talents
  // for (let index = 1; index <= talentsCount; index++) {
    // const button = $("#" + abilityTalentButtonID + index);

    // button.SetPanelEvent("onactivate", () => LearnTalent(button));
    // button.SetPanelEvent("onmouseover", () => ShowTooltip(button));
    // button.SetPanelEvent("onmouseout", () => HideTooltip());
  //}
}

function RecurseEnableFocus(panel) {
  panel.SetAcceptsFocus(true);
  const children = panel.Children();

  children.forEach(function(child) {
    RecurseEnableFocus(child);
  });
}

function ConfigureTalentHotkey() {
  const talentHotkey = Game.GetKeybindForCommand(DOTAKeybindCommand_t.DOTA_KEYBIND_LEARN_STATS);
  Game.CreateCustomKeyBind(talentHotkey, 'AttributeHotkey');
  Game.AddCommand('AttributeHotkey', function () { ToggleTalentWindow() }, '', 0);

  // Enable focus for talent window children (this is to allow catching of Escape button)
  RecurseEnableFocus(contextPanel);

  $.RegisterKeyBind(contextPanel, 'key_escape', function () {
    if (isTalentWindowCurrentlyOpen) {
      ToggleTalentWindow();
    }
  });

  // Allow mouse clicks outside the talent window to close it.
  GameUI.SetMouseCallback(function(event, value) {
    if (isTalentWindowCurrentlyOpen && value == CLICK_BEHAVIORS.DOTA_CLICK_BEHAVIOR_NONE) {
      if (event == 'pressed') {
        const cursorPos = GameUI.GetCursorPosition();
        if (cursorPos[0] < talentWindow.actualxoffset || talentWindow.actualxoffset + talentWindow.contentwidth < cursorPos[0] || cursorPos[1] < talentWindow.actualyoffset || talentWindow.actualyoffset + talentWindow.contentheight < cursorPos[1]) {
          const currentUnit = currentlySelectedUnitID;
          $.Schedule(0, function () {
            // Only close the window if we didn't change the selection of units
            if (Players.GetLocalPlayerPortraitUnit() == currentUnit) {
              ToggleTalentWindow();
            }
          });
        }
      }
    }

    return false;
  });
}

(function () {
  talentWindow = contextPanel.FindChildTraverse('CustomUIRoot').FindChildTraverse('CustomUIContainer_Hud').FindChildTraverse('TalentsHeader').GetParent();
  RemoveDotaTalentTree()
  CreateHudTalentButton();
  GameEvents.Subscribe('dota_player_gained_level', AnimateTalentTree);
  GameEvents.Subscribe('dota_player_learned_ability', AnimateTalentTree);
  GameEvents.Subscribe('dota_player_update_query_unit', CheckSelectedAndAnimate);
  GameEvents.Subscribe('dota_player_update_selected_unit', CheckSelectedAndAnimate);
  // GameEvents.Subscribe("confirm_talent_learned", (event) => OnTalentLearnedConfirmed(event));
  // GameEvents.Subscribe("request_currently_selected_unit", () => OnRequestSelectedUnit());
  // InitializeHeroTalents();
  ConfigureTalentAbilityButtons();
  ConfigureTalentHotkey();
})();
