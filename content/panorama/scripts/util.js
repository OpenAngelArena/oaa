"use strict";

/*
  Author:
    Angel Arena Blackstar
  Credits:
    Angel Arena Blackstar
*/// SNIPPET START
var PlayerTables = GameUI.CustomUIConfig().PlayerTables;
var hud = GetDotaHud();

function FindDotaHudElement(id) {
    return hud.FindChildTraverse(id)
}

function GetDotaHud() {
    var p = $.GetContextPanel()
    try {
        while (true) {
            if (p.id === "Hud")
                return p
            else
                p = p.GetParent()
        }
    } catch (e) {}
}

Entities.GetHeroPlayerOwner = function(unit) {
    for (var i = 0; i < 24; i++) {
        var ServersideData = PlayerTables.GetTableValue("player_hero_entities", i)
        if ((ServersideData && Number(ServersideData) == unit) || Players.GetPlayerHeroEntityIndex(i) == unit)
            return i
    }
    return -1
}
// SNIPPET END

/*
  Author:
    Noya
    Chronophylos
  Credits:
    Noya
  Description:
    Returns gold with commas and k
*/
GameUI.FormatGold = function (gold) {
  var formatted = GameUI.CommaFormat(gold)
  if (gold.toString().length > 7) {
    return formatted.substring(0, formatted.length - 7) + "M";
  } else if (gold.toString().length > 4) {
    return formatted.substring(0, formatted.length - 4) + "k";
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
GameUI.FormatComma = function (value) {
    return value.toString().replace(/\B(?=(\d{3})+(?!\d))/g, " ");
}
