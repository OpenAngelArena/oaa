/* global $ GameEvents CustomNetTables FindDotaHudElement Game */

const heroNamePanel = FindDotaHudElement('HeroInspectHeroName');
const info = FindDotaHudElement('HeroInspectInfo');
const tooltipManager = FindDotaHudElement('Tooltips');
const abilities = info.GetParent().FindChildTraverse('HeroAbilities');
const currentMap = Game.GetMapInfo().map_display_name;
$.Msg(currentMap);

let altTooltip = tooltipManager.FindChildTraverse('DOTAHUDStatBranchTooltipAlt');
if (altTooltip == null) {
  FindDotaHudElement('DOTAHUDStatBranchTooltipAlt').SetParent(tooltipManager);
  altTooltip = tooltipManager.FindChildTraverse('DOTAHUDStatBranchTooltipAlt');
}

function CreateAbilityPanel (parent, ability) {
  const id = 'Ability_' + ability;
  $.CreatePanelWithProperties('DOTAAbilityImage', parent, id, { abilityname: ability });
  const icon = parent.FindChildTraverse(id);

  icon.SetPanelEvent('onmouseover', function () {
    $.DispatchEvent('DOTAShowAbilityTooltip', icon, ability);
  });
  icon.SetPanelEvent('onmouseout', function () {
    $.DispatchEvent('DOTAHideAbilityTooltip', icon);
  });
  return icon;
}

function OnUpdateHeroSelection (key) {
  const portrait = info.FindChildTraverse('HeroPortrait');
  if (heroNamePanel && heroNamePanel.text === 'SOHEI') {
    SetupSohei(portrait);
  } else if (heroNamePanel && heroNamePanel.text === 'CHATTERJEE') {
    SetupElectrician(portrait);
  } else {
    UpdateBottlePassArcana('');
  }
}

function SetupElectrician (portrait) {
  portrait.style.backgroundImage = 'url("file://{images}/heroes/selection/npc_dota_hero_electrician.png")';
  portrait.style.backgroundSize = '100% 100%';
  CreateAbilityPanel(abilities, 'electrician_static_grip');
  CreateAbilityPanel(abilities, 'electrician_electric_shield');
  CreateAbilityPanel(abilities, 'electrician_energy_absorption');
  const lastAbility = CreateAbilityPanel(abilities, 'electrician_cleansing_shock');
  const talents = abilities.GetChild(0);
  talents.SetPanelEvent('onmouseover', function () {
    altTooltip.SetHasClass('visible', true);
    SetTalentsElectrician();
  });
  talents.SetPanelEvent('onmouseout', function () {
    altTooltip.SetHasClass('visible', false);
  });
  abilities.MoveChildAfter(talents, lastAbility);
  UpdateBottlePassArcana('npc_dota_hero_electrician');
}

function SetupSohei (portrait) {
  portrait.style.backgroundImage = 'url("file://{images}/heroes/selection/npc_dota_hero_sohei.png")';
  portrait.style.backgroundSize = '100% 100%';
  CreateAbilityPanel(abilities, 'sohei_dash');
  CreateAbilityPanel(abilities, 'sohei_wholeness_of_body');
  CreateAbilityPanel(abilities, 'sohei_palm_of_life');
  const lastAbility = CreateAbilityPanel(abilities, 'sohei_flurry_of_blows');
  const talents = abilities.GetChild(0);
  talents.SetPanelEvent('onmouseover', function () {
    altTooltip.SetHasClass('visible', true);
  });
  talents.SetPanelEvent('onmouseout', function () {
    altTooltip.SetHasClass('visible', false);
  });
  abilities.MoveChildAfter(talents, lastAbility);

  UpdateBottlePassArcana('npc_dota_hero_sohei');
}

