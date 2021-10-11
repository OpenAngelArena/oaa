/* global Game, GameEvents, FindDotaHudElement, LuaTableToArray, ColorToHexCode, ColoredText, Players, $ */
'use strict';
(function () {
  GameEvents.Subscribe('override_hero_bounty_toast', OverrideHeroBountyToast);
}());
function OverrideHeroBountyToast (data) {
  let toastManager = FindDotaHudElement('ToastManager');
  let toasts = toastManager.Children();
  let toastCount = toastManager.GetChildCount();
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
  let label = lastToast.FindChildTraverse('EventLabel');
  // $.Msg(label.text); // old message
  let rewardPlayerIDs = LuaTableToArray(data.rewardIDs);
  let killedPlayerID = data.killedID;
  let goldBounty = data.goldBounty;
  let displayHeroes = data.displayHeroes === 1;
  let killedColor = ColorToHexCode(Players.GetPlayerColor(killedPlayerID));
  let killedName = Players.GetPlayerName(killedPlayerID);
  let killedText = ColoredText(killedColor, killedName);
  let killerText = '';
  // if (displayHeroes) {
  rewardPlayerIDs.forEach(function (playerID) {
    let color = ColorToHexCode(Players.GetPlayerColor(playerID));
    let name = Players.GetPlayerName(playerID);
    let killerIcon = '<img class="CombatEventHeroIcon" src="file://{images}/heroes/icons/' + Players.GetPlayerSelectedHero(playerID) + '.png"/>';
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
  let goldText = ColoredText('#ffd825', goldBounty.toString());
  let killIcon = '<Panel class="CombatEventKillIcon"/>';
  let goldIcon = '<Panel class="CombatEventGoldIcon"/>';
  let killedIcon = '<img class="CombatEventHeroIcon" src="file://{images}/heroes/icons/' + Players.GetPlayerSelectedHero(killedPlayerID) + '.png"/>';
  let each = !displayHeroes || rewardPlayerIDs.length > 1 ? $.Localize('#DOTA_HUD_Gold_Each') : '';
  label.text = killerText + killIcon + killedIcon + killedText + ' ' + goldText + goldIcon + each;
}
