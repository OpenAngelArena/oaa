/* global Players $ GameEvents CustomNetTables FindDotaHudElement Game */

'use strict';

const hilariousLoadingPhrases = [
  'Precaching all heroes',
  'Filling bottles',
  'Spawning extra Ogres',
  'Procrastinating',
  'Loading a bunch of other stuff too',
  'Mining bitcoins',
  'Charging into towers',
  'Breaking boss agro leashes',
  'Hacking the gibson',
  'Adding more pointless loading screen quotes',
  'Attempting to index a nil value',
  'Changing Workshop entries',
  'Forking to make balance changes',
  'Constructing additional pylons',
  'Sedating Azazel',
  'Filling lava pools',
  'Rehearsing "Ocean Man"',
  'Painting the happy little trees',
  'Grinding Moon Shards into moon dust',
  'Dusting off the farming cave',
  'Priming tesla coils',
  'Rigging uphill attack misses',
  'Eating Jaffa cakes',
  'Nerfing your hero',
  'Buffing opponents',
  'Loading Warcraft 3',
  'Unboxing map',
  'Searching for a worthy opponent',
  'Pay no attention to the man behind the curtain',
  'Reticulating Splines',
  'Bugfixing waveshines and fun-canceling',
  'Selling arcanas to afford custom bottle',
  'Finding a 5-stack on Discord',
  'Rigging the tournament',
  'Arbitrarily resetting everyone\'s MMR',
  'Adding another overpowered custom hero',
  'Actually doing nothing',
  'Prolonging loading screen for dramatic effect',
  'Crashing tournament finals',
  'Banning spectators on a hunch',
  'Replacing all heroes with Oracle',
  'Losing self in the music the moment I owned it',
  'Practicing invincible ledgedash',
  'Actually playing Auto Chess instead',
  'Remember to poop aggressively',
  'Sneaking loading screen text into the game simply because I can',
  'Hope everyone is having a great day',
  'Wards cannot be bought individually, but an item called Ward Stack gives some stats and passively generates both Observer and Sentry wards',
  'Upgrade cores allow you to upgrade your items',
  'Each capture point is worth more points than the previous',
  'Each hero on a capture point speeds up the capture time',
  'Before -0:10 on the clock, you cannot leave the base',
  'Bosses spawn into the map at 3:00',
  'First Wanderer spawns between 12:00 and 15:00',
  'If you think you found a bug or a weird interaction, please share it on our discord server. Thank you',
  'Every hero has a Town Portal Scroll and it will not disappear when used',
  'Heroes are purged and invulnerable for 2 seconds at the start of every duel',
  'Open Angel Arena games can be spectated live with no delay',
  'Passive experience gain doesn\'t work in Duels',
  'You have questions about the game? Check out our discord server. We might know a few new tricks for your favorite hero',
  'You gain all talents at level 50',
  'Open Angel Arena is best enjoyed with friends (even if they are imaginary)',
  '4 bounty runes will spawn when the game begins and respawn every 3 minutes',
  'Bosses have True Sight when damaged',
  'GPM Spark is overpowered',
  'If Private Pigeon is on your team, farm everything',
  'Bosses are much easier to kill with attack speed slows and magic damage',
  'If you see this text, we will give you an incorporeal bag full of nothing',
  'Protect your team\'s couriers from Mr Fahrenheit at all costs',
  'In Open Angel Arena there are 2 currencies: gold and core points',
  'Unclaimed Runes will be destroyed in developer\'s pits of darkness',
  'You cannot block neutral creep camps from respawning at the minute mark. Griefers get rekt',
  'Scan reveals invisible enemy units and heroes but not wards',
  'Aghanim\'s Shard cannot be purchased until the 12 minute mark',
  'Azazel\'s Scout, unit that can be purchased from the Azazel shop, has flying vision, true sight and 100% magic resistance',
  'You can sell core points for gold by right-clicking on the special item in the main shop',
  'Bosses start regenerating rapidly to full health if not damaged for 5 seconds',
  'Sometimes it is easier to yell at devs to fix the game, than helping them instead',
  'Demon Stone can summon a demon that has True Sight',
  'Tooltips usually provide answers to all your questions. But also keep in mind that Valve is a small indie company and we are not obligated to fix all their errors',
  'Remember that this is only a game',
  'Never question Darkonius\' item builds',
  'Dark Seer can use Ion Shell on invulnerable allies',
  'Ten years since chrisinajar stream'
];

(function() {
  GameEvents.Subscribe('game_rules_state_change', CheckStrategy);
})();

function changeHilariousLoadingText () {
  const incredibleWit = hilariousLoadingPhrases[~~(Math.random() * hilariousLoadingPhrases.length)];

  noDots();
  $.Schedule(1, oneDots);
  $.Schedule(2, twoDots);
  $.Schedule(3, threeDots);
  $.Schedule(4, noDots);
  $.Schedule(5, oneDots);
  $.Schedule(6, twoDots);
  $.Schedule(7, threeDots);

  $.Schedule(8, changeHilariousLoadingText);

  function noDots () {
    $('#ARDMLoading').text = incredibleWit;
  }
  function oneDots () {
    $('#ARDMLoading').text = incredibleWit + '.';
  }
  function twoDots () {
    $('#ARDMLoading').text = incredibleWit + '..';
  }
  function threeDots () {
    $('#ARDMLoading').text = incredibleWit + '...';
  }
}

function HideStrategy () {
  // var bossMarkers = ['Boss1r', 'Boss1d', 'Boss2r', 'Boss2d', 'Boss3r', 'Boss3d', 'Boss4r', 'Boss4d', 'Boss5r', 'Boss5d', 'Duel1', 'Duel2', 'Cave1r', 'Cave1d', 'Cave2r', 'Cave2d', 'Cave3r', 'Cave3d'];

  // bossMarkers.forEach(function (element) {
  //   FindDotaHudElement(element).style.transform = 'translateY(0)';
  //   FindDotaHudElement(element).style.opacity = '1';
  // });
  $('#OAAStrategy').style.opacity = 0;
  $('#OAAStrategy').style.visibility = 'collapse';
  $('#ARDMLoading').style.opacity = 0;
}

function CheckStrategy () {
  if (Game.GameStateIsBefore(DOTA_GameState.DOTA_GAMERULES_STATE_STRATEGY_TIME)) {
    HideStrategy()
  } else if (Game.GameStateIs(DOTA_GameState.DOTA_GAMERULES_STATE_STRATEGY_TIME)) {
    $('#OAAStrategy').style.opacity = 1;
    $('#OAAStrategy').style.visibility = 'visible';
    $('#ARDMLoading').style.opacity = 1;
    changeHilariousLoadingText();
  } else if (Game.GameStateIsAfter(DOTA_GameState.DOTA_GAMERULES_STATE_STRATEGY_TIME)) {
    HideStrategy()
  }
}