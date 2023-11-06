/* global FindDotaHudElement, $, Players, Entities, Game, GameEvents, DOTAKeybindCommand_t, GameUI, CLICK_BEHAVIORS, Abilities, ABILITY_TYPES */
'use strict';

// CSS classes
const cssTalendWindowOpen = 'Talent_Window_open';
const cssOverlaySelected = 'visible_overlay';
const cssTalentLearned = 'talentImageLearned';
const cssTalentButtonUpgradeReady = 'upgradeAvailable';
const cssTalentUnlearnable = 'talentImageUnlearnable';
const cssTalentLearnable = 'talentLearnableGlow';
// Selected units
let currentlySelectedUnitID;
let lastSelectedUnitID;
// Panels
const contextPanel = $.GetContextPanel();
const HUDElements = FindDotaHudElement('HUDElements');
const centerBlock = HUDElements.FindChildTraverse('center_block');
let hudButtonContainer;
let hudButton;
let hudOverlay;
let hudScene;
let talentWindow;
// Bools
let isTalentWindowCurrentlyOpen = false; // when you load in, talent window is not supposed to be visible
let isTalentButtonVisible = true; // when you load in, talent button is supposed to be visible, because you hero is selected

function RemoveDotaTalentTree () {
  // Find the talent tree
  const talentTree = centerBlock.FindChildTraverse('StatBranch');
  // Collapse the talent tree
  talentTree.style.visibility = 'collapse';
  // Disable clicking on the talent tree
  talentTree.SetPanelEvent('onactivate', function () {});
  // Disable hovering over the talent tree
  talentTree.SetPanelEvent('onmouseover', function () {});
  // Disable context menu for the talent tree
  talentTree.SetPanelEvent('oncontextmenu', function () {});
  // Find level up frame for the talent tree
  const levelUpButton = centerBlock.FindChildTraverse('level_stats_frame');
  // Collapse level up button/frame above the talent tree
  levelUpButton.style.visibility = 'collapse';
}

function CreateCustomHudTalentButton () {
  // Find the ability bar
  const abilityBar = centerBlock.FindChildTraverse('StatBranch').GetParent();

  // Find the ability list
  const abilityList = abilityBar.FindChildTraverse('StatBranch');

  // Delete previous instances of 'talent_btn_container' for testing purposes in tools,
  // because of constant recompiling after every change
  const old = abilityBar.FindChildTraverse('talent_btn_container');
  if (old) {
    old.DeleteAsync(0);
  }

  // New talent button container
  hudButtonContainer = $.CreatePanel('Panel', abilityBar, 'talent_btn_container');
  hudButtonContainer.BLoadLayout('file://{resources}/layout/custom_game/custom_talent_hud.xml', true, false);
  hudButtonContainer.SetParent(abilityBar);
  abilityBar.MoveChildAfter(hudButtonContainer, abilityList);

  // Find the button inside the container (custom_talent_hud.xml has the talent_hud_btn button)
  hudButton = hudButtonContainer.FindChildTraverse('talent_hud_btn');
  // Set that button to react on click, open or close the new custom talent window
  hudButton.SetPanelEvent('onactivate', function () { ToggleTalentWindow(); });
  hudButton.SetPanelEvent('oncontextmenu', function () { ToggleTalentWindow(); });
  // Find the Panel that will indicate if the button is pressed
  hudOverlay = hudButtonContainer.FindChildTraverse('talent_hud_btn_overlay');
  // Find the DOTAScenePanel that will indicate if the button is pressed
  hudScene = hudButtonContainer.FindChildTraverse('talent_hud_scene');
}

