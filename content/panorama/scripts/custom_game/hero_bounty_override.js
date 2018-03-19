/* global Game, GameEvents, LuaTableToArray, ColorToHexCode, ColoredText, Players, DOMException, $ */
'use strict';
var HeroBountyUtils = /** @class */ (function () {
  function HeroBountyUtils () {
  }
  HeroBountyUtils.FindDotaHudElement = function (id) {
    return HeroBountyUtils.GetDotaHud().FindChildTraverse(id);
  };
  HeroBountyUtils.GetDotaHud = function () {
    var p = $.GetContextPanel();
    while (p !== null && p.id !== 'Hud') {
      p = p.GetParent();
    }
    if (p === null) {
      throw new DOMException('Could not find Hud root as parent of panel with id: ' + $.GetContextPanel().id);
    } else {
      return p;
    }
  };
  return HeroBountyUtils;
}());
(function () {
  GameEvents.Subscribe('override_hero_bounty_toast', OverrideHeroBountyToast);
}());
function OverrideHeroBountyToast (data) {
  var toasts = HeroBountyUtils.FindDotaHudElement('ToastManager').Children();
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
