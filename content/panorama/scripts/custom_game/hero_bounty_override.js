/* global Game, GameEvents, FindDotaHudElement, LuaTableToArray, ColorToHexCode, ColoredText, Players, $ */
'use strict';
(function () {
  GameEvents.Subscribe('override_hero_bounty_toast', OverrideHeroBountyToast);
}());
function OverrideHeroBountyToast (data) {
  const toastManager = FindDotaHudElement('ToastManager');
  const toasts = toastManager.Children();
  const toastCount = toastManager.GetChildCount();
  // Find the last toast kill message that we need to override
  let lastToast = toasts[toastCount - 1];
  let count = toastCount;
  do {
    count = count - 1;
    if (count <= 0) {
      return;
    }
    lastToast = toasts[count]; // pop() doesn't seem to work properly for dota's array of panels
  } while (!lastToast.BHasClass('event_dota_player_kill'));
  const label = lastToast.FindChildTraverse('EventLabel');
  // $.Msg(label.text); // old message
  const rewardPlayerIDs = LuaTableToArray(data.rewardIDs);
  const killedPlayerID = data.killedID;
  const goldBounty = data.goldBounty;
  const displayHeroes = data.displayHeroes === 1;
  const killedColor = ColorToHexCode(Players.GetPlayerColor(killedPlayerID));
  const killedName = Players.GetPlayerName(killedPlayerID);
  const killedText = ColoredText(killedColor, killedName);
  let killerText = '';
  // if (displayHeroes) {
  rewardPlayerIDs.forEach(function (playerID) {
    const color = ColorToHexCode(Players.GetPlayerColor(playerID));
    const name = Players.GetPlayerName(playerID);
    const killerIcon = '<img class="CombatEventHeroIcon" src="file://{images}/heroes/icons/' + Players.GetPlayerSelectedHero(playerID) + '.png"/>';
    killerText = killerText + (killerText ? ' ' : '') + killerIcon + ColoredText(color, name);
  });
  // } else {
  if (rewardPlayerIDs.length < 1 && !displayHeroes) {
    killerText = $.Localize(Game.GetTeamDetails(data.rewardTeam).team_name);
    // if (data.rewardTeam === Game.GetLocalPlayerInfo().player_team_id) {
    // killMessageToast.RemoveClass('EnemyEvent');
    // killMessageToast.AddClass('AllyEvent');
    // }
  }
  const goldText = ColoredText('#ffd825', goldBounty.toString());
  const killIcon = '<Panel class="CombatEventKillIcon"/>';
  const goldIcon = '<Panel class="CombatEventGoldIcon"/>';
  const killedIcon = '<img class="CombatEventHeroIcon" src="file://{images}/heroes/icons/' + Players.GetPlayerSelectedHero(killedPlayerID) + '.png"/>';
  const each = !displayHeroes || rewardPlayerIDs.length > 1 ? $.Localize('#DOTA_HUD_Gold_Each') : '';
  label.text = killerText + killIcon + killedIcon + killedText + ' ' + goldText + goldIcon + each;
}
