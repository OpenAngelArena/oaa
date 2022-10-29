/* global Players $ GameEvents CustomNetTables FindDotaHudElement Game */

'use strict';

if (typeof module !== 'undefined' && module.exports) {
  module.exports = {
    SelectHero: SelectHero,
    CaptainSelectHero: CaptainSelectHero,
    BecomeCaptain: BecomeCaptain,
    RandomHero: RandomHero,
    PreviewHeroCM: PreviewHeroCM,
    RerandomHero: RerandomHero
  };
}

// for testing
const neverHideStrategy = false;

const heroAbilities = {};
const currentMap = Game.GetMapInfo().map_display_name;
let hasGoneToStrategy = false;
let selectedhero = 'empty';
let disabledheroes = [];
let herolocked = false;
let panelscreated = 0;
let iscm = false;
let selectedherocm = 'empty';
let isPicking = true;
let isBanning = false;
let isCMLocking = false;
let canRandom = true;
let canReRandom = false;
let currentHeroPreview = '';
let stepsCompleted = {
  2: 0,
  3: 0
};
let lastPickIndex = 0;
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

init();

function init () {
  $.GetContextPanel().AddClass(currentMap);

  SetupTopBar();

  $('#MainContent').SetHasClass(currentMap, true);

  CustomNetTables.SubscribeNetTableListener('hero_selection', onPlayerStatChange);
  CustomNetTables.SubscribeNetTableListener('bottlepass', UpdateBottleList);
  CustomNetTables.SubscribeNetTableListener('oaa_settings', handleOAASettingsChange);
  GameEvents.Subscribe('oaa_random_hero_message', SendMessageToTeam);

  // load hero selection
  onPlayerStatChange(null, 'abilities_DOTA_ATTRIBUTE_STRENGTH', CustomNetTables.GetTableValue('hero_selection', 'abilities_DOTA_ATTRIBUTE_STRENGTH'));
  onPlayerStatChange(null, 'abilities_DOTA_ATTRIBUTE_AGILITY', CustomNetTables.GetTableValue('hero_selection', 'abilities_DOTA_ATTRIBUTE_AGILITY'));
  onPlayerStatChange(null, 'abilities_DOTA_ATTRIBUTE_INTELLECT', CustomNetTables.GetTableValue('hero_selection', 'abilities_DOTA_ATTRIBUTE_INTELLECT'));
  onPlayerStatChange(null, 'herolist', CustomNetTables.GetTableValue('hero_selection', 'herolist'));

  onPlayerStatChange(null, 'APdata', CustomNetTables.GetTableValue('hero_selection', 'APdata'));
  onPlayerStatChange(null, 'CMdata', CustomNetTables.GetTableValue('hero_selection', 'CMdata'));
  onPlayerStatChange(null, 'rankedData', CustomNetTables.GetTableValue('hero_selection', 'rankedData'));
  onPlayerStatChange(null, 'time', CustomNetTables.GetTableValue('hero_selection', 'time'));
  onPlayerStatChange(null, 'preview_table', CustomNetTables.GetTableValue('hero_selection', 'preview_table'));
  ReloadCMStatus(CustomNetTables.GetTableValue('hero_selection', 'CMdata'));
  UpdatePreviews(CustomNetTables.GetTableValue('hero_selection', 'preview_table'));

  handleOAASettingsChange(null, 'locked', CustomNetTables.GetTableValue('oaa_settings', 'locked'));

  changeHilariousLoadingText();
  UpdateBottleList();

  // there are rumors this makes CM worse but i'll believe it when i see it
  EnableChatWindow();

  $('#ARDMLoading').style.opacity = 0;
}

function handleOAASettingsChange (n, key, settings) {
  if (key !== 'locked') {
    return;
  }

  const infoPanel = $('#ExtraInfo');

  if (!infoPanel) {
    return;
  }

  const lines = [];

  lines.push($.Localize('#game_options_hero_selection') + ' ' + $.Localize('#game_option_' + settings.GAME_MODE.toLowerCase()));
  lines.push('');

  const heroModifierNames = {
    HMR: '#game_option_random',
    HM01: '#game_option_lifesteal',
    HM02: '#game_option_aoe_radius',
    HM03: '#game_option_blood_magic',
    HM04: '#game_option_timeless_relic',
    HM05: '#game_option_echo_strike',
    HM06: '#game_option_hyper_active',
    HM07: '#game_option_no_cast_points',
    HM08: '#game_option_physical_immune',
    HM09: '#game_option_pro_active',
    HM10: '#game_option_spell_block',
    HM11: '#game_option_troll_switch',
    HM12: '#game_option_hyper_experience',
    HM13: '#game_option_diarrhetic',
    HM14: '#game_option_rend',
    HM15: '#game_option_telescope',
    HM16: '#game_option_healer',
    HM17: '#game_option_explosive_death',
    HM18: '#game_option_no_hp_bar',
    HM19: '#game_option_brute',
    HM20: '#game_option_wisdom',
    HM21: '#game_option_aghanim',
    HM22: '#game_option_nimble',
    HM23: '#game_option_sorcerer',
    HM24: '#game_option_max_power',
    HM25: '#game_option_hp_mana_switch',
    HM26: '#game_option_magus',
    HM27: '#game_option_brawler'
  };

  if (settings.HEROES_MODS !== 'HMN' || settings.HEROES_MODS_2 !== 'HMN') {
    lines.push($.Localize('#hero_options_title'));

    if (settings.HEROES_MODS !== 'HMN') {
      lines.push(' ' + $.Localize(heroModifierNames[settings.HEROES_MODS] + '_description'));
      lines.push('');
    }

    if (settings.HEROES_MODS_2 !== 'HMN') {
      lines.push(' ' + $.Localize(heroModifierNames[settings.HEROES_MODS_2] + '_description'));
      lines.push('');
    }
  }

  if (settings.BOSSES_MODS !== 'BMN') {
    const modifierNames = {
      BMR: '#game_option_random',
      BM01: '#game_option_lifesteal',
      BM02: '#game_option_echo_strike',
      BM03: '#game_option_physical_immune',
      BM04: '#game_option_spell_block',
      BM05: '#game_option_no_cast_points',
      BM06: '#game_option_hyper_active',
      BM07: '#game_option_agressive_bosses',
      BM08: '#game_option_brawler'
    };

    lines.push($.Localize('#boss_options_title') + ' ' + $.Localize(modifierNames[settings.BOSSES_MODS] + '_description'));
    lines.push('');
  }

  if (settings.GLOBAL_MODS !== 'GMN') {
    const modifierNames = {
      GMR: '#game_option_random',
      GM01: '#game_option_lifesteal_global',
      GM02: '#game_option_aoe_radius',
      GM08: '#game_option_physical_immune',
      GM09: '#game_option_pro_active',
      GM12: '#game_option_buyback'
    };

    lines.push($.Localize('#units_options_title') + ' ' + $.Localize(modifierNames[settings.GLOBAL_MODS] + '_description'));
    lines.push('');
  }

  infoPanel.text = lines.join('\n');
}

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