function InitializeHeroTalents () {
  // Prevent talent initialization multiple times if the last selected hero is the same
  // For example spam clicking the hero would trigger this multiple times
  if (lastSelectedUnitID === currentlySelectedUnitID) return;

  const talentWindowChildren = talentWindow.Children();
  const talentRowCount = talentWindow.GetChildCount(); // 5 rows for now, but the following code allows more
  const normalTalents = [];

  // Filter out talents out of all abilities and add them to the normalTalents array
  for (let index = 0; index < Entities.GetAbilityCount(currentlySelectedUnitID); index++) {
    const ability = Entities.GetAbility(currentlySelectedUnitID, index);
    if (ability) {
      if (Entities.IsValidEntity(ability)) {
        const abilityName = Abilities.GetAbilityName(ability);
        if (Abilities.GetAbilityType(ability) === ABILITY_TYPES.ABILITY_TYPE_ATTRIBUTES && abilityName !== 'special_bonus_attributes') {
          normalTalents.push(abilityName);
        }
      }
    }
  }

  // Add talents to the talent tree.
  // Keep in mind that Ability10 (normalTalents[0]) is a right talent. Ability11 is left etc.
  for (let index = 1; index < talentRowCount; index++) {
    const talentRow = talentWindowChildren[index];
    const requiredLevel = talentRow.FindChildrenWithClassTraverse('talentLevel')[0].text;
    // talentRow.FindChildrenWithClassTraverse('talentLevel')[0].text is the same as:
    // talentRow.Children()[0].Children()[0].Children()[0].text;
    // talentRow.GetChild(0).GetChild(0).GetChild(0).text;
    if (requiredLevel === '55') {
      const leftTalentSuper = talentRow.FindChildrenWithClassTraverse('leftTalentSuper')[0];
      const rightTalentSuper = talentRow.FindChildrenWithClassTraverse('rightTalentSuper')[0];
      leftTalentSuper.GetChild(0).text = 'Super Talent Left';
      leftTalentSuper.SetPanelEvent('onmouseover', function () { $.DispatchEvent('DOTAShowTextTooltip', leftTalentSuper, 'Description left'); });
      leftTalentSuper.SetPanelEvent('onmouseout', function () { $.DispatchEvent('DOTAHideTextTooltip'); });
      rightTalentSuper.GetChild(0).text = 'Super Talent Right';
      rightTalentSuper.SetPanelEvent('onmouseover', function () { $.DispatchEvent('DOTAShowTextTooltip', rightTalentSuper, 'Description right'); });
      rightTalentSuper.SetPanelEvent('onmouseout', function () { $.DispatchEvent('DOTAHideTextTooltip'); });
    } else {
      const rightTalent = talentRow.FindChildrenWithClassTraverse('rightTalent')[0];
      const leftTalent = talentRow.FindChildrenWithClassTraverse('leftTalent')[0];
      let rightTalentName = 'right';
      let leftTalentName = 'left';
      if (requiredLevel === '10') {
        rightTalentName = normalTalents[0];
        leftTalentName = normalTalents[1];
      } else if (requiredLevel === '15') {
        rightTalentName = normalTalents[2];
        leftTalentName = normalTalents[3];
      } else if (requiredLevel === '20') {
        rightTalentName = normalTalents[4];
        leftTalentName = normalTalents[5];
      } else if (requiredLevel === '25') {
        rightTalentName = normalTalents[6];
        leftTalentName = normalTalents[7];
      }
      // Localize talent tooltips (crashes the game to Desktop if the second argument (context panel) is undefined)
      rightTalent.GetChild(0).text = $.Localize('#DOTA_Tooltip_Ability_' + rightTalentName, rightTalent.GetChild(0));
      leftTalent.GetChild(0).text = $.Localize('#DOTA_Tooltip_Ability_' + leftTalentName, leftTalent.GetChild(0));
      const rightTalentDescription = $.Localize('#DOTA_Tooltip_Ability_' + rightTalentName + '_Description', rightTalent.GetChild(0));
      const leftTalentDescription = $.Localize('#DOTA_Tooltip_Ability_' + leftTalentName + '_Description', leftTalent.GetChild(0));
      // Check if talent descriptions exist before setting panel events (Localize will return the input string if localization not found)
      if (rightTalentDescription !== '#DOTA_Tooltip_Ability_' + rightTalentName + '_Description') {
        rightTalent.SetPanelEvent('onmouseover', function () { $.DispatchEvent('DOTAShowTextTooltip', rightTalent, rightTalentDescription); });
        rightTalent.SetPanelEvent('onmouseout', function () { $.DispatchEvent('DOTAHideTextTooltip'); });
      }
      if (leftTalentDescription !== '#DOTA_Tooltip_Ability_' + leftTalentName + '_Description') {
        leftTalent.SetPanelEvent('onmouseover', function () { $.DispatchEvent('DOTAShowTextTooltip', leftTalent, leftTalentDescription); });
        leftTalent.SetPanelEvent('onmouseout', function () { $.DispatchEvent('DOTAHideTextTooltip'); });
      }
    }
  }

  lastSelectedUnitID = currentlySelectedUnitID;

  if (!Entities.IsRealHero(currentlySelectedUnitID) || !Entities.IsControllableByPlayer(currentlySelectedUnitID, Players.GetLocalPlayer())) return;

  for (let index = 1; index < talentRowCount; index++) {
    const talentRow = talentWindowChildren[index];
    const requiredLevel = talentRow.FindChildrenWithClassTraverse('talentLevel')[0].text;
    let rightTalent = talentRow.FindChildrenWithClassTraverse('rightTalent')[0];
    let leftTalent = talentRow.FindChildrenWithClassTraverse('leftTalent')[0];
    if (!rightTalent) {
      rightTalent = talentRow.FindChildrenWithClassTraverse('rightTalentSuper')[0];
    }
    if (!leftTalent) {
      leftTalent = talentRow.FindChildrenWithClassTraverse('leftTalentSuper')[0];
    }
    rightTalent.SetPanelEvent('onactivate', function () { LearnTalent(rightTalent, requiredLevel); });
    leftTalent.SetPanelEvent('onactivate', function () { LearnTalent(leftTalent, requiredLevel); });
    MakeTalentUnlearnable(rightTalent);
    MakeTalentUnlearnable(leftTalent);
  }
}

