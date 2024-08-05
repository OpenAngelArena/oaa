/* global FindDotaHudElement, $, Players, Entities, Game, GameEvents, DOTAKeybindCommand_t, GameUI, CLICK_BEHAVIORS, Abilities, ABILITY_TYPES, HasModifier */
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
const talentTree = centerBlock.FindChildTraverse('StatBranch');
let hudButtonContainer;
let hudButton;
let hudOverlay;
let hudScene;
let talentWindow;
// Bools
let isTalentWindowCurrentlyOpen = false; // when you load in, talent window is not supposed to be visible
let isTalentButtonVisible = true; // when you load in, talent button is supposed to be visible, because you hero is selected

function RemoveDotaTalentTree () {
  // Find root panels for vanilla talent trees so we can inject new panels into them
  const nameLabel = HUDElements.FindChildTraverse('UpgradeName8');
  const button = nameLabel.GetParent(); // Upgrade8
  const container1 = button.GetParent(); // Upgrade8Container
  const pair1 = container1.GetParent(); // UpgradeOption4
  const root1 = pair1.GetParent(); // StatBranchColumn
  const descriptionLabel = HUDElements.FindChildTraverse('Description8');
  const descriptionPanel = descriptionLabel.GetParent(); // Upgrade8Description
  const descriptionContainer = descriptionPanel.GetParent(); // Upgrade8DescriptionContainer
  const container2 = descriptionContainer.GetParent(); // Upgrade8Container
  const pair2 = container2.GetParent(); // TalentPair4
  const root2 = pair2.GetParent(); // TalentDescriptions

  const old1 = root1.FindChildTraverse('UpgradeOption5');
  const old2 = root2.FindChildTraverse('TalentPair5');
  if (old1) {
    old1.DeleteAsync(0);
  }
  if (old2) {
    old2.DeleteAsync(0);
  }

  // Inject panels into vanilla talent tree for 2 more talents to prevent crashes
  const a1 = $.CreatePanel('Panel', root1, 'UpgradeOption5');
  const b1 = $.CreatePanel('Panel', a1, 'Upgrade9Container');
  const c1 = $.CreatePanel('Button', b1, 'Upgrade9');
  $.CreatePanel('Label', c1, 'UpgradeName9');
  const d1 = $.CreatePanel('Panel', a1, 'Upgrade10Container');
  const e1 = $.CreatePanel('Button', d1, 'Upgrade10');
  $.CreatePanel('Label', e1, 'UpgradeName10');

  const a2 = $.CreatePanel('Panel', root2, 'TalentPair5');
  const b2 = $.CreatePanel('Panel', a2, 'Upgrade9Container');
  const c2 = $.CreatePanel('Panel', b2, 'Upgrade9DescriptionContainer');
  const d2 = $.CreatePanel('Panel', c2, 'Upgrade9Description');
  $.CreatePanel('Label', d2, 'Description9');
  const e2 = $.CreatePanel('Panel', a2, 'Upgrade10Container');
  const f2 = $.CreatePanel('Panel', e2, 'Upgrade10DescriptionContainer');
  const g2 = $.CreatePanel('Panel', f2, 'Upgrade10Description');
  $.CreatePanel('Label', g2, 'Description10');

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
  const abilityBar = talentTree.GetParent();

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
  abilityBar.MoveChildAfter(hudButtonContainer, talentTree);

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

function GetTalentNames (requiredLevel) {
  const names = [];
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

  // Keep in mind that Ability10 (normalTalents[0]) is a right talent. Ability11 is left etc.
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
  } else if (requiredLevel === '55') {
    rightTalentName = normalTalents[8];
    leftTalentName = normalTalents[9];
  }

  names.push(rightTalentName);
  names.push(leftTalentName);

  return names;
}