function onPlayerStatChange (table, key, data) {
  const teamID = Players.GetTeam(Game.GetLocalPlayerID());
  let newimage = null;
  if (data &&
    (key === 'abilities_DOTA_ATTRIBUTE_STRENGTH' ||
    key === 'abilities_DOTA_ATTRIBUTE_AGILITY' ||
    key === 'abilities_DOTA_ATTRIBUTE_INTELLECT')
  ) {
    Object.keys(data).forEach(function (heroName) {
      heroAbilities[heroName] = data[heroName];
    });
  } else if (key === 'rankedData' && data != null) {
    UpdatedRankedPickState(data);
  } else if (key === 'herolist' && data != null) {
    const strengthholder = FindDotaHudElement('StrengthHeroes');
    const agilityholder = FindDotaHudElement('AgilityHeroes');
    const intelligenceholder = FindDotaHudElement('IntelligenceHeroes');
    Object.keys(data.herolist).sort().forEach(function (heroName) {
      let currentstat = null;

      switch (data.herolist[heroName]) {
        case 'DOTA_ATTRIBUTE_STRENGTH':
          currentstat = strengthholder;
          break;
        case 'DOTA_ATTRIBUTE_AGILITY':
          currentstat = agilityholder;
          break;
        case 'DOTA_ATTRIBUTE_INTELLECT':
          currentstat = intelligenceholder;
          break;
      }
      const newhero = $.CreatePanel('RadioButton', currentstat, heroName);
      newhero.group = 'HeroChoises';
      newhero.SetPanelEvent('onactivate', function () { PreviewHero(heroName); });
      const newheroimage = $.CreatePanel('DOTAHeroImage', newhero, '');
      newheroimage.hittest = false;
      newheroimage.AddClass('HeroCard');
      ChangeHeroImage(newheroimage, heroName);
    });
  } else if (key === 'preview_table' && data != null) {
    UpdatePreviews(data);
  } else if (key === 'APdata' && data != null) {
    canReRandom = data[Game.GetLocalPlayerID()] && data[Game.GetLocalPlayerID()].selectedhero !== 'empty' && data[Game.GetLocalPlayerID()].didRandom === 'true';
    const length = Object.keys(data).length;
    if (panelscreated !== length) {
      // initial load stuff
      const teamdire = FindDotaHudElement('TeamDire');
      const teamradiant = FindDotaHudElement('TeamRadiant');
      panelscreated = length;
      teamdire.RemoveAndDeleteChildren();
      teamradiant.RemoveAndDeleteChildren();
      Object.keys(data).forEach(function (nkey) {
        let currentteam = null;
        switch (data[nkey].team) {
          case 2:
            currentteam = teamradiant;
            break;
          case 3:
            currentteam = teamdire;
            break;
        }
        const newelement = $.CreatePanel('Panel', currentteam, '');
        newelement.AddClass('Player');
        newimage = $.CreatePanel('DOTAHeroImage', newelement, data[nkey].steamid);
        newimage.hittest = false;
        newimage.AddClass('PlayerImage');
        ChangeHeroImage(newimage, data[nkey].selectedhero);
        const newlabel = $.CreatePanel('DOTAUserName', newelement, '');
        newlabel.AddClass('PlayerLabel');
        newlabel.steamid = data[nkey].steamid;

        DisableHero(data[nkey].selectedhero);
        if (iscm) {
          if (data[nkey].selectedhero !== 'empty') {
            ChangeHeroImage(FindDotaHudElement('CMStep' + nkey), data[nkey].selectedhero);
            const label = FindDotaHudElement('CMHeroPickLabel_' + data[nkey].selectedhero);

            label.style.visibility = 'collapse';
            label.steamid = null;
            FindDotaHudElement('CMHeroPickLabel_' + data[nkey].selectedhero).steamid = data[nkey].steamid;
            FindDotaHudElement('CMHeroPickLabel_' + data[nkey].selectedhero).style.visibility = 'visible';
          } else {
            FindDotaHudElement('CMHeroPickLabel_' + data[nkey].selectedhero).steamid = data[nkey].steamid;
            FindDotaHudElement('CMHeroPickLabel_' + data[nkey].selectedhero).style.visibility = 'collapse';
          }
        }
      });
    } else {
      // captains mode stuff
      if (iscm) {
        const cmData = CustomNetTables.GetTableValue('hero_selection', 'CMdata');
        Object.keys(cmData.order).forEach(function (nkey) {
          const obj = cmData.order[nkey];
          ChangeHeroImage(FindDotaHudElement('CMStep' + nkey).heroname, obj.hero);
          FindDotaHudElement('CMStep' + nkey).RemoveClass('active');
          if (obj.side === teamID && obj.type === 'Pick' && obj.hero !== 'empty') {
            const label = FindDotaHudElement('CMHeroPickLabel_' + obj.hero);

            label.style.visibility = 'collapse';
            label.steamid = null;
          }
        });
      }

      // general picking stuff
      Object.keys(data).forEach(function (nkey) {
        const currentplayer = FindDotaHudElement(data[nkey].steamid);
        if (currentplayer !== null) {
          ChangeHeroImage(currentplayer, data[nkey].selectedhero);
          currentplayer.RemoveClass('PreviewHero');
        }

        DisableHero(data[nkey].selectedhero);
        if (iscm && FindDotaHudElement('CMHeroPickLabel_' + data[nkey].selectedhero)) {
          if (data[nkey].steamid) {
            FindDotaHudElement('CMHeroPickLabel_' + data[nkey].selectedhero).steamid = data[nkey].steamid;
            FindDotaHudElement('CMHeroPickLabel_' + data[nkey].selectedhero).style.visibility = 'visible';
            // FindDotaHudElement('CMHeroPick_' + data[nkey].selectedhero).style.brightness = 0.2;
          } else {
            FindDotaHudElement('CMHeroPickLabel_' + data[nkey].selectedhero).steamid = data[nkey].steamid;
            FindDotaHudElement('CMHeroPickLabel_' + data[nkey].selectedhero).style.visibility = 'collapse';
            // FindDotaHudElement('CMHeroPick_' + data[nkey].selectedhero).style.brightness = 1;
          }
        }
      });
    }
    UpdatePreviews();
    UpdateButtons();
  } else if (key === 'CMdata' && data != null) {
    iscm = true;
    const teamName = teamID === 2 ? 'radiant' : 'dire';
    if (data['captain' + teamName] === 'empty') {
      isPicking = false;
      // "BECOME CAPTAIN" button
      FindDotaHudElement('CMPanel').style.visibility = 'visible';
      FindDotaHudElement('CMHeroPreview').style.visibility = 'collapse';
      // FindDotaHudElement('HeroPreview').style.visibility = 'collapse';
      FindDotaHudElement('HeroLockIn').style.visibility = 'collapse';
      FindDotaHudElement('HeroRandom').style.visibility = 'collapse';
      FindDotaHudElement('HeroReRandom').style.visibility = 'collapse';
      FindDotaHudElement('BecomeCaptain').style.visibility = 'visible';
      return;
    } else {
      FindDotaHudElement('CMPanel').style.visibility = 'visible';
      FindDotaHudElement('CMProgress').style.visibility = 'visible';
      FindDotaHudElement('CMHeroPreview').style.visibility = 'collapse';
      FindDotaHudElement('HeroLockIn').style.visibility = 'collapse';
      FindDotaHudElement('HeroRandom').style.visibility = 'collapse';
      FindDotaHudElement('HeroReRandom').style.visibility = 'collapse';
      FindDotaHudElement('BecomeCaptain').style.visibility = 'collapse';
    }
    FindDotaHudElement('RadiantReserve').text = data.reserveradiant;
    FindDotaHudElement('DireReserve').text = data.reservedire;

    if (data.currentstage < data.totalstages || (data.order[data.currentstage] && data.order[data.currentstage].hero === 'empty')) {
      if (!data.order[data.currentstage]) {
        return;
      }
      FindDotaHudElement('CMPanel').style.visibility = 'visible';
      FindDotaHudElement('CMHeroPreview').style.visibility = 'collapse';
      FindDotaHudElement('HeroLockIn').style.visibility = 'collapse';
      FindDotaHudElement('HeroRandom').style.visibility = 'collapse';
      FindDotaHudElement('HeroReRandom').style.visibility = 'collapse';
      FindDotaHudElement('BecomeCaptain').style.visibility = 'collapse';
      let currentPick = null;
      let currentPickIndex = 0;
      if (data.order[data.currentstage].hero === 'empty') {
        currentPickIndex = data.currentstage;
        currentPick = data.order[currentPickIndex];
      } else {
        currentPickIndex = data.currentstage + 1;
        currentPick = data.order[currentPickIndex];
      }
      if (currentPickIndex > lastPickIndex) {
        stepsCompleted[currentPick.side]++;
        lastPickIndex = currentPickIndex;
      }
      $.Msg(currentPick);
      $.Msg(stepsCompleted);

      FindDotaHudElement('CMRadiantProgress').style.width = ~~(stepsCompleted[2] / (data.totalstages / 2) * 100) + '%';
      FindDotaHudElement('CMDireProgress').style.width = ~~(stepsCompleted[3] / (data.totalstages / 2) * 100) + '%';
      FindDotaHudElement('CMStep' + currentPickIndex).AddClass('active');

      FindDotaHudElement('CMRadiant').RemoveClass('Pick');
      FindDotaHudElement('CMRadiant').RemoveClass('Ban');
      FindDotaHudElement('CMDire').RemoveClass('Pick');
      FindDotaHudElement('CMDire').RemoveClass('Ban');

      if (currentPick.side === 2) {
        FindDotaHudElement('CMRadiant').AddClass(currentPick.type);
      } else {
        FindDotaHudElement('CMDire').AddClass(currentPick.type);
      }

      FindDotaHudElement('CaptainLockIn').RemoveClass('PickHero');
      FindDotaHudElement('CaptainLockIn').RemoveClass('BanHero');
      FindDotaHudElement('CaptainLockIn').AddClass(currentPick.type + 'Hero');

      if (data.order[data.currentstage] && data.order[data.currentstage].hero && data.order[data.currentstage].hero !== 'empty') {
        ChangeHeroImage(FindDotaHudElement('CMStep' + data.currentstage), data.order[data.currentstage].hero);
        FindDotaHudElement('CMStep' + data.currentstage).RemoveClass('active');
        DisableHero(data.order[data.currentstage].hero);
      }
      $.Msg(data.currentstage + ', ' + currentPick.side);
      if (Game.GetLocalPlayerID() === data['captain' + teamName] && teamID === currentPick.side) {
        // FindDotaHudElement('CaptainLockIn').style.visibility = 'visible';
        isPicking = true;
        isBanning = currentPick.type === 'Ban';
        PreviewHero();
      } else {
        isPicking = false;
        PreviewHero();
      }
    } else if (data.currentstage === data.totalstages) {
      ChangeHeroImage(FindDotaHudElement('CMStep' + data.currentstage), data.order[data.currentstage].hero);
      DisableHero(data.order[data.currentstage].hero);
      FindDotaHudElement('CMPanel').style.visibility = 'visible';
      FindDotaHudElement('HeroLockIn').style.visibility = 'collapse';
      FindDotaHudElement('HeroRandom').style.visibility = 'collapse';
      FindDotaHudElement('HeroReRandom').style.visibility = 'collapse';
      FindDotaHudElement('HeroPreview').style.visibility = 'collapse';
      FindDotaHudElement('BecomeCaptain').style.visibility = 'collapse';
      FindDotaHudElement('CaptainLockIn').style.visibility = 'collapse';
      DisableHero(data.order[data.currentstage].hero);

      ReloadCMStatus(data);
      disabledheroes = [];
      FindDotaHudElement('SectionTitle').style.visibility = 'collapse';
      FindDotaHudElement('CMHeroPreview').style.visibility = 'visible';
      isCMLocking = true;
    }
  } else if (key === 'time' && data != null) {
    // $.Msg(data);
    if (data.mode === 'STRATEGY' || data.mode === 'PRE-GAME') {
      FindDotaHudElement('TimeLeft').text = 'VS';
      FindDotaHudElement('GameMode').text = $.Localize(data.mode);
      if (data.mode === 'STRATEGY') {
        GoToStrategy();
      }
    } else if (data.time > -1) {
      $('#TimeLeft').text = data.time;
      $('#GameMode').text = $.Localize(data.mode);
      // spammy
      // $.Msg('Timer mode ' + data.mode);
    } else {
      HideStrategy();
    }
  }
}

