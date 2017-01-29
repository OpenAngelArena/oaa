/*
  Author:
    Chronophylos
  Credits:
    Noya
    Angel Arena Blackstar
*/
"use strict";
var useFormatting = "half";

function UpdateGoldHud(data) {
  //$.Msg("UpdateGoldHud")
  var player_gold = PlayerTables.GetTableValue("gold", "gold");
  var unit = Players.GetLocalPlayerPortraitUnit();
  var playerID = Game.GetLocalPlayerID()
  var GoldLabel = FindDotaHudElement("ShopButton").FindChildTraverse("GoldLabel");
  var gold = player_gold[playerID];
  if (useFormatting == "full"){
    GoldLabel.text = GameUI.FormatGold(gold);
  } else if (useFormatting == "half") {
    GoldLabel.text = GameUI.FormatComma(gold);
  } else {
    GoldLabel.text = gold;
  }
}

(function () {
    //GameEvents.Subscribe("aaa_update_gold", UpdateGoldHud);
    PlayerTables.SubscribeNetTableListener("gold", UpdateGoldHud);
})();