function SetTalentsElectrician () {
  altTooltip.SetDialogVariable('name_1', $.Localize('#Dota_tooltip_ability_special_bonus_mp_regen_6'));
  altTooltip.SetDialogVariable('name_2', $.Localize('#Dota_tooltip_ability_special_bonus_hp_regen_10'));
  altTooltip.SetDialogVariable('name_3', $.Localize('#Dota_tooltip_ability_special_bonus_movement_speed_30'));
  altTooltip.SetDialogVariable('name_4', $.Localize('#Dota_tooltip_ability_special_bonus_cast_range_250'));
  altTooltip.SetDialogVariable('name_5', $.Localize('#Dota_tooltip_ability_special_bonus_electrician_absorption_hero_mana_restore').replace('%value%', '2'));
  altTooltip.SetDialogVariable('name_6', $.Localize('#Dota_tooltip_ability_special_bonus_mp_800'));
  altTooltip.SetDialogVariable('name_7', $.Localize('#Dota_tooltip_ability_special_bonus_electrician_shock_autoself'));
  altTooltip.SetDialogVariable('name_8', $.Localize('#Dota_tooltip_ability_special_bonus_hp_1000'));
}

function UpdateBottleList () {
  const playerID = Game.GetLocalPlayerID();
  const specialBottles = CustomNetTables.GetTableValue('bottlepass', 'special_bottles');
  if (!specialBottles) {
    $.Schedule(0.2, UpdateBottleList);
    return;
  }
  const bottles = specialBottles[playerID.toString()] ? specialBottles[playerID.toString()].Bottles : {};

  if ($('#BottleSelection').GetChildCount() === Object.keys(bottles).length + 1) {
    // ignore repaint if radio is already filled
    return;
  }

  $('#BottleSelection').RemoveAndDeleteChildren();
  // Wait the parent be updated
  $.Schedule(0.2, function () {
    let selectedBottle;

    const selectedBottles = CustomNetTables.GetTableValue('bottlepass', 'selected_bottles');
    if (selectedBottles !== undefined && selectedBottles[playerID.toString()] !== undefined) {
      selectedBottle = selectedBottles[playerID.toString()];
    }

    CreateBottleRadioElement(0, selectedBottle === 0);
    const bottleCount = Object.keys(bottles).length;
    Object.keys(bottles).forEach(function (bottleId, i) {
      const id = bottles[bottleId];
      CreateBottleRadioElement(bottles[bottleId], selectedBottle === undefined ? i === bottleCount - 1 : id === selectedBottle);
    });

    SelectBottle();
  });
}

function CreateBottleRadioElement (id, isChecked) {
  const radio = $.CreatePanel('RadioButton', $('#BottleSelection'), 'Bottle' + id);
  radio.BLoadLayoutSnippet('BottleRadio');
  radio.bottleId = id;
  radio.checked = isChecked;
}

function SelectBottle () {
  let bottleId = 0;
  const btn = $('#Bottle0');
  if (btn != null && btn.GetSelectedButton() !== null) {
    bottleId = btn.GetSelectedButton().bottleId;
  }
  const data = {
    BottleId: bottleId
  };
  btn.SetHasClass('Selected', true);
  $.Msg('Selecting Bottle #' + data.BottleId + ' for Player #' + Game.GetLocalPlayerID());
  GameEvents.SendCustomGameEventToServer('bottle_selected', data);
}