function MakeTalentUnlearnable (talent) {
  // Don't make the talent unlearnable if it's already unlearnable or learnable
  if (!talent.BHasClass(cssTalentLearnable) && !talent.BHasClass(cssTalentUnlearnable)) {
    talent.AddClass(cssTalentUnlearnable);
  }
}

function MakeOtherTalentUnlearnable (talent) {
  const talentRow = talent.GetParent();
  let rightTalent = talentRow.FindChildrenWithClassTraverse('rightTalent')[0];
  let leftTalent = talentRow.FindChildrenWithClassTraverse('leftTalent')[0];
  if (!rightTalent) {
    rightTalent = talentRow.FindChildrenWithClassTraverse('rightTalentSuper')[0];
  }
  if (!leftTalent) {
    leftTalent = talentRow.FindChildrenWithClassTraverse('leftTalentSuper')[0];
  }
  let otherTalent;
  if (talent === rightTalent) {
    otherTalent = leftTalent;
  } else if (talent === leftTalent) {
    otherTalent = rightTalent;
  }
  // Mark the other talent unlearnable if not already learned
  if (!otherTalent.BHasClass(cssTalentLearned) && otherTalent.BHasClass(cssTalentLearnable)) {
    otherTalent.RemoveClass(cssTalentLearnable);
    otherTalent.AddClass(cssTalentUnlearnable);
  }
}

function GetHeroTalents () {
  const currentlySelectedUnit = Players.GetLocalPlayerPortraitUnit();

  // Do nothing if the current selected unit is not a hero
  if (!Entities.IsHero(currentlySelectedUnit)) return;

  if (currentlySelectedUnit !== currentlySelectedUnitID) {
    // Update currently selected hero unit
    currentlySelectedUnitID = currentlySelectedUnit;
  }

  // Update talents
  if (currentlySelectedUnitID) {
    InitializeHeroTalents();
  }
}

function ToggleTalentWindow () {
  const currentEntity = Players.GetLocalPlayerPortraitUnit();
  // Currently closed: open!
  if (!isTalentWindowCurrentlyOpen) {
    // Prevent opening talent window if a hero is not selected
    if (Entities.IsValidEntity(currentEntity) && Entities.IsHero(currentEntity)) {
      GetHeroTalents();
      isTalentWindowCurrentlyOpen = true;
      talentWindow.AddClass(cssTalendWindowOpen);
      hudOverlay.AddClass(cssOverlaySelected);
    }
  } else { // Currently open: close!
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
      if (currentlySelectedUnitID !== Players.GetPlayerHeroEntityIndex(Players.GetLocalPlayer())) {
        return false;
      }
    }

    // Ignore illusions
    if (Entities.IsIllusion(currentlySelectedUnitID)) {
      return false;
    }

    // Check if the selected hero has any upgrade points
    if (Entities.GetAbilityPoints(currentlySelectedUnitID) > 0) {
      const talentWindowChildren = talentWindow.Children();
      const talentRowCount = talentWindow.GetChildCount();
      // Check if any talent is learnable
      for (let index = 1; index < talentRowCount; index++) {
        const talentRow = talentWindowChildren[index];
        let rightTalent = talentRow.FindChildrenWithClassTraverse('rightTalent')[0];
        let leftTalent = talentRow.FindChildrenWithClassTraverse('leftTalent')[0];
        if (!rightTalent) {
          rightTalent = talentRow.FindChildrenWithClassTraverse('rightTalentSuper')[0];
        }
        if (!leftTalent) {
          leftTalent = talentRow.FindChildrenWithClassTraverse('leftTalentSuper')[0];
        }
        if (rightTalent.BHasClass(cssTalentLearnable) || leftTalent.BHasClass(cssTalentLearnable)) {
          return true;
        }
      }
    }
  }

  return false;
}

