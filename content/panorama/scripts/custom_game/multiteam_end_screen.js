/* global $, CustomNetTables, Game, DOTATeam_t */

'use strict';

if (typeof module !== 'undefined' && module.exports) {
  module.exports = {
    CloseBottlepassReward: CloseBottlepassReward
  };
}

(function () {
  CustomNetTables.SubscribeNetTableListener('end_game_scoreboard', EndScoreboard);
  EndScoreboard(null, 'game_info', CustomNetTables.GetTableValue('end_game_scoreboard', 'game_info'));
})();

/*
// PLACEHOLDERS: testing purpose only
var args = {
  xp_info: {
    0: {
      progress: 0.7,
      level: 12,
      rank: 'Legend',
      earned: 17
    },

    info: {
      radiant_score: 100,
      dire_score: 99
    },

    players: {
      0: {
        // GetPlayer lua thing
      }
    }
  },

  info: {
    map: {
      map_name: 'maps/oaa.vpk',
      map_display_name: 'oaa'
    },

    ids1: [0],
    ids2: []
  }
};
*/

function EndScoreboard (table, key, args) {
  if (!args || key !== 'game_info') {
    $.Msg(key);
    $.Msg('Got bad end screen data');
    return;
  }

  // Hide all other UI
  var MainPanel = $.GetContextPanel().GetParent().GetParent().GetParent().GetParent();
  MainPanel.FindChildTraverse('topbar').style.visibility = 'collapse';
  MainPanel.FindChildTraverse('minimap_container').style.visibility = 'collapse';
  MainPanel.FindChildTraverse('lower_hud').style.visibility = 'collapse';
  MainPanel.FindChildTraverse('HudChat').style.visibility = 'collapse'; // can be useful to keep but in 10v10 panels override on it
  MainPanel.FindChildTraverse('NetGraph').style.visibility = 'collapse';
  MainPanel.FindChildTraverse('quickstats').style.visibility = 'collapse';

  // Gather info
  var playerResults = args.players;
  var serverInfo = args.info;
  var xpInfo = args.xp_info;
  var mapInfo = Game.GetMapInfo();
  var radiantPlayerIds = Game.GetPlayerIDsOnTeam(DOTATeam_t.DOTA_TEAM_GOODGUYS);
  var direPlayerIds = Game.GetPlayerIDsOnTeam(DOTATeam_t.DOTA_TEAM_BADGUYS);

  $.Msg(serverInfo);

  $.Msg({
    args: args,
    info: {
      map: mapInfo,
      ids1: radiantPlayerIds,
      ids2: direPlayerIds
    }
  });

  // Victory Info text
  var victoryMessage = 'winning_team_name Victory!';
  var victoryMessageLabel = $('#es-victory-info-text');

  if (serverInfo.winner === 2) {
    victoryMessage = victoryMessage.replace('winning_team_name', $.Localize('#DOTA_GoodGuys'));
  } else if (serverInfo.winner === 3) {
    victoryMessage = victoryMessage.replace('winning_team_name', $.Localize('#DOTA_BadGuys'));
  }

  victoryMessageLabel.text = victoryMessage;

  // Load frequently used panels
  // var teamsContainer = $('#es-teams');

  var panels = {
    radiant: $('#es-radiant'),
    dire: $('#es-dire'),
    radiantPlayers: $('#es-radiant-players'),
    direPlayers: $('#es-dire-players')
  };

  // the panorama xml file used for the player lines
  var playerXmlFile = 'file://{resources}/layout/custom_game/multiteam_end_screen_player.xml';

  // sort a player by merging results from server and using getplayerinfo
  var loadPlayer = function (id) {
    var playerInfo = Game.GetPlayerInfo(id);
    var resultInfo = null;
    var xp = null;
    var steamid = null;
    var playerSteamId = playerInfo.player_steamid + '';

    resultInfo = playerResults[id + ''];

    for (steamid in xpInfo) {
      if (playerSteamId === steamid) {
        xp = xpInfo[steamid];
      }
    }

    return {
      id: id,
      info: playerInfo,
      result: resultInfo,
      xp: xp
    };
  };

  // Load players = sort our data we got from above
  var radiantPlayers = [];
  var direPlayers = [];

  $.Each(radiantPlayerIds, function (id) { radiantPlayers.push(loadPlayer(id)); });
  $.Each(direPlayerIds, function (id) { direPlayers.push(loadPlayer(id)); });

  var createPanelForPlayer = function (player, parent) {
    // Create a new Panel for this player
    var pp = $.CreatePanel('Panel', parent, 'es-player-' + player.id);
    pp.AddClass('es-player');
    pp.BLoadLayout(playerXmlFile, false, false);

    var xpBar = pp.FindChildrenWithClassTraverse('es-player-xp');

    //    $.Msg("Player:");
    //    $.Msg(player);

    var values = {
      name: pp.FindChildInLayoutFile('es-player-name'),
      avatar: pp.FindChildInLayoutFile('es-player-avatar'),
      hero: pp.FindChildInLayoutFile('es-player-hero'),
      desc: pp.FindChildInLayoutFile('es-player-desc'),
      kills: pp.FindChildInLayoutFile('es-player-k'),
      deaths: pp.FindChildInLayoutFile('es-player-d'),
      assists: pp.FindChildInLayoutFile('es-player-a'),
      imr: pp.FindChildInLayoutFile('es-player-imr'),
      gold: pp.FindChildInLayoutFile('es-player-gold'),
      level: pp.FindChildInLayoutFile('es-player-level'),
      xp: {
        bar: xpBar,
        progress: pp.FindChildInLayoutFile('es-player-xp-progress'),
        level: pp.FindChildInLayoutFile('es-player-xp-level'),
        rank: pp.FindChildInLayoutFile('es-player-xp-rank'),
        earned: pp.FindChildInLayoutFile('es-player-xp-earned')
      }
    };

    var rp = $('#es-player-reward-container');

    var rewards = {
      name: rp.FindChildInLayoutFile('es-player-reward-name'),
      rarity: rp.FindChildInLayoutFile('es-player-reward-rarity'),
      image: rp.FindChildInLayoutFile('es-player-reward-image')
    };

    // Avatar + Hero Image
    values.avatar.steamid = player.info.player_steamid;
    values.hero.heroname = player.info.player_selected_hero;

    // Steam Name + Hero name
    values.name.text = player.info.player_name;
    values.desc.text = $.Localize(player.info.player_selected_hero);

    // Stats
    values.kills.text = player.info.player_kills;
    values.deaths.text = player.info.player_deaths;
    values.assists.text = player.info.player_assists;
    values.gold.text = player.info.player_gold;
    values.level.text = player.info.player_level;

    // PLACEHOLDERS: testing purpose only, remove it
    // player.result = [];
    // player.result.imr_calibrating = false;
    // player.result.imr = 1594;
    // player.result.imr_diff = +9;
    // player.result.xp_diff = 600;
    // player.result.xp = 500;
    // player.result.max_xp = 1000;

    // player.xp = [];
    // player.xp.level = 2;

    // player.xp.progress = player.result.xp / player.result.max_xp;
    // END OF PLACEHOLDERS

    // IMR
    if (player.result != null) {
      if (player.result.imr_calibrating) {
        $.Msg('MMR Calibrating!');
        values.imr.text = 'TBD';
      } else {
        $.Msg('MMR correct!');
        var imr = Math.floor(player.result.imr);
        var diff = Math.floor(player.result.imr_diff);

        if (diff === 0) {
          values.imr.text = imr;
          values.imr.AddClass('es-text-white');
        } else if (diff > 0) {
          values.imr.text = imr + ' (+' + diff + ')';
          values.imr.AddClass('es-text-green');
        } else {
          values.imr.text = imr + ' (' + diff + ')';
          values.imr.AddClass('es-text-red');
        }
      }
    } else {
      values.imr.text = 'N/A';
    }

    // XP
    if (player.result != null) {
      // var xp = Math.floor(player.result.xp);
      var xpDiff = Math.floor(player.result.xp_diff);

      if (xpDiff > 0) {
        values.xp.earned.text = '+' + xpDiff;
        values.xp.earned.AddClass('es-text-green');
      } else if (xpDiff === 0) {
        values.xp.earned.text = '0';
        values.xp.earned.AddClass('es-text-white');
      } else {
        values.xp.earned.text = String(xpDiff);
        values.xp.earned.AddClass('es-text-red');
      }

      xpDiff = player.result.xp_diff / player.result.max_xp;

      if (player.xp) {
        player.xp.progress = (player.xp.progress + xpDiff) * 100;
        values.xp.level.text = 'Level: ' + player.xp.level;
        values.xp.rank.text = player.result.max_xp + '/' + player.result.max_xp;
      }

      if (player.xp) {
        $.Schedule(0.6, function () { // END_SCREEN_DELAY in css
          // if not leveling up
          if (player.xp.progress < 100) {
            $.Msg('Everything normal');
            values.xp.progress.style.width = player.xp.progress + '%';
            values.xp.rank.text = player.result.xp + player.result.xp_diff + '/' + player.result.max_xp;
          // else if leveling up
          } else {
            values.xp.rank.text = player.result.max_xp + '/' + player.result.max_xp;
            values.xp.progress.style.width = '100%';

            $.Schedule(2.0, function () { // XP_BAR_ANIM_TIME in css
              $.Msg('Level up!');

              // PLACEHOLDERS
              // item earned info
              var item = {
                name: 'Dash Staff',
                rarity: 'Arcana',
                image: 'dash_staff'
              };
              // PLACEHOLDERS END

              rp.style.visibility = 'visible';
              rewards.name.text = item.name;
              rewards.rarity.text = item.rarity;
              rewards.rarity.AddClass(item.rarity);
              rewards.image.style.backgroundImage = 'url("file://{resources}/images/items/custom/' + item.image + '.png")';
              rewards.image.style.backgroundSize = 'cover';

              rp.AddClass('level-up');

              if (values.xp.bar[0].BHasClass('level-up')) {
                values.xp.bar[0].RemoveClass('level-up');
              }
              values.xp.bar[0].AddClass('level-up');
              player.xp.level = player.xp.level + 1;
              values.xp.level.text = 'Level up!';
              values.xp.rank.text = '';
              player.xp.progress = player.xp.progress - 100;
              values.xp.progress.style.width = player.xp.progress + '%';
              $.Schedule(2.0, function () {
                values.xp.level.text = 'Level: ' + player.xp.level;
                values.xp.rank.text = player.result.xp + player.result.xp_diff - player.result.max_xp + '/' + player.result.max_xp;
              });
            });
          }
        });
      }
    } else {
      values.xp.earned.text = 'N/A';
    }
  };

  // Create the panels for the players
  $.Each(radiantPlayers, function (player) {
    createPanelForPlayer(player, panels.radiantPlayers);
  });

  $.Each(direPlayers, function (player) {
    createPanelForPlayer(player, panels.direPlayers);
  });

  // Set Team Score
  $('#es-team-score-radiant').text = String(serverInfo.radiant_score);
  $('#es-team-score-dire').text = String(serverInfo.dire_score);

  // Configure Stats Button, to see this game info automatically created on website
//  $("#es-buttons-stats").SetPanelEvent("onactivate", function () {
//    $.DispatchEvent("DOTADisplayURL", "http://www.dota2imba.org/stats/game/" + serverInfo.gameid);
//  });
}

function CloseBottlepassReward () {
  $('#es-player-reward-container').style.visibility = 'collapse';
}
