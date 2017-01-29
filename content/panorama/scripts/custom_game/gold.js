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
  var unit = Players.GetLocalPlayerPortraitUnit();
  var playerID = Game.GetLocalPlayerID()
  var GoldLabel = FindDotaHudElement("ShopButton").FindChildTraverse("GoldLabel");
  if (useFormatting == "full"){
    GoldLabel.text = GameUI.FormatGold(data.gold[playerID]);
  } else if (useFormatting == "half") {
    GoldLabel.text = GameUI.FormatComma(data.gold[playerID]);
  } else {
    GoldLabel.text = data.gold[playerID];
  }
}

(function () {
    GameEvents.Subscribe("aaa_update_gold", UpdateGoldHud);
})();