function UpdatedRankedPickState (data) {
  $.Msg(data);

  const bans = Object.keys(data.bans)
    .map(function (key) { return data.bans[key]; })
    .filter(function (banned) { return banned !== 'empty'; });

  Object.keys(data.banChoices)
    .map(function (key) { return data.banChoices[key]; })
    .filter(function (banned) { return banned !== 'empty'; })
    .forEach(function (banned) {
      if (data.phase === 'bans' || data.phase === 'start') {
        if (!IsHeroDisabled(banned)) {
          DisableHero(banned);
        }
      } else {
        if (bans.indexOf(banned) === -1 && IsHeroDisabled(banned)) {
          EnableHero(banned);
        }
      }
    });

  bans.forEach(function (banned) {
    $.Msg('Banned hero: ' + banned);
    if (!IsHeroDisabled(banned)) {
      DisableHero(banned);
    }
  });

  Object.keys(data.order)
    .map(function (key) { return data.order[key].hero; })
    .filter(function (banned) { return banned !== 'empty'; })
    .forEach(function (banned) {
      if (!IsHeroDisabled(banned)) {
        DisableHero(banned);
      }
    });
  const teamID = Players.GetTeam(Game.GetLocalPlayerID());
  const order = data.order[data.currentOrder + ''];
  const apData = CustomNetTables.GetTableValue('hero_selection', 'APdata');

  switch (data.phase) {
    case 'start':
      isPicking = false;
      break;
    case 'bans':
      $.Msg(data.banChoices[Game.GetLocalPlayerID()]);
      isPicking = !data.banChoices[Game.GetLocalPlayerID()];
      herolocked = false;
      canRandom = false;
      canReRandom = false;
      isBanning = true;

      break;
    case 'picking':
      isBanning = false;
      if (order.team === teamID) {
        isPicking = !apData[Game.GetLocalPlayerID()] || apData[Game.GetLocalPlayerID()].selectedhero === 'empty';
        herolocked = !isPicking;
        canRandom = order.canRandom !== false;
        $.Msg('Set hero picking state and stuff ' + isPicking + '/' + apData[Game.GetLocalPlayerID()].selectedhero + JSON.stringify(apData[Game.GetLocalPlayerID()]));
      } else {
        isPicking = false;
        $.Msg('Not my turn ' + order.team + ' / ' + teamID);
        $.Msg(data.currentOrder);
        $.Msg(data.order);
        $.Msg(order);
      }

      canReRandom = apData[Game.GetLocalPlayerID()] && apData[Game.GetLocalPlayerID()].selectedhero !== 'empty' && apData[Game.GetLocalPlayerID()].didRandom === 'true';

      break;
  }
  UpdateButtons();
}

