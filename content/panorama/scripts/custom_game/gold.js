/* global FindDotaHudElement, Game, PlayerTables, GameEvents, Players, Entities */
/*
  Author:
    Chronophylos
  Credits:
    Noya
    Angel Arena Blackstar
*/
'use strict';

// settings
var useFormatting = 'half';

(function () {
  PlayerTables.SubscribeNetTableListener('gold', onGoldChange);
  GameEvents.Subscribe('dota_player_update_query_unit', onQueryChange); // This doesn't work but I'm leaving it in
  GameEvents.Subscribe('dota_player_update_selected_unit', onQueryChange);
}());

function onQueryChange () {
  onGoldChange('gold', PlayerTables.GetAllTableValues('gold'));
}

function onGoldChange (table, data) {
  var unit = Players.GetLocalPlayerPortraitUnit();
  var localPlayerID = Game.GetLocalPlayerID();
  var playerID = Entities.GetPlayerOwnerID(unit);

  if (playerID === -1 || Entities.GetTeamNumber(unit) !== Players.GetTeam(localPlayerID)) {
    playerID = localPlayerID;
  }

  var gold = data.gold[playerID];

  UpdateGoldHud(gold);
  UpdateGoldTooltip(gold);
}

function UpdateGoldHud (gold) {
  var GoldLabel = FindDotaHudElement('ShopButton').FindChildTraverse('GoldLabel');

  if (useFormatting === 'full') {
    GoldLabel.text = FormatGold(gold);
  } else if (useFormatting === 'half') {
    GoldLabel.text = FormatComma(gold);
  } else {
    GoldLabel.text = gold;
  }
}

function UpdateGoldTooltip (gold) {
  // HACK this spews error when attempting to change the tooltip if it is not visible
  try {
    var tooltipLabels = FindDotaHudElement('DOTAHUDGoldTooltip').FindChildTraverse('Contents');

    var label = tooltipLabels.GetChild(0);
    label.text = label.text.replace(/: [0-9]+/, ': ' + gold);

    label = tooltipLabels.GetChild(1);
    label.style.visibility = 'collapse';
  } catch (e) {}
}

/*
  Author:
    Noya
    Chronophylos
  Credits:
    Noya
  Description:
    Returns gold with commas and k
*/
function FormatGold (gold) {
  var formatted = FormatComma(gold);
  if (gold.toString().length > 6) {
    return FormatGold(gold.toString().substring(0, gold.toString().length - 5) / 10) + 'M';
  } else if (gold.toString().length > 4) {
    return FormatGold(gold.toString().substring(0, gold.toString().length - 3)) + 'k';
  } else {
    return formatted;
  }
}

/*
  Author:
    Noya
  Credits:
    Noya
  Description:
    Inserts Commas every 3 chars
    We use a whitespace because of some DIN
*/
function FormatComma (value) {
  try {
    return value.toString().replace(/\B(?=(\d{3})+(?!\d))/g, ',');
  } catch (e) {}
}
