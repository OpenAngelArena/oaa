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
let args = {
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
  const MainPanel = $.GetContextPanel().GetParent().GetParent().GetParent().GetParent();
  MainPanel.FindChildTraverse('topbar').style.visibility = 'collapse';
  MainPanel.FindChildTraverse('minimap_container').style.visibility = 'collapse';
  MainPanel.FindChildTraverse('lower_hud').style.visibility = 'collapse';
  // MainPanel.FindChildTraverse('HudChat').style.visibility = 'collapse'; // can be useful to keep but in 10v10 panels override on it
  MainPanel.FindChildTraverse('NetGraph').style.visibility = 'collapse';
  MainPanel.FindChildTraverse('quickstats').style.visibility = 'collapse';

  // Gather info
  const playerResults = args.players;
  const serverInfo = args.info;
  const xpInfo = args.xp_info;
  const stats = args.stats;
  const mapInfo = Game.GetMapInfo();
  const radiantPlayerIds = Game.GetPlayerIDsOnTeam(DOTATeam_t.DOTA_TEAM_GOODGUYS);
  const direPlayerIds = Game.GetPlayerIDsOnTeam(DOTATeam_t.DOTA_TEAM_BADGUYS);

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
  let victoryMessage = 'winning_team_name Victory!';
  const victoryMessageLabel = $('#es-victory-info-text');

  if (serverInfo.winner === 2) {
    victoryMessage = victoryMessage.replace('winning_team_name', $.Localize('#DOTA_GoodGuys'));
  } else if (serverInfo.winner === 3) {
    victoryMessage = victoryMessage.replace('winning_team_name', $.Localize('#DOTA_BadGuys'));
  }

  victoryMessageLabel.text = victoryMessage;

  // Load frequently used panels
  // let teamsContainer = $('#es-teams');

  const panels = {
    radiant: $('#es-radiant'),
    dire: $('#es-dire'),
    radiantPlayers: $('#es-radiant-players'),
    direPlayers: $('#es-dire-players')
  };

  // the panorama xml file used for the player lines
  const playerXmlFile = 'file://{resources}/layout/custom_game/multiteam_end_screen_player.xml';

  // sort a player by merging results from server and using getplayerinfo
  const loadPlayer = function (id) {
    const playerInfo = Game.GetPlayerInfo(id);
    let resultInfo = null;
    let xp = null;
    let steamid = null;
    const playerSteamId = playerInfo.player_steamid + '';

    if (playerResults !== undefined) {
      resultInfo = playerResults[id + ''];
    }

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
  const radiantPlayers = [];
  const direPlayers = [];

  $.Each(radiantPlayerIds, function (id) { radiantPlayers.push(loadPlayer(id)); });
  $.Each(direPlayerIds, function (id) { direPlayers.push(loadPlayer(id)); });

  const createPanelForPlayer = function (player, parent) {
    // Create a new Panel for this player
    const pp = $.CreatePanel('Panel', parent, 'es-player-' + player.id);
    pp.AddClass('es-player');
    pp.BLoadLayout(playerXmlFile, false, false);

    const xpBar = pp.FindChildrenWithClassTraverse('es-player-xp');

    const values = {
      name: pp.FindChildInLayoutFile('es-player-name'),
      avatar: pp.FindChildInLayoutFile('es-player-avatar'),
      hero: pp.FindChildInLayoutFile('es-player-hero'),
      desc: pp.FindChildInLayoutFile('es-player-desc'),
      kills: pp.FindChildInLayoutFile('es-player-k'),
      deaths: pp.FindChildInLayoutFile('es-player-d'),
      assists: pp.FindChildInLayoutFile('es-player-a'),
      imr: pp.FindChildInLayoutFile('es-player-imr'),
      // gold: pp.FindChildInLayoutFile('es-player-gold'),
      gpm: pp.FindChildInLayoutFile('es-player-gpm'),
      xpm: pp.FindChildInLayoutFile('es-player-xpm'),
      dmgDoneHeroes: pp.FindChildInLayoutFile('es-player-dmg-done-to-heroes'),
      dmgDoneBosses: pp.FindChildInLayoutFile('es-player-dmg-done-to-bosses'),
      dmgReceivedHeroes: pp.FindChildInLayoutFile('es-player-dmg-taken-from-players'),
      dmgReceivedBosses: pp.FindChildInLayoutFile('es-player-dmg-taken-from-bosses'),
      healing: pp.FindChildInLayoutFile('es-player-healing'),
      level: pp.FindChildInLayoutFile('es-player-level'),
      xp: {
        bar: xpBar,
        progress: pp.FindChildInLayoutFile('es-player-xp-progress'),
        level: pp.FindChildInLayoutFile('es-player-xp-level'),
        rank: pp.FindChildInLayoutFile('es-player-xp-rank'),
        earned: pp.FindChildInLayoutFile('es-player-xp-earned')
      }
    };

    const rp = $('#es-player-reward-container');

    const rewards = {
      name: rp.FindChildInLayoutFile('es-player-reward-name'),
      rarity: rp.FindChildInLayoutFile('es-player-reward-rarity'),
      image: rp.FindChildInLayoutFile('es-player-reward-image')
    };

    // Avatar + Hero Image
    values.avatar.steamid = player.info.player_steamid;
    values.hero.heroname = player.info.player_selected_hero;

    const heroname = '#' + player.info.player_selected_hero;

    // Steam Name + Hero name
    values.name.text = player.info.player_name;
    values.desc.text = $.Localize(heroname);

    // Stats
    values.kills.text = player.info.player_kills;
    values.deaths.text = player.info.player_deaths;
    values.assists.text = player.info.player_assists;
    // values.gold.text = player.info.player_gold;
    if (stats !== undefined && player.id !== undefined) {
      if (stats[player.id] !== undefined) {
        values.gpm.text = stats[player.id].gpm;
        values.xpm.text = stats[player.id].xpm;
        values.dmgDoneHeroes.text = stats[player.id].damage_dealt;
        values.dmgDoneBosses.text = stats[player.id].damage_dealt_to_bosses;
        values.dmgReceivedHeroes.text = stats[player.id].damage_taken;
        values.dmgReceivedBosses.text = stats[player.id].damage_taken_from_bosses;
        values.healing.text = stats[player.id].healing;
      } else {
        $.Msg('stats[player.id] is ' + stats[player.id]);
        values.gpm.text = 'N/A';
        values.xpm.text = 'N/A';
        values.dmgDoneHeroes.text = 'N/A';
        values.dmgDoneBosses.text = 'N/A';
        values.dmgReceivedHeroes.text = 'N/A';
        values.dmgReceivedBosses.text = 'N/A';
        values.healing.text = 'N/A';
      }
    } else {
      $.Msg('stats is ' + stats);
      $.Msg('player ID is ' + player.id);
      values.gpm.text = 'N/A';
      values.xpm.text = 'N/A';
      values.dmgDoneHeroes.text = 'N/A';
      values.dmgDoneBosses.text = 'N/A';
      values.dmgReceivedHeroes.text = 'N/A';
      values.dmgReceivedBosses.text = 'N/A';
      values.healing.text = 'N/A';
    }
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
        const imr = Math.floor(player.result.imr);
        const diff = Math.floor(player.result.imr_diff);

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
      // let xp = Math.floor(player.result.xp);
      let xpDiff = Math.floor(player.result.xp_diff);

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
              const item = {
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