function UpdateButtons () {
  if (IsHeroDisabled(selectedhero)) {
    FindDotaHudElement('HeroLockIn').style.visibility = 'collapse';
    FindDotaHudElement('HeroBan').style.visibility = 'collapse';
    FindDotaHudElement('HeroRandom').style.visibility = 'collapse';
    FindDotaHudElement('HeroReRandom').style.visibility = 'collapse';
    return;
  }
  FindDotaHudElement('HeroLockIn').style.visibility = isPicking && !isBanning ? 'visible' : 'collapse';
  FindDotaHudElement('HeroBan').style.visibility = isPicking && isBanning ? 'visible' : 'collapse';
  FindDotaHudElement('HeroRandom').style.visibility = isPicking && canRandom ? 'visible' : 'collapse';
  FindDotaHudElement('HeroReRandom').style.visibility = canReRandom ? 'visible' : 'collapse';
}

function SetupTopBar () {
  if (currentMap !== '10v10') {
    return;
  }

  $.GetContextPanel().SetHasClass('TenVTen', true);
  const topbar = FindDotaHudElement('topbar');
  topbar.style.width = '1550px';

  // Top Bar Radiant
  const TopBarRadiantTeam = FindDotaHudElement('TopBarRadiantTeam');
  TopBarRadiantTeam.style.width = '690px';

  const topbarRadiantPlayers = FindDotaHudElement('TopBarRadiantPlayers');
  topbarRadiantPlayers.style.width = '690px';

  const topbarRadiantPlayersContainer = FindDotaHudElement('TopBarRadiantPlayersContainer');
  topbarRadiantPlayersContainer.style.width = '630px';
  FillTopBarPlayer(topbarRadiantPlayersContainer);

  const RadiantTeamContainer = FindDotaHudElement('RadiantTeamContainer');
  RadiantTeamContainer.style.height = '737px';

  // Top Bar Dire
  const TopBarDireTeam = FindDotaHudElement('TopBarDireTeam');
  TopBarDireTeam.style.width = '690px';

  const topbarDirePlayers = FindDotaHudElement('TopBarDirePlayers');
  topbarDirePlayers.style.width = '690px';

  const topbarDirePlayersContainer = FindDotaHudElement('TopBarDirePlayersContainer');
  topbarDirePlayersContainer.style.width = '630px';
  FillTopBarPlayer(topbarDirePlayersContainer);

  const DireTeamContainer = FindDotaHudElement('DireTeamContainer');
  DireTeamContainer.style.height = '737px';
}