function AnimateTalentTree () {
  if (currentlySelectedUnitID) {
    if (Entities.IsValidEntity(currentlySelectedUnitID) && Entities.IsRealHero(currentlySelectedUnitID) && Entities.IsControllableByPlayer(currentlySelectedUnitID, Players.GetLocalPlayer())) {
      // Animate the talent button
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
      // Animate talent choices (add glow); make them learnable
      $.Schedule(0, function () {
        const talentWindowChildren = talentWindow.Children();
        const talentRowCount = talentWindow.GetChildCount();
        const level = Entities.GetLevel(currentlySelectedUnitID);
        for (let index = 1; index < talentRowCount; index++) {
          const talentRow = talentWindowChildren[index];
          const minLevel = talentRow.FindChildrenWithClassTraverse('talentLevel')[0].text;
          let rightTalent = talentRow.FindChildrenWithClassTraverse('rightTalent')[0];
          let leftTalent = talentRow.FindChildrenWithClassTraverse('leftTalent')[0];
          if (!rightTalent) {
            rightTalent = talentRow.FindChildrenWithClassTraverse('rightTalentSuper')[0];
          }
          if (!leftTalent) {
            leftTalent = talentRow.FindChildrenWithClassTraverse('leftTalentSuper')[0];
          }
          if (!rightTalent.BHasClass(cssTalentLearned) && !leftTalent.BHasClass(cssTalentLearned) && level >= minLevel) {
            // if both talents in a row are unlearned, and hero level >= minLevel, then make both talents learnable
            rightTalent.RemoveClass(cssTalentUnlearnable);
            rightTalent.AddClass(cssTalentLearnable);
            leftTalent.RemoveClass(cssTalentUnlearnable);
            leftTalent.AddClass(cssTalentLearnable);
          }
          if ((minLevel === '10' && level >= 15) || (minLevel === '15' && level >= 20) || (minLevel === '20' && level >= 35) || (minLevel === '25' && level >= 45) || (minLevel === '55' && level >= 60)) {
            // if one of the talents in a row is already learned, if level is >= required level, make the other learnable
            if (rightTalent.BHasClass(cssTalentLearned) && !leftTalent.BHasClass(cssTalentLearned)) {
              leftTalent.RemoveClass(cssTalentUnlearnable);
              leftTalent.AddClass(cssTalentLearnable);
            } else if (!rightTalent.BHasClass(cssTalentLearned) && leftTalent.BHasClass(cssTalentLearned)) {
              rightTalent.RemoveClass(cssTalentUnlearnable);
              rightTalent.AddClass(cssTalentLearnable);
            }
          }
        }
      });
    }
  }
}

function CloseTalentWindowUnitDeselected () {
  const unitIDPortrait = Players.GetLocalPlayerPortraitUnit();

  if (isTalentWindowCurrentlyOpen) {
    // If this is another hero, then refill the talent window without closing it
    if (Entities.IsHero(unitIDPortrait)) {
      GetHeroTalents();
    } else { // Close the window
      ToggleTalentWindow();
    }
  }
}

// Show the talent button only for heroes
function ToggleTalentButton () {
  const currentEntity = Players.GetLocalPlayerPortraitUnit();
  if (isTalentButtonVisible) {
    if (!Entities.IsValidEntity(currentEntity) || !Entities.IsHero(currentEntity)) {
      hudButtonContainer.style.visibility = 'collapse';
      isTalentButtonVisible = false;
    }
  } else {
    if (Entities.IsValidEntity(currentEntity) && Entities.IsHero(currentEntity)) {
      hudButtonContainer.style.visibility = 'visible';
      isTalentButtonVisible = true;
    }
  }
}

function CheckSelectedAndAnimate () {
  CloseTalentWindowUnitDeselected();
  ToggleTalentButton();
  AnimateTalentTree();
  GetHeroTalents();
}

