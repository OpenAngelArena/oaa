/* global Game, GameEvents, FindDotaHudElement, LuaTableToArray, ColorToHexCode, ColoredText, Players, $ */
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
  var rewardPlayerIDs = LuaTableToArray(data.rewardIDs);
  var killedPlayerID = data.killedID;
  var goldBounty = data.goldBounty;
  var displayHeroes = data.displayHeroes === 1;
  var killedColor = ColorToHexCode(Players.GetPlayerColor(killedPlayerID));
  var killedName = Players.GetPlayerName(killedPlayerID);
  var killedText = ColoredText(killedColor, killedName);
  var killerText = '';
  if (displayHeroes) {
    rewardPlayerIDs.forEach(function (playerID) {
      var color = ColorToHexCode(Players.GetPlayerColor(playerID));
      var name = Players.GetPlayerName(playerID);
      var killerIcon = '<img class="CombatEventHeroIcon" src="file://{images}/heroes/icons/' + Players.GetPlayerSelectedHero(playerID) + '.png"/>';
      killerText = killerText + (killerText ? ' ' : '') + killerIcon + ColoredText(color, name);
    });
  } else {
    killerText = $.Localize(Game.GetTeamDetails(data.rewardTeam).team_name);
    if (data.rewardTeam === Game.GetLocalPlayerInfo().player_team_id) {
      killMessageToast.RemoveClass('EnemyEvent');
      killMessageToast.AddClass('AllyEvent');
    }
  }
  var goldText = ColoredText('#ffd825', goldBounty.toString());
  var killIcon = '<Panel class="CombatEventKillIcon"/>';
  var goldIcon = '<Panel class="CombatEventGoldIcon"/>';
  var killedIcon = '<img class="CombatEventHeroIcon" src="file://{images}/heroes/icons/' + Players.GetPlayerSelectedHero(killedPlayerID) + '.png"/>';
  var each = !displayHeroes || rewardPlayerIDs.length > 1 ? $.Localize('#DOTA_HUD_Gold_Each') : '';
  label.text = killerText + killIcon + killedIcon + killedText + ' ' + goldText + goldIcon + each;
}