function FillTopBarPlayer (TeamContainer) {
  // Fill players top bar in case on partial lobbies
  const playerCount = TeamContainer.GetChildCount();
  for (let i = playerCount + 1; i <= 10; i++) {
    const newPlayer = $.CreatePanel('DOTATopBarPlayer', TeamContainer, 'RadiantPlayer-1');
    if (newPlayer) {
      newPlayer.FindChildTraverse('PlayerColor').style.backgroundColor = '#FFFFFFFF';
    }
    newPlayer.SetHasClass('EnemyTeam', true);
  }
}

function EnableChatWindow () {
  const pregamePanel = FindDotaHudElement('PreGame');
  pregamePanel.style.zIndex = 10;
  pregamePanel.style.backgroundColor = 'transparent';
  const contentPanel = pregamePanel.FindChildTraverse('MainContents');
  if (contentPanel) {
    contentPanel.style.visibility = 'collapse';
  }
  const backgroundPanel = pregamePanel.FindChildTraverse('PregameBGStatic');
  if (backgroundPanel) {
    backgroundPanel.style.visibility = 'collapse';
  }
  const backgroundDashboardPanel = pregamePanel.FindChildTraverse('PregameBG');
  if (backgroundDashboardPanel) {
    backgroundDashboardPanel.style.visibility = 'collapse';
  }
  const radiantTeamPanel = pregamePanel.FindChildTraverse('RadiantTeamPlayers');
  if (radiantTeamPanel) {
    radiantTeamPanel.style.visibility = 'collapse';
  }
  const direTeamPanel = pregamePanel.FindChildTraverse('DireTeamPlayers');
  if (direTeamPanel) {
    direTeamPanel.style.visibility = 'collapse';
  }
  const headerPanel = pregamePanel.FindChildTraverse('Header');
  if (headerPanel) {
    headerPanel.style.visibility = 'collapse';
  }
  const minimapPanel = pregamePanel.FindChildTraverse('PreMinimapContainer');
  if (minimapPanel) {
    minimapPanel.style.visibility = 'collapse';
  }
  const friendsAndFoesPanel = pregamePanel.FindChildTraverse('FriendsAndFoes');
  if (friendsAndFoesPanel) {
    friendsAndFoesPanel.style.visibility = 'collapse';
  }
  const panel2 = pregamePanel.FindChildTraverse('HeroPickingTeamComposition');
  if (panel2) {
    panel2.style.visibility = 'collapse';
  }
  const panel3 = pregamePanel.FindChildTraverse('PlusChallengeSelector');
  if (panel3) {
    panel3.style.visibility = 'collapse';
  }
  const panel4 = pregamePanel.FindChildTraverse('AvailableItemsContainer');
  if (panel4) {
    panel4.style.visibility = 'collapse';
  }
}

function UpdatePreviews (data) {
  if (!data) {
    data = CustomNetTables.GetTableValue('hero_selection', 'preview_table');
  }
  if (!data) {
    return;
  }
  const apData = CustomNetTables.GetTableValue('hero_selection', 'APdata');
  const heroesBySteamid = {};
  Object.keys(apData).forEach(function (playerId) {
    if (apData[playerId].selectedhero && apData[playerId].selectedhero !== 'empty' && apData[playerId].selectedhero !== 'random') {
      heroesBySteamid[apData[playerId].steamid] = apData[playerId].selectedhero;
    }
  });
  const teamID = Players.GetTeam(Game.GetLocalPlayerID());
  Object.keys(data[teamID] || {}).forEach(function (steamid) {
    if (heroesBySteamid[steamid]) {
      return;
    }
    const player = FindDotaHudElement(steamid);
    if (player) {
      ChangeHeroImage(player, data[teamID][steamid]);
      player.AddClass('PreviewHero');
    }
  });
  Object.keys(heroesBySteamid).forEach(function (steamid) {
    const player = FindDotaHudElement(steamid);
    ChangeHeroImage(player, heroesBySteamid[steamid]);
  });
}

function ChangeHeroImage (container, hero) {
  // if you give this long "npc_dota_hero_blah" or short "blah" names they both work
  container.heroname = hero;
  // when we read the value, it's always the short-hand version without the prefix
  const shortHeroName = container.heroname;
  if (shortHeroName === 'sohei' || shortHeroName === 'electrician') {
    // re-add prefix
    container.style.backgroundImage = 'url("file://{images}/heroes/npc_dota_hero_' + shortHeroName + '.png")';
    container.style.backgroundSize = '100% 100%';
  }
}

