/* global GameEvents, $, FindDotaHudElement */
'use strict';

(function () {
  GameEvents.Subscribe('dota_player_update_selected_unit', function () {
    $.Schedule(0.1, InjectBottomAbilityDotsStyle);
  });
  GameEvents.Subscribe('dota_player_update_query_unit', function () {
    $.Schedule(0.1, InjectQueryAbilityDotsStyle);
  });
}());

function InjectAbilityDotsStyle (abilitiesPanel, numAbilitiesClassPanel, dotStyles, containerStyles) {
  abilitiesPanel.ApplyStyles(false);
  //  Figure out style groups to apply based on number of abilities
  for (var numAbilitiesClass in dotStyles) {
    if (numAbilitiesClassPanel.BHasClass(numAbilitiesClass)) {
      break;
    }
  }
  //  Loop through ability panels
  abilitiesPanel.Children().forEach(function (abilityPanel) {
    var abilityLevelContainer = abilityPanel.FindChildTraverse('AbilityLevelContainer');
    // Figure out the group of styles in dotStyles to apply
    for (var dotClassName in dotStyles[numAbilitiesClass]) {
      if (abilityPanel.BHasClass(dotClassName)) {
        break;
      }
    }
    if (containerStyles !== null) {
      // Figure out the group of styles in containerStyles to apply
      for (var containerClassName in containerStyles[numAbilitiesClass]) {
        if (abilityPanel.BHasClass(containerClassName)) {
          break;
        }
      }
      // Apply styles to AbilityLevelContainer
      for (var attribute in containerStyles[numAbilitiesClass][containerClassName]) {
        abilityLevelContainer.style[attribute] = containerStyles[numAbilitiesClass][containerClassName][attribute];
      }
    }
    //  Loop through level dots and apply style
    abilityLevelContainer.Children().forEach(function (levelDot) {
      for (var attribute in dotStyles[numAbilitiesClass][dotClassName]) {
        levelDot.style[attribute] = dotStyles[numAbilitiesClass][dotClassName][attribute];
      }
    });
  });
  abilitiesPanel.ApplyStyles(true);
}

function InjectBottomAbilityDotsStyle () {
  var abilitiesPanel = FindDotaHudElement('abilities');
  var numAbilitiesClassPanel = FindDotaHudElement('center_block');
  var dotStyles = {
    SixAbilities: {
      AbilityMaxLevel6: {
        width: '7px',
        margin: '3px 1px 3px 1px'
      },
      AbilityMaxLevel5: {
        width: '7px'
      },
      default: {
        width: null,
        margin: null
      }
    },
    FiveAbilities: {
      AbilityMaxLevel6: {
        width: '7px',
        margin: '3px 1px 3px 1px'
      },
      AbilityMaxLevel5: {
        width: '7px'
      },
      default: {
        width: null,
        margin: null
      }
    },
    default: {
      AbilityMaxLevel6: {
        width: '7px',
        margin: '3px 1.5px 3px 1.5px'
      },
      default: {
        width: null,
        margin: null
      }
    }
  };
  InjectAbilityDotsStyle(abilitiesPanel, numAbilitiesClassPanel, dotStyles, null);
}

function InjectQueryAbilityDotsStyle () {
  var abilitiesPanel = FindDotaHudElement('Abilities');
  var numAbilitiesClassPanel = FindDotaHudElement('QueryUnit');
  var dotStyles = {
    default: {
      AbilityMaxLevel6: {
        width: '3px',
        height: '3px',
        margin: '0px 1.4px 1px 1.4px'
      },
      AbilityMaxLevel5: {
        width: '4px',
        height: '3px',
        margin: '0px 1px 1px 1px'
      },
      default: {
        width: null,
        height: null,
        margin: null
      }
    }
  };
  var containerStyles = {
    AbilityMaxLevel6: {
      'margin-left': '1px'
    },
    default: {
      'margin': null
    }
  };
  InjectAbilityDotsStyle(abilitiesPanel, numAbilitiesClassPanel, dotStyles, containerStyles);
  //  Also call styling function for bottom panel in case user has set unit query to override
  // hero control panel
  InjectBottomAbilityDotsStyle();
}