function LearnTalent (talent, minLevel) {
  if (GameUI.IsAltDown()) {
    // Pinging talents
    if (talent.BHasClass(cssTalentLearned)) {
      // Send the event to server with message: 'Talent ready' if ally, 'Beware talent' if enemy
    } else if (talent.BHasClass(cssTalentLearnable)) {
      // Send the event to server with message: 'Talent required level' if ally, if enemy, no message
    } else if (talent.BHasClass(cssTalentUnlearnable)) {
      // Send the event to server with message: 'Talent not learned'
    }
  } else {
    // If talent is learned or unlearnable, do nothing
    if (talent.BHasClass(cssTalentLearned) || talent.BHasClass(cssTalentUnlearnable)) return;

    if (currentlySelectedUnitID) {
      if (Entities.IsValidEntity(currentlySelectedUnitID) && Entities.IsRealHero(currentlySelectedUnitID) && Entities.IsControllableByPlayer(currentlySelectedUnitID, Players.GetLocalPlayer())) {
        // Check if the selected hero has any upgrade points
        if (Entities.GetAbilityPoints(currentlySelectedUnitID) > 0) {
          // Get hero level
          const level = Entities.GetLevel(currentlySelectedUnitID);
          if (level >= minLevel && talent.BHasClass(cssTalentLearnable)) {
            // Send the event to server to learn the talent

            // Remove the glow and mark as learned
            talent.RemoveClass(cssTalentLearnable);
            talent.AddClass(cssTalentLearned);

            $.Msg('Learned talent is: ' + talent.GetChild(0).text);

            MakeOtherTalentUnlearnable(talent);
          }
        }
      }
    }
  }
}

function ConfigureTalentLearnHotkeys () {
  // const talentRightHotkey = Game.GetKeybindForCommand(DOTAKeybindCommand_t.DOTA_KEYBIND_TALENT_UPGRADE_RIGHT);
  // const talentLeftHotkey = Game.GetKeybindForCommand(DOTAKeybindCommand_t.DOTA_KEYBIND_TALENT_UPGRADE_LEFT);
  // const commandName1 = 'TalentRightHotkey' + Date.now().toString();
  // Game.CreateCustomKeyBind(talentRightHotkey, commandName1);
  // Game.AddCommand(commandName1, function () { }, '', 0);
  // const commandName2 = 'TalentLeftHotkey' + Date.now().toString();
  // Game.CreateCustomKeyBind(talentLeftHotkey, commandName2);
  // Game.AddCommand(commandName2, function () { }, '', 0);
}

function RecurseEnableFocus (panel) {
  panel.SetAcceptsFocus(true);
  const children = panel.Children();

  children.forEach(function (child) {
    RecurseEnableFocus(child);
  });
}

function ConfigureTalentButtonHotkey () {
  const talentHotkey = Game.GetKeybindForCommand(DOTAKeybindCommand_t.DOTA_KEYBIND_LEARN_STATS);
  const commandName = 'AttributeHotkey' + Date.now().toString();
  Game.CreateCustomKeyBind(talentHotkey, commandName);
  Game.AddCommand(commandName, function () { ToggleTalentWindow(); }, '', 0);

  // Enable focus for talent window children (this is to allow catching of Escape button)
  RecurseEnableFocus(contextPanel);

  $.RegisterKeyBind(contextPanel, 'key_escape', function () {
    if (isTalentWindowCurrentlyOpen) {
      ToggleTalentWindow();
    }
  });

  // Allow mouse clicks outside the talent window to close it.
  GameUI.SetMouseCallback(function (event, value) {
    if (isTalentWindowCurrentlyOpen && value === CLICK_BEHAVIORS.DOTA_CLICK_BEHAVIOR_NONE) {
      if (event === 'pressed') {
        const cursorPos = GameUI.GetCursorPosition();
        if (cursorPos[0] < talentWindow.actualxoffset || talentWindow.actualxoffset + talentWindow.contentwidth < cursorPos[0] || cursorPos[1] < talentWindow.actualyoffset || talentWindow.actualyoffset + talentWindow.contentheight < cursorPos[1]) {
          const currentUnit = currentlySelectedUnitID;
          $.Schedule(0, function () {
            // Only close the window if we didn't change the selection of units
            if (Players.GetLocalPlayerPortraitUnit() === currentUnit) {
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
  talentWindow = $('#TalentsHeader').GetParent(); // returns OAA_Talent_Window panel
  RemoveDotaTalentTree();
  CreateCustomHudTalentButton();
  GetHeroTalents();
  GameEvents.Subscribe('dota_player_gained_level', AnimateTalentTree);
  GameEvents.Subscribe('dota_player_learned_ability', AnimateTalentTree);
  GameEvents.Subscribe('dota_player_update_query_unit', CheckSelectedAndAnimate);
  GameEvents.Subscribe('dota_player_update_selected_unit', CheckSelectedAndAnimate);
  // GameEvents.Subscribe("confirm_talent_learned", (event) => OnTalentLearnedConfirmed(event));
  ConfigureTalentButtonHotkey();
  ConfigureTalentLearnHotkeys();
})();