function ReloadCMStatus (data) {
  if (!data) {
    return;
  }
  // reset all data for people, who lost it
  const teamID = Players.GetTeam(Game.GetLocalPlayerID());
  stepsCompleted = {
    2: 0,
    3: 0
  };

  let currentPick = null;
  if (!data.order[data.currentstage]) {
    return;
  }
  if (data.order[data.currentstage].hero === 'empty') {
    currentPick = data.currentstage;
  } else {
    currentPick = data.currentstage + 1;
  }
  const currentPickData = data.order[currentPick];

  if (data.currentstage === data.totalstages) {
    FindDotaHudElement('CMHeroPreview').RemoveAndDeleteChildren();
    Object.keys(data.order).forEach(function (nkey) {
      const obj = data.order[nkey];
      // FindDotaHudElement('CMStep' + nkey).heroname = obj.hero;
      if (obj.hero !== 'empty') {
        DisableHero(obj.hero);
      }

      // the "select your hero at the end" thing
      if (obj.side === teamID && obj.type === 'Pick' && obj.hero !== 'empty') {
        $('#MainContent').SetHasClass('CMHeroChoices', true);

        const newbutton = $.CreatePanel('RadioButton', FindDotaHudElement('CMHeroPreview'), '');
        newbutton.group = 'CMHeroChoises';
        newbutton.AddClass('CMHeroPreviewItem');
        newbutton.SetPanelEvent('onactivate', function () { SelectHero(obj.hero); });
        $.CreatePanelWithProperties('Label', newbutton, '', { class: 'HeroPickLabel', text: '#' + obj.hero });

        CreateHeroPanel(newbutton, obj.hero);
        const newlabel = $.CreatePanel('DOTAUserName', newbutton, 'CMHeroPickLabel_' + obj.hero);
        newlabel.style.visibility = 'collapse';
        newlabel.steamid = null;
      }

      // the CM picking order phase thingy
      if (obj.hero && obj.hero !== 'empty') {
        ChangeHeroImage(FindDotaHudElement('CMStep' + nkey), obj.hero);
        FindDotaHudElement('CMStep' + nkey).RemoveClass('active');

        FindDotaHudElement('CMRadiant').RemoveClass('Pick');
        FindDotaHudElement('CMRadiant').RemoveClass('Ban');
        FindDotaHudElement('CMDire').RemoveClass('Pick');
        FindDotaHudElement('CMDire').RemoveClass('Ban');
      }

      if (currentPick >= nkey) {
        stepsCompleted[obj.side]++;
        lastPickIndex = nkey;
      }
    });
  }
  $.Msg(stepsCompleted);
  FindDotaHudElement('CMRadiantProgress').style.width = ~~(stepsCompleted[2] / (data.totalstages / 2) * 100) + '%';
  FindDotaHudElement('CMDireProgress').style.width = ~~(stepsCompleted[3] / (data.totalstages / 2) * 100) + '%';
  if (currentPick < data.totalstages) {
    FindDotaHudElement('CMStep' + currentPick).AddClass('active');

    if (currentPickData.side === 2) {
      FindDotaHudElement('CMRadiant').AddClass(currentPickData.type);
    } else {
      FindDotaHudElement('CMDire').AddClass(currentPickData.type);
    }
  }
}

function EnableHero (name) {
  if (FindDotaHudElement(name) != null) {
    FindDotaHudElement(name).RemoveClass('Disabled');
    if (IsHeroDisabled(name)) {
      disabledheroes.splice(disabledheroes.indexOf(name), 1);
    }
  }
}

function DisableHero (name) {
  if (FindDotaHudElement(name) != null) {
    FindDotaHudElement(name).AddClass('Disabled');
    if (!IsHeroDisabled(name)) {
      disabledheroes.push(name);
    }
  }
}

function IsHeroDisabled (name) {
  // if it's not -1 it's in the disabled list
  return disabledheroes.indexOf(name) !== -1;
}

function PreviewHero (name) {
  let lockButton = null;
  if (iscm) {
    lockButton = FindDotaHudElement('CaptainLockIn');
  } else {
    lockButton = FindDotaHudElement('HeroLockIn');
  }
  if (!name) {
    if (selectedhero === 'empty') {
      lockButton.style.visibility = 'collapse';
      return;
    }
    name = selectedhero;
  }
  if (!herolocked || iscm) {
    const preview = FindDotaHudElement('HeroPreview');
    if (name !== 'random' && currentHeroPreview !== name) {
      currentHeroPreview = name;
      preview.RemoveAndDeleteChildren();
      CreateHeroPanel(preview, name);
      $('#SectionTitle').text = $.Localize('#' + name, $('#SectionTitle'));

      const abilityPreview = $('#AbilityPreview');
      abilityPreview.RemoveAndDeleteChildren();
      Object.keys(heroAbilities[name]).forEach(function (i) {
        const ability = heroAbilities[name][i];
        if (ability === 'generic_hidden') {
          return;
        }
        CreateAbilityPanel(abilityPreview, ability);
      });

      UpdateBottlePassArcana(name);
    }
    selectedhero = name;
    selectedherocm = name;

    UpdateButtons();

    GameEvents.SendCustomGameEventToServer('preview_hero', {
      hero: name
    });
  }
}

function UpdateBottlePassArcana (heroName) {
  const playerID = Game.GetLocalPlayerID();
  $('#ArcanaSelection').RemoveAndDeleteChildren();

  if (heroName !== 'npc_dota_hero_sohei' && heroName !== 'npc_dota_hero_electrician') {
    $('#ArcanaPanel').SetHasClass('HasArcana', false);
    return;
  }
  $('#ArcanaPanel').SetHasClass('HasArcana', true);

  const selectedArcanas = CustomNetTables.GetTableValue('bottlepass', 'selected_arcanas');
  let selectedArcana = 'DefaultSet';

  if (selectedArcanas !== undefined && selectedArcanas[playerID.toString()] !== undefined) {
    selectedArcana = selectedArcanas[playerID.toString()][heroName];
  }

  $.Schedule(0.2, function () {
    $.Msg('UpdateBottlePassArcana(' + heroName + ')');
    let arcanas = null;

    const specialArcanas = CustomNetTables.GetTableValue('bottlepass', 'special_arcanas');
    for (const arcanaIndex in specialArcanas) {
      if (specialArcanas[arcanaIndex].PlayerId === playerID) {
        arcanas = specialArcanas[arcanaIndex].Arcanas;
      }
    }
    let radio = null;
    if (heroName === 'npc_dota_hero_sohei') {
      radio = $.CreatePanel('RadioButton', $('#ArcanaSelection'), 'DefaultSoheiSet');
      radio.BLoadLayoutSnippet('ArcanaRadio');
      radio.hero = heroName;
      radio.setName = 'DefaultSet';
      radio.checked = selectedArcana === radio.setName;

      for (const index in arcanas) {
        if (arcanas[index] === 'DBZSohei') {
          radio = $.CreatePanel('RadioButton', $('#ArcanaSelection'), 'DBZSoheiSet');
          radio.BLoadLayoutSnippet('ArcanaRadio');
          radio.hero = heroName;
          radio.setName = 'DBZSohei';
          radio.checked = selectedArcana === radio.setName;
        }
        if (arcanas[index] === 'PepsiSohei') {
          radio = $.CreatePanel('RadioButton', $('#ArcanaSelection'), 'PepsiSoheiSet');
          radio.BLoadLayoutSnippet('ArcanaRadio');
          radio.hero = heroName;
          radio.setName = 'PepsiSohei';
          radio.checked = selectedArcana === radio.setName;
        }
      }
    } else if (heroName === 'npc_dota_hero_electrician') {
      radio = $.CreatePanel('RadioButton', $('#ArcanaSelection'), 'DefaultElectricianSet');
      radio.BLoadLayoutSnippet('ArcanaRadio');
      radio.hero = heroName;
      radio.setName = 'DefaultSet';
      radio.checked = selectedArcana === radio.setName;

      for (const index2 in arcanas) {
        if (arcanas[index2] === 'RockElectrician') {
          radio = $.CreatePanel('RadioButton', $('#ArcanaSelection'), 'RockElectricianSet');
          radio.BLoadLayoutSnippet('ArcanaRadio');
          radio.hero = heroName;
          radio.setName = 'RockElectrician';
          radio.checked = selectedArcana === radio.setName;
        }
      }
    }
    SelectArcana();
  });
}