function UpdateBottlePassArcana (heroName) {
  const playerID = Game.GetLocalPlayerID();
  $('#ArcanaSelection').RemoveAndDeleteChildren();

  if (heroName !== 'npc_dota_hero_sohei' && heroName !== 'npc_dota_hero_electrician') {
    $('#ArcanaPanel').SetHasClass('HasArcana', false);
    return;
  }
  $('#ArcanaPanel').SetHasClass('HasArcana', true);

  const selectedArcanas = CustomNetTables.GetTableValue('bottlepass', 'selected_arcanas');
  let selectedArcana = 'DefaultSet';

  if (selectedArcanas !== undefined && selectedArcanas[playerID.toString()] !== undefined) {
    selectedArcana = selectedArcanas[playerID.toString()][heroName];
  }

  $.Schedule(0.2, function () {
    $.Msg('UpdateBottlePassArcana(' + heroName + ')');
    let arcanas = null;

    const specialArcanas = CustomNetTables.GetTableValue('bottlepass', 'special_arcanas');
    for (const arcanaIndex in specialArcanas) {
      if (specialArcanas[arcanaIndex].PlayerId === playerID) {
        arcanas = specialArcanas[arcanaIndex].Arcanas;
      }
    }
    let radio = null;
    if (heroName === 'npc_dota_hero_sohei') {
      radio = $.CreatePanel('RadioButton', $('#ArcanaSelection'), 'DefaultSoheiSet');
      radio.BLoadLayoutSnippet('ArcanaRadio');
      radio.hero = heroName;
      radio.setName = 'DefaultSet';
      radio.checked = selectedArcana === radio.setName;

      for (const index in arcanas) {
        if (arcanas[index] === 'DBZSohei') {
          radio = $.CreatePanel('RadioButton', $('#ArcanaSelection'), 'DBZSoheiSet');
          radio.BLoadLayoutSnippet('ArcanaRadio');
          radio.hero = heroName;
          radio.setName = 'DBZSohei';
          radio.checked = selectedArcana === radio.setName;
        }
        if (arcanas[index] === 'PepsiSohei') {
          radio = $.CreatePanel('RadioButton', $('#ArcanaSelection'), 'PepsiSoheiSet');
          radio.BLoadLayoutSnippet('ArcanaRadio');
          radio.hero = heroName;
          radio.setName = 'PepsiSohei';
          radio.checked = selectedArcana === radio.setName;
        }
      }
    } else if (heroName === 'npc_dota_hero_electrician') {
      radio = $.CreatePanel('RadioButton', $('#ArcanaSelection'), 'DefaultElectricianSet');
      radio.BLoadLayoutSnippet('ArcanaRadio');
      radio.hero = heroName;
      radio.setName = 'DefaultSet';
      radio.checked = selectedArcana === radio.setName;

      for (const index2 in arcanas) {
        if (arcanas[index2] === 'RockElectrician') {
          radio = $.CreatePanel('RadioButton', $('#ArcanaSelection'), 'RockElectricianSet');
          radio.BLoadLayoutSnippet('ArcanaRadio');
          radio.hero = heroName;
          radio.setName = 'RockElectrician';
          radio.checked = selectedArcana === radio.setName;
        }
      }
    }
    SelectArcana();
  });
}

function SelectArcana () {
  const arcanasList = $('#ArcanaSelection');
  if (arcanasList.GetChildCount() > 0) {
    const selectedArcana = $('#ArcanaSelection').Children()[0].GetSelectedButton();
    if (selectedArcana == null) {
      return;
    }
    const data = {
      Hero: selectedArcana.hero,
      Arcana: selectedArcana.setName
    };

    $.Msg('Selecting Arcana ' + data.Arcana + ' for Player #' + Game.GetLocalPlayerID() + ' for hero ' + data.Hero);
    GameEvents.SendCustomGameEventToServer('arcana_selected', data);
  }
}

function init () {
  $.GetContextPanel().SetHasClass(Game.GetMapInfo().map_display_name, true);
  $.GetContextPanel().FindChildrenWithClassTraverse('BottlePassSelection')[0].SetHasClass(Game.GetMapInfo().map_display_name, true);
  // Subscribe hero pre select event
  GameEvents.Subscribe('dota_player_hero_selection_dirty', OnUpdateHeroSelection);

  CustomNetTables.SubscribeNetTableListener('bottlepass', UpdateBottleList);

  // Enable top bar
  FindDotaHudElement('PreGame').FindChildTraverse('Header').style.visibility = 'visible';

  // SetMinimap
  const minimap = FindDotaHudElement('HeroPickMinimap');
  minimap.style.backgroundImage = 'url("s2r://materials/overviews/oaa.tga")';
  minimap.style.borderRadius = '20px';

  for (let i = 0; i < minimap.GetChildCount(); i++) {
    const lastPanel = minimap.GetChild(i);
    lastPanel.style.visibility = 'collapse';
  }

  UpdateBottleList();
}

init();
