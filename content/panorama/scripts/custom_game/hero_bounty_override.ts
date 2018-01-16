(function() {
  GameEvents.Subscribe('override_hero_bounty_toast', OverrideHeroBountyToast);
}())

interface BountyToastOverrideData {
  killerID: number;
  killedID: number;
  goldBounty: number;
}

function OverrideHeroBountyToast(data: BountyToastOverrideData) {
  let toasts = FindDotaHudElement('ToastManager').Children();
  let killMessageToast: Panel | undefined;
  do {
    killMessageToast = toasts.pop();
    if (killMessageToast === undefined) {
      return;
    }
  } while (!(killMessageToast.BHasClass('ToastVisible') && killMessageToast.BHasClass('event_dota_player_kill')));
  let label = <LabelPanel> killMessageToast.FindChild('EventLabel');
  let killerPlayerID = data.killerID;
  let killedPlayerID = data.killedID;
  let goldBounty = data.goldBounty;
  let killerColor = ColorToHexCode(Players.GetPlayerColor(killerPlayerID));
  let killedColor = ColorToHexCode(Players.GetPlayerColor(killedPlayerID));
  let killerName = Players.GetPlayerName(killerPlayerID);
  let killedName = Players.GetPlayerName(killedPlayerID);
  let killerText = ColoredText(killerColor, killerName);
  let killedText = ColoredText(killedColor, killedName);
  let goldText = ColoredText('#ffd825', goldBounty.toString());
  let killIcon = '<Panel class="CombatEventKillIcon"/>';
  let goldIcon = '<Panel class="CombatEventGoldIcon"/>';
  let killerIcon = `<img class="CombatEventHeroIcon" src="file://{images}/heroes/icons/${Players.GetPlayerSelectedHero(killerPlayerID)}.png"/>`;
  let killedIcon = `<img class="CombatEventHeroIcon" src="file://{images}/heroes/icons/${Players.GetPlayerSelectedHero(killedPlayerID)}.png"/>`;
  label.text = killerIcon + killerText + killIcon + killedIcon + killedText + ' ' + goldText + goldIcon;
}