function SelectArcana () {
  const arcanasList = $('#ArcanaSelection');
  if (arcanasList.GetChildCount() > 0) {
    const selectedArcana = $('#ArcanaSelection').Children()[0].GetSelectedButton();

    if (!selectedArcana) {
      $.Schedule(0.1, SelectArcana);
      return;
    }

    const id = 'Scene' + ~~(Math.random() * 100);
    const preview = FindDotaHudElement('HeroPreview');
    preview.RemoveAndDeleteChildren();
    if (selectedArcana.setName !== 'DefaultSet') {
      $.CreatePanelWithProperties('DOTAScenePanel', preview, id, {
        style: "opacity-mask: url('s2r://panorama/images/masks/softedge_box_png.vtex');",
        map: 'prefabs\\heroes\\' + selectedArcana.setName,
        particleonly: 'false',
        renderdeferred: 'false',
        camera: 'camera1',
        rotateonhover: 'true',
        yawmin: '-10',
        yawmax: '10',
        pitchmin: '-10',
        pitchmax: '10'
      });
    } else {
      if (selectedArcana.hero === 'npc_dota_hero_sohei') {
        $.CreatePanelWithProperties('DOTAScenePanel', preview, id, {
          style: "opacity-mask: url('s2r://panorama/images/masks/softedge_box_png.vtex');",
          map: 'prefabs\\heroes\\sohei',
          particleonly: 'false',
          renderdeferred: 'false',
          camera: 'camera1',
          rotateonhover: 'true',
          yawmin: '-10',
          yawmax: '10',
          pitchmin: '-10',
          pitchmax: '10'
        });
      } else if (selectedArcana.hero === 'npc_dota_hero_electrician') {
        $.CreatePanelWithProperties('DOTAScenePanel', preview, id, {
          style: "opacity-mask: url('s2r://panorama/images/masks/softedge_box_png.vtex');",
          map: 'prefabs\\heroes\\electrician',
          particleonly: 'false',
          renderdeferred: 'false',
          camera: 'camera1',
          rotateonhover: 'true',
          yawmin: '-10',
          yawmax: '10',
          pitchmin: '-10',
          pitchmax: '10'
        });
      }
    }

    const data = {
      Hero: selectedArcana.hero,
      Arcana: selectedArcana.setName
    };

    $.Msg('Selecting Arcana ' + data.Arcana + ' for Player #' + Game.GetLocalPlayerID() + ' for hero ' + data.Hero);
    GameEvents.SendCustomGameEventToServer('arcana_selected', data);
  }
}

function UpdateBottleList () {
  const playerID = Game.GetLocalPlayerID();
  const specialBottles = CustomNetTables.GetTableValue('bottlepass', 'special_bottles');
  if (!specialBottles) {
    $.Schedule(0.2, UpdateBottleList);
    return;
  }
  const bottles = specialBottles[playerID.toString()] ? specialBottles[playerID.toString()].Bottles : {};

  if ($('#BottleSelection').GetChildCount() === Object.keys(bottles).length + 1) {
    // ignore repaint if radio is already filled
    return;
  }

  $('#BottleSelection').RemoveAndDeleteChildren();
  // Wait the parent be updated
  $.Schedule(0.2, function () {
    let selectedBottle;

    const selectedBottles = CustomNetTables.GetTableValue('bottlepass', 'selected_bottles');
    if (selectedBottles !== undefined && selectedBottles[playerID.toString()] !== undefined) {
      selectedBottle = selectedBottles[playerID.toString()];
    }

    CreateBottleRadioElement(0, selectedBottle === 0);
    const bottleCount = Object.keys(bottles).length;
    Object.keys(bottles).forEach(function (bottleId, i) {
      const id = bottles[bottleId];
      CreateBottleRadioElement(bottles[bottleId], selectedBottle === undefined ? i === bottleCount - 1 : id === selectedBottle);
    });

    SelectBottle();
  });
}

function CreateBottleRadioElement (id, isChecked) {
  const radio = $.CreatePanel('RadioButton', $('#BottleSelection'), 'Bottle' + id);
  radio.BLoadLayoutSnippet('BottleRadio');
  radio.bottleId = id;
  radio.checked = isChecked;
}

function SelectBottle () {
  let bottleId = 0;
  const btn = $('#Bottle0');
  if (btn != null && btn.GetSelectedButton() !== null) {
    bottleId = btn.GetSelectedButton().bottleId;
  }
  const data = {
    BottleId: bottleId
  };
  $.Msg('Selecting Bottle #' + data.BottleId + ' for Player #' + Game.GetLocalPlayerID());
  GameEvents.SendCustomGameEventToServer('bottle_selected', data);
}

function PreviewHeroCM (name) {
  return PreviewHero(name);
}

