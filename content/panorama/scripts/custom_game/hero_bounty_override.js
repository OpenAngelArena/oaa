'use strict';
(function () {
  GameEvents.Subscribe('override_hero_bounty_toast', OverrideHeroBountyToast);
}());
function OverrideHeroBountyToast (data) {
  var toasts = FindDotaHudElement('ToastManager').Children();
  var killMessageToast;
  do {
    killMessageToast = toasts.pop();
    if (killMessageToast === undefined) {
      return;
    }
  } while (!(killMessageToast.BHasClass('ToastVisible') && killMessageToast.BHasClass('event_dota_player_kill')));
  var label = killMessageToast.FindChild('EventLabel');
  var killerPlayerID = data.killerID;
  var killedPlayerID = data.killedID;
  var goldBounty = data.goldBounty;
  var killerColor = ColorToHexCode(Players.GetPlayerColor(killerPlayerID));
  var killedColor = ColorToHexCode(Players.GetPlayerColor(killedPlayerID));
  var killerName = Players.GetPlayerName(killerPlayerID);
  var killedName = Players.GetPlayerName(killedPlayerID);
  var killerText = ColoredText(killerColor, killerName);
  var killedText = ColoredText(killedColor, killedName);
  var goldText = ColoredText('#ffd825', goldBounty.toString());
  var killIcon = '<Panel class="CombatEventKillIcon"/>';
  var goldIcon = '<Panel class="CombatEventGoldIcon"/>';
  var killerIcon = '<img class="CombatEventHeroIcon" src="file://{images}/heroes/icons/' + Players.GetPlayerSelectedHero(killerPlayerID) + '.png"/>';
  var killedIcon = '<img class="CombatEventHeroIcon" src="file://{images}/heroes/icons/' + Players.GetPlayerSelectedHero(killedPlayerID) + '.png"/>';
  label.text = killerIcon + killerText + killIcon + killedIcon + killedText + ' ' + goldText + goldIcon;
}