function InitializeHeroTalents () {
  // Prevent talent initialization multiple times if the last selected hero is the same
  // For example spam clicking the hero would trigger this multiple times
  if (lastSelectedUnitID === currentlySelectedUnitID) return;

  const talentWindowChildren = talentWindow.Children();
  const talentRowCount = talentWindow.GetChildCount(); // 5 rows for now, but the following code allows more

  // Add talents to the talent tree.
  for (let index = 1; index < talentRowCount; index++) {
    const talentRow = talentWindowChildren[index];
    const requiredLevel = talentRow.FindChildrenWithClassTraverse('talentLevel')[0].text;
    // talentRow.FindChildrenWithClassTraverse('talentLevel')[0].text is the same as:
    // talentRow.Children()[0].Children()[0].Children()[0].text;
    // talentRow.GetChild(0).GetChild(0).GetChild(0).text;
    let rightTalent = talentRow.FindChildrenWithClassTraverse('rightTalent')[0];
    let leftTalent = talentRow.FindChildrenWithClassTraverse('leftTalent')[0];
    const aghsTalent = talentRow.FindChildrenWithClassTraverse('aghsTalent')[0];
    if (!rightTalent) {
      rightTalent = talentRow.FindChildrenWithClassTraverse('rightTalentSuper')[0];
    }
    if (!leftTalent) {
      leftTalent = talentRow.FindChildrenWithClassTraverse('leftTalentSuper')[0];
    }

    // TALENTS LOCALIZATION
    const rightTalentName = GetTalentNames(requiredLevel)[0];
    const leftTalentName = GetTalentNames(requiredLevel)[1];
    let aghsTalentName = '';
    // Localize talent tooltips (crashes the game to Desktop if the second argument (context panel) is undefined)
    // rightTalent.GetChild(0).text = $.Localize('#DOTA_Tooltip_Ability_' + rightTalentName, rightTalent.GetChild(0));
    if (rightTalentName) {
      GameUI.SetupDOTATalentNameLabel(rightTalent.GetChild(0), rightTalentName);
    }
    // leftTalent.GetChild(0).text = $.Localize('#DOTA_Tooltip_Ability_' + leftTalentName, leftTalent.GetChild(0));
    if (leftTalentName) {
      GameUI.SetupDOTATalentNameLabel(leftTalent.GetChild(0), leftTalentName);
    }
    const rightTalentDescription = $.Localize('#DOTA_Tooltip_Ability_' + rightTalentName + '_Description', rightTalent.GetChild(0));
    const leftTalentDescription = $.Localize('#DOTA_Tooltip_Ability_' + leftTalentName + '_Description', leftTalent.GetChild(0));
    let aghsTalentDescription = '#_Description';
    if (aghsTalent) {
      const heroName = Entities.GetUnitName(currentlySelectedUnitID);
      aghsTalentName = heroName.replace('npc_dota_hero_', '') + '_aghanim_talent_oaa_' + requiredLevel;
      aghsTalent.GetChild(0).text = $.Localize('#' + aghsTalentName, aghsTalent.GetChild(0));
      aghsTalentDescription = $.Localize('#' + aghsTalentName + '_Description', aghsTalent.GetChild(0));
    }

    // TALENTS PANEL EVENTS
    rightTalent.SetPanelEvent('onmouseover', function () { }); // to not show talent description of some other talent from some other hero
    leftTalent.SetPanelEvent('onmouseover', function () { }); // to not show talent description of some other talent from some other hero
    if (aghsTalent) {
      aghsTalent.SetPanelEvent('onmouseover', function () { }); // to not show talent description of some other talent from some other hero
    }
    // Check if talent descriptions exist before setting panel events (Localize will return the input string if localization not found)
    if (rightTalentDescription !== '#DOTA_Tooltip_Ability_' + rightTalentName + '_Description') {
      rightTalent.SetPanelEvent('onmouseover', function () { $.DispatchEvent('DOTAShowTextTooltip', rightTalent, rightTalentDescription); });
      rightTalent.SetPanelEvent('onmouseout', function () { $.DispatchEvent('DOTAHideTextTooltip'); });
    }
    if (leftTalentDescription !== '#DOTA_Tooltip_Ability_' + leftTalentName + '_Description') {
      leftTalent.SetPanelEvent('onmouseover', function () { $.DispatchEvent('DOTAShowTextTooltip', leftTalent, leftTalentDescription); });
      leftTalent.SetPanelEvent('onmouseout', function () { $.DispatchEvent('DOTAHideTextTooltip'); });
    }
    if (aghsTalent && aghsTalentDescription !== '#' + aghsTalentName + '_Description') {
      aghsTalent.SetPanelEvent('onmouseover', function () { $.DispatchEvent('DOTAShowTextTooltip', aghsTalent, aghsTalentDescription); });
      aghsTalent.SetPanelEvent('onmouseout', function () { $.DispatchEvent('DOTAHideTextTooltip'); });
    }
  }

  lastSelectedUnitID = currentlySelectedUnitID;

  if (!Entities.IsRealHero(currentlySelectedUnitID) || !Entities.IsControllableByPlayer(currentlySelectedUnitID, Players.GetLocalPlayer()) || currentlySelectedUnitID !== Players.GetPlayerHeroEntityIndex(Players.GetLocalPlayer())) return;

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
    if (Entities.IsValidEntity(currentlySelectedUnitID) && Entities.IsRealHero(currentlySelectedUnitID) && currentlySelectedUnitID === Players.GetPlayerHeroEntityIndex(Players.GetLocalPlayer())) {
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

function AnimateAghanimTalents () {
  if (currentlySelectedUnitID) {
    if (Entities.IsValidEntity(currentlySelectedUnitID) && Entities.IsRealHero(currentlySelectedUnitID) && currentlySelectedUnitID === Players.GetPlayerHeroEntityIndex(Players.GetLocalPlayer())) {
      // Animate aghanim talents, make them learned/unlearned
      $.Schedule(0, function () {
        const talentWindowChildren = talentWindow.Children();
        const talentRowCount = talentWindow.GetChildCount();
        for (let index = 1; index < talentRowCount; index++) {
          const talentRow = talentWindowChildren[index];
          const aghsTalent = talentRow.FindChildrenWithClassTraverse('aghsTalent')[0];
          if (aghsTalent) {
            const level = talentRow.FindChildrenWithClassTraverse('talentLevel')[0].text;
            const modifierName = 'modifier_aghanim_talent_oaa_' + level;
            if (HasModifier(currentlySelectedUnitID, modifierName) && !aghsTalent.BHasClass(cssTalentLearned)) {
              aghsTalent.AddClass(cssTalentLearned);
            } else if (aghsTalent.BHasClass(cssTalentLearned)) {
              aghsTalent.RemoveClass(cssTalentLearned);
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
      // Send the event to allied clients with message: 'Talent ready' if ally, 'Beware talent' if enemy
    } else if (talent.BHasClass(cssTalentLearnable)) {
      // Send the event to allied clients with message: 'Talent required level' if ally, 'Beware talent' if enemy
    } else if (talent.BHasClass(cssTalentUnlearnable)) {
      // Send the event to allied clients with message: 'Talent not learned'
    }
  } else {
    // If talent is learned or unlearnable, do nothing
    if (talent.BHasClass(cssTalentLearned) || talent.BHasClass(cssTalentUnlearnable)) return;

    if (currentlySelectedUnitID) {
      if (Entities.IsValidEntity(currentlySelectedUnitID) && Entities.IsRealHero(currentlySelectedUnitID) && currentlySelectedUnitID === Players.GetPlayerHeroEntityIndex(Players.GetLocalPlayer())) {
        // Check if the selected hero has any upgrade points
        if (Entities.GetAbilityPoints(currentlySelectedUnitID) > 0) {
          // Get hero level
          const level = Entities.GetLevel(currentlySelectedUnitID);
          if (level >= minLevel && talent.BHasClass(cssTalentLearnable)) {
            const talentNames = GetTalentNames(minLevel);
            const isRight = talent.BHasClass('rightTalent');
            const isLeft = talent.BHasClass('leftTalent');
            const isAghs = talent.BHasClass('aghsTalent');
            $.Msg(isRight, isLeft, isAghs);
            let talentIndex;
            if (isRight) {
              talentIndex = Entities.GetAbilityByName(currentlySelectedUnitID, talentNames[0]);
            } else if (isLeft) {
              talentIndex = Entities.GetAbilityByName(currentlySelectedUnitID, talentNames[1]);
            }
            // Send the event to server to learn the talent
            if (!isAghs) {
              GameEvents.SendCustomGameEventToServer('custom_learn_talent_event', { ability: talentIndex });
            }
            // Remove the glow and mark as learned
            talent.RemoveClass(cssTalentLearnable);
            talent.AddClass(cssTalentLearned);

            $.Msg('Learned talent is: ' + talent.GetChild(0).text);

            MakeOtherTalentUnlearnable(talent);

            // AnimateTalentTree(); // keep this only if dota_player_learned_ability doesn't trigger it
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
  GameEvents.Subscribe('oaa_aghanim_talent_status_changed', AnimateAghanimTalents);
  GameEvents.Subscribe('dota_player_update_query_unit', CheckSelectedAndAnimate);
  GameEvents.Subscribe('dota_player_update_selected_unit', CheckSelectedAndAnimate);
  ConfigureTalentButtonHotkey();
  ConfigureTalentLearnHotkeys();
})();