function SelectHero (hero) {
  if (hero) {
    if (iscm) {
      selectedherocm = hero;
    } else {
      selectedhero = hero;
    }
  }
  if (!herolocked || (canReRandom && selectedhero === 'rerandom')) {
    let newhero = 'empty';
    if (iscm && selectedherocm !== 'empty') {
      newhero = selectedherocm;
    } else if (!iscm && selectedhero !== 'empty' && !IsHeroDisabled(selectedhero)) {
      herolocked = true;
      isPicking = false;
      newhero = selectedhero;
      FindDotaHudElement('HeroLockIn').style.brightness = 0.5;
      FindDotaHudElement('HeroRandom').style.brightness = 0.5;
    }

    if (iscm && !isCMLocking) {
      $.Msg('CM order ' + newhero);
      CaptainSelectHero();
    } else {
      $.Msg('Selecting ' + newhero);
      const playerId = Game.GetLocalPlayerID();
      const playerName = Players.GetPlayerName(playerId);
      const heroName = $.Localize('#' + newhero);
      GameEvents.SendCustomGameEventToServer('hero_selected', {
        hero: newhero,
        player_name: playerName,
        hero_name: heroName
      });
    }
  }
}

function BecomeCaptain () {
  GameEvents.SendCustomGameEventToServer('cm_become_captain', {
    test: '1'
  });
}

function CaptainSelectHero () {
  if (selectedherocm !== 'empty') {
    GameEvents.SendCustomGameEventToServer('cm_hero_selected', {
      hero: selectedherocm
    });
  }
}

function HideStrategy () {
  // var bossMarkers = ['Boss1r', 'Boss1d', 'Boss2r', 'Boss2d', 'Boss3r', 'Boss3d', 'Boss4r', 'Boss4d', 'Boss5r', 'Boss5d', 'Duel1', 'Duel2', 'Cave1r', 'Cave1d', 'Cave2r', 'Cave2d', 'Cave3r', 'Cave3d'];

  // bossMarkers.forEach(function (element) {
  //   FindDotaHudElement(element).style.transform = 'translateY(0)';
  //   FindDotaHudElement(element).style.opacity = '1';
  // });
  if (neverHideStrategy) {
    return;
  }

  FindDotaHudElement('MainContent').GetParent().style.opacity = '0';
  FindDotaHudElement('MainContent').GetParent().style.transform = 'scaleX(3) scaleY(3) translateY(25%)';
}

function GoToStrategy () {
  FindDotaHudElement('MainContent').style.transform = 'translateX(0) translateY(100%)';
  FindDotaHudElement('MainContent').style.opacity = '0';
  FindDotaHudElement('StrategyContent').style.transform = 'scaleX(1) scaleY(1)';
  FindDotaHudElement('StrategyContent').style.opacity = '1';
  // FindDotaHudElement('PregameBG').style.opacity = '0.15';
  FindDotaHudElement('PregameBG').RemoveClass('BluredAndDark');

  if (!hasGoneToStrategy) {
    hasGoneToStrategy = true;
    $.Schedule(6, function () {
      $('#ARDMLoading').style.opacity = 1;
    });
  }
}

function RandomHero () {
  selectedhero = 'random';
  selectedherocm = 'random';
  if (iscm) {
    CaptainSelectHero();
  } else {
    SelectHero();
  }
}

function RerandomHero () {
  $.Msg('Re-randoming');
  selectedhero = 'rerandom';
  selectedherocm = 'rerandom';
  if (iscm) {
    CaptainSelectHero();
  } else {
    SelectHero();
  }
}

function CreateHeroPanel (parent, hero) {
  const id = 'Scene' + ~~(Math.random() * 100);
  let scene = null;
  if (hero === 'npc_dota_hero_sohei') {
    scene = $.CreatePanelWithProperties('DOTAScenePanel', parent, id, {
      style: "opacity-mask: url('s2r://panorama/images/masks/softedge_box_png.vtex');",
      map: 'prefabs\\heroes\\sohei',
      particleonly: 'false',
      renderdeferred: 'false',
      camera: 'camera1',
      rotateonhover: 'true',
      yawmin: '-10',
      yawmax: '10',
      pitchmin: '-10',
      pitchmax: '10'
    });
  } else if (hero === 'npc_dota_hero_electrician') {
    scene = $.CreatePanelWithProperties('DOTAScenePanel', parent, id, {
      style: "opacity-mask: url('s2r://panorama/images/masks/softedge_box_png.vtex');",
      map: 'prefabs\\heroes\\electrician',
      particleonly: 'false',
      renderdeferred: 'false',
      camera: 'camera1',
      rotateonhover: 'true',
      yawmin: '-10',
      yawmax: '10',
      pitchmin: '-10',
      pitchmax: '10'
    });
  } else {
    scene = $.CreatePanelWithProperties('DOTAScenePanel', parent, id, {
      style: "opacity-mask: url('s2r://panorama/images/masks/softedge_box_png.vtex');",
      hittest: 'false',
      drawbackground: '0',
      renderdeferred: 'false',
      particleonly: 'false',
      unit: hero,
      rotateonhover: 'true',
      yawmin: '-10',
      yawmax: '10',
      pitchmin: '-10',
      pitchmax: '10'
    });
    $.DispatchEvent('DOTAGlobalSceneSetCameraEntity', id, 'camera_end_top', 1.0);
  }

  return scene;
}

function CreateAbilityPanel (parent, ability) {
  const id = 'Ability_' + ability;
  $.CreatePanelWithProperties('DOTAAbilityImage', parent, id, { abilityname: ability });
  const icon = $('#' + id);
  icon.SetPanelEvent('onmouseover', function () {
    $.DispatchEvent('DOTAShowAbilityTooltip', icon, ability);
  });
  icon.SetPanelEvent('onmouseout', function () {
    $.DispatchEvent('DOTAHideAbilityTooltip', icon);
  });
}

function SendMessageToTeam (event) {
  let playerName = event.player_name;
  if (playerName === undefined || playerName === '') {
    let playerId = event.picker_playerid;
    if (!playerId) {
      playerId = Game.GetLocalPlayerID();
    }
    playerName = Players.GetPlayerName(playerId);
  }
  const heroName = $.Localize('#' + event.hero);
  let message = playerName + ' got ' + heroName;
  const forced = event.forced === 1;
  if (forced) {
    const forcedToPick = event.forced_pick === 1;
    message = playerName + ' was forced to pick ' + heroName;
    if (!forcedToPick) {
      message = playerName + ' was forced to random ' + heroName;
    }
  } else {
    message = playerName + ' randomed ' + heroName;
  }

  Game.ServerCmd(`say ${message}`);
}
