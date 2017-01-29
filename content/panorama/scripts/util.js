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
      if (p.id === "Hud") {
        return p
      } else {
        p = p.GetParent()
      }
    }
  } catch (e) {}
}

Entities.GetHeroPlayerOwner = function(unit) {
  for (var i = 0; i < 24; i++) {
    var ServersideData = PlayerTables.GetTableValue("player_hero_entities", i);

    if ((ServersideData && Number(ServersideData) == unit) || Players.GetPlayerHeroEntityIndex(i) == unit) {
      return i;
    }
  }
  return -1
}
// SNIPPET END
