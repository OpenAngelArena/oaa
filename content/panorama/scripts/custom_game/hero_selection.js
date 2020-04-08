/* global Players $ GameEvents CustomNetTables FindDotaHudElement Game */

if (typeof module !== 'undefined' && module.exports) {
  module.exports = {
    SelectHero: SelectHero,
    CaptainSelectHero: CaptainSelectHero,
    BecomeCaptain: BecomeCaptain,
    RandomHero: RandomHero,
    PreviewHeroCM: PreviewHeroCM
  };
}

// for testing
var neverHideStrategy = false;

var heroAbilities = {};
var currentMap = Game.GetMapInfo().map_display_name;
var hasGoneToStrategy = false;
var selectedhero = 'empty';
var disabledheroes = [];
var herolocked = false;
var panelscreated = 0;
var iscm = false;
var selectedherocm = 'empty';
var isPicking = true;
var isBanning = false;
var isCMLocking = false;
var canRandom = true;
var currentHeroPreview = '';
var stepsCompleted = {
  2: 0,
  3: 0
};
var lastPickIndex = 0;
var hilariousLoadingPhrases = [
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
  'Daydreaming about standalone',
  'Donating $1 to tournament prize pool',
  'Selling arcanas to afford custom bottle',
  'Finding a 5-stack on Discord',
  'Rigging the tournament',
  'Arbitrarily resetting everyone\'s MMR',
  'Adding another overpowered custom hero',
  'Actually doing nothing',
  'Prolonging loading screen for dramatic effect',
  'Begging for Oracle sets',
  'Crashing tournament finals',
  'Banning spectators on a hunch',
  'Nerfing Tinker more',
  'Replacing all heroes with Oracle',
  'Losing self in the music the moment I owned it',
  'Practicing invincible ledgedash',
  'Actually playing Auto Chess instead',
  'Remember to poop aggressively',
  'Sneaking loading screen text into the game simply because I can',
  'Forgetting to upgrade boots',
  'Hope everyone is having a great day',
  'Wards cannot be bought individually, instead the Ward Stack item is used to generate both observer and sentry wards passively',
  'Upgrade cores allow you to upgrade your items',
  'You can split an upgrade core into 2 of a lower tier',
  'Heroes are invulnerable for 2 seconds at the start of every duel',
  'Each capture point is worth more points than the previous',
  'Each hero on a capture point speeds up the capture time',
  'Use your glyph hotkey to drop a free ward',
  'Before -0:10 on the clock, you cannot leave base',
  'Bosses spawn into the map at 3:00',
  'The wandering boss spawns at 12:00'
];

init();

function init () {
  $.GetContextPanel().AddClass(currentMap);

  SetupTopBar();

  $('#MainContent').SetHasClass(currentMap, true);

  CustomNetTables.SubscribeNetTableListener('hero_selection', onPlayerStatChange);
  CustomNetTables.SubscribeNetTableListener('bottlepass', UpdateBottleList);

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
  changeHilariousLoadingText();
  UpdateBottleList();

  $('#ARDMLoading').style.opacity = 0;
}

function changeHilariousLoadingText () {
  var incredibleWit = hilariousLoadingPhrases[~~(Math.random() * hilariousLoadingPhrases.length)];

  noDots();
  $.Schedule(1, oneDots);
  $.Schedule(2, twoDots);
  $.Schedule(3, threeDots);
  $.Schedule(6, noDots);
  $.Schedule(7, oneDots);
  $.Schedule(8, twoDots);
  $.Schedule(9, threeDots);

  $.Schedule(12, changeHilariousLoadingText);

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
  var teamID = Players.GetTeam(Game.GetLocalPlayerID());
  var newimage = null;
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
    // do not move chat for ardm
    if (currentMap !== 'ardm') {
      MoveChatWindow();
    }
    var strengthholder = FindDotaHudElement('StrengthHeroes');
    var agilityholder = FindDotaHudElement('AgilityHeroes');
    var intelligenceholder = FindDotaHudElement('IntelligenceHeroes');
    Object.keys(data.herolist).sort().forEach(function (heroName) {
      var currentstat = null;

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
      var newhero = $.CreatePanel('RadioButton', currentstat, heroName);
      newhero.group = 'HeroChoises';
      newhero.SetPanelEvent('onactivate', function () { PreviewHero(heroName); });
      var newheroimage = $.CreatePanel('DOTAHeroImage', newhero, '');
      newheroimage.hittest = false;
      newheroimage.AddClass('HeroCard');
      newheroimage.heroname = heroName;
      var tempHeroName = newheroimage.heroname;
      if (tempHeroName === 'sohei' || tempHeroName === 'electrician') {
        newheroimage.style.backgroundImage = 'url("file://{images}/heroes/npc_dota_hero_' + tempHeroName + '.png")';
        newheroimage.style.backgroundSize = '100% 100%';
      }
    });
  } else if (key === 'preview_table' && data != null) {
    UpdatePreviews(data);
  } else if (key === 'APdata' && data != null) {
    var length = Object.keys(data).length;
    if (panelscreated !== length) {
      var teamdire = FindDotaHudElement('TeamDire');
      var teamradiant = FindDotaHudElement('TeamRadiant');
      panelscreated = length;
      teamdire.RemoveAndDeleteChildren();
      teamradiant.RemoveAndDeleteChildren();
      Object.keys(data).forEach(function (nkey) {
        var currentteam = null;
        switch (data[nkey].team) {
          case 2:
            currentteam = teamradiant;
            break;
          case 3:
            currentteam = teamdire;
            break;
        }
        var newelement = $.CreatePanel('Panel', currentteam, '');
        newelement.AddClass('Player');
        newimage = $.CreatePanel('DOTAHeroImage', newelement, data[nkey].steamid);
        newimage.hittest = false;
        newimage.AddClass('PlayerImage');
        newimage.heroname = data[nkey].selectedhero;
        var newlabel = $.CreatePanel('DOTAUserName', newelement, '');
        newlabel.AddClass('PlayerLabel');
        newlabel.steamid = data[nkey].steamid;

        DisableHero(data[nkey].selectedhero);
        if (iscm) {
          if (data[nkey].selectedhero !== 'empty') {
            FindDotaHudElement('CMStep' + nkey).heroname = data[nkey].selectedhero;
            var label = FindDotaHudElement('CMHeroPickLabel_' + data[nkey].selectedhero);

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
      if (iscm) {
        var cmData = CustomNetTables.GetTableValue('hero_selection', 'CMdata');
        Object.keys(cmData['order']).forEach(function (nkey) {
          var obj = cmData['order'][nkey];
          FindDotaHudElement('CMStep' + nkey).heroname = obj.hero;
          FindDotaHudElement('CMStep' + nkey).RemoveClass('active');
          if (obj.side === teamID && obj.type === 'Pick' && obj.hero !== 'empty') {
            var label = FindDotaHudElement('CMHeroPickLabel_' + obj.hero);

            label.style.visibility = 'collapse';
            label.steamid = null;
          }
        });
      }
      Object.keys(data).forEach(function (nkey) {
        var currentplayer = FindDotaHudElement(data[nkey].steamid);
        currentplayer.heroname = data[nkey].selectedhero;
        currentplayer.RemoveClass('PreviewHero');

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
  } else if (key === 'CMdata' && data != null) {
    iscm = true;
    var teamName = teamID === 2 ? 'radiant' : 'dire';
    if (data['captain' + teamName] === 'empty') {
      isPicking = false;
      // "BECOME CAPTAIN" button
      FindDotaHudElement('CMPanel').style.visibility = 'visible';
      FindDotaHudElement('CMHeroPreview').style.visibility = 'collapse';
      // FindDotaHudElement('HeroPreview').style.visibility = 'collapse';
      FindDotaHudElement('HeroLockIn').style.visibility = 'collapse';
      FindDotaHudElement('HeroRandom').style.visibility = 'collapse';
      FindDotaHudElement('BecomeCaptain').style.visibility = 'visible';
      return;
    } else {
      FindDotaHudElement('CMPanel').style.visibility = 'visible';
      FindDotaHudElement('CMProgress').style.visibility = 'visible';
      FindDotaHudElement('CMHeroPreview').style.visibility = 'collapse';
      FindDotaHudElement('HeroLockIn').style.visibility = 'collapse';
      FindDotaHudElement('HeroRandom').style.visibility = 'collapse';
      FindDotaHudElement('BecomeCaptain').style.visibility = 'collapse';
    }
    FindDotaHudElement('RadiantReserve').text = data['reserveradiant'];
    FindDotaHudElement('DireReserve').text = data['reservedire'];

    if (data['currentstage'] < data['totalstages'] || (data['order'][data['currentstage']] && data['order'][data['currentstage']].hero === 'empty')) {
      if (!data['order'][data['currentstage']]) {
        return;
      }
      FindDotaHudElement('CMPanel').style.visibility = 'visible';
      FindDotaHudElement('CMHeroPreview').style.visibility = 'collapse';
      FindDotaHudElement('HeroLockIn').style.visibility = 'collapse';
      FindDotaHudElement('HeroRandom').style.visibility = 'collapse';
      FindDotaHudElement('BecomeCaptain').style.visibility = 'collapse';
      var currentPick = null;
      var currentPickIndex = 0;
      if (data['order'][data['currentstage']].hero === 'empty') {
        currentPickIndex = data['currentstage'];
        currentPick = data['order'][currentPickIndex];
      } else {
        currentPickIndex = data['currentstage'] + 1;
        currentPick = data['order'][currentPickIndex];
      }
      if (currentPickIndex > lastPickIndex) {
        stepsCompleted[currentPick.side]++;
        lastPickIndex = currentPickIndex;
      }
      $.Msg(currentPick);
      $.Msg(stepsCompleted);

      FindDotaHudElement('CMRadiantProgress').style.width = ~~(stepsCompleted[2] / (data['totalstages'] / 2) * 100) + '%';
      FindDotaHudElement('CMDireProgress').style.width = ~~(stepsCompleted[3] / (data['totalstages'] / 2) * 100) + '%';
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

      if (data['order'][data['currentstage']] && data['order'][data['currentstage']].hero && data['order'][data['currentstage']].hero !== 'empty') {
        FindDotaHudElement('CMStep' + data['currentstage']).heroname = data['order'][data['currentstage']].hero;
        FindDotaHudElement('CMStep' + data['currentstage']).RemoveClass('active');
        DisableHero(data['order'][data['currentstage']].hero);
      }
      $.Msg(data['currentstage'] + ', ' + currentPick.side);
      if (Game.GetLocalPlayerID() === data['captain' + teamName] && teamID === currentPick.side) {
        // FindDotaHudElement('CaptainLockIn').style.visibility = 'visible';
        isPicking = true;
        isBanning = currentPick.type === 'Ban';
        PreviewHero();
      } else {
        isPicking = false;
        PreviewHero();
      }
    } else if (data['currentstage'] === data['totalstages']) {
      FindDotaHudElement('CMStep' + data['currentstage']).heroname = data['order'][data['currentstage']].hero;
      DisableHero(data['order'][data['currentstage']].hero);
      FindDotaHudElement('CMPanel').style.visibility = 'visible';
      FindDotaHudElement('HeroLockIn').style.visibility = 'collapse';
      FindDotaHudElement('HeroRandom').style.visibility = 'collapse';
      FindDotaHudElement('HeroPreview').style.visibility = 'collapse';
      FindDotaHudElement('BecomeCaptain').style.visibility = 'collapse';
      FindDotaHudElement('CaptainLockIn').style.visibility = 'collapse';
      DisableHero(data['order'][data['currentstage']].hero);

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
      // CM Hides the chat on last pick, before selecting plyer hero
      // ARDM don't have pick screen chat
      if (currentMap !== 'ardm' && currentMap !== 'captains_mode') {
        ReturnChatWindow();
      }
      HideStrategy();
    }
  }
}

function UpdatedRankedPickState (data) {
  $.Msg(data);

  var bans = Object.keys(data.bans)
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
  var teamID = Players.GetTeam(Game.GetLocalPlayerID());
  var order = data.order[data.currentOrder + ''];

  switch (data.phase) {
    case 'start':
      isPicking = false;
      break;
    case 'bans':
      $.Msg(data.banChoices[Game.GetLocalPlayerID()]);
      isPicking = !data.banChoices[Game.GetLocalPlayerID()];
      herolocked = false;
      canRandom = false;
      isBanning = true;

      break;
    case 'picking':
      isBanning = false;
      if (order.team === teamID) {
        var apData = CustomNetTables.GetTableValue('hero_selection', 'APdata');
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
      break;
  }
  UpdateButtons();
}

function UpdateButtons () {
  if (IsHeroDisabled(selectedhero)) {
    FindDotaHudElement('HeroLockIn').style.visibility = 'collapse';
    FindDotaHudElement('HeroBan').style.visibility = 'collapse';
    FindDotaHudElement('HeroRandom').style.visibility = 'collapse';
    return;
  }
  FindDotaHudElement('HeroLockIn').style.visibility = isPicking && !isBanning ? 'visible' : 'collapse';
  FindDotaHudElement('HeroBan').style.visibility = isPicking && isBanning ? 'visible' : 'collapse';
  FindDotaHudElement('HeroRandom').style.visibility = isPicking && canRandom ? 'visible' : 'collapse';
}

function SetupTopBar () {
  if (currentMap !== '10v10') {
    return;
  }

  $.GetContextPanel().SetHasClass('TenVTen', true);
  var topbar = FindDotaHudElement('topbar');
  topbar.style.width = '1550px';

  // Top Bar Radiant
  var TopBarRadiantTeam = FindDotaHudElement('TopBarRadiantTeam');
  TopBarRadiantTeam.style.width = '690px';

  var topbarRadiantPlayers = FindDotaHudElement('TopBarRadiantPlayers');
  topbarRadiantPlayers.style.width = '690px';

  var topbarRadiantPlayersContainer = FindDotaHudElement('TopBarRadiantPlayersContainer');
  topbarRadiantPlayersContainer.style.width = '630px';
  FillTopBarPlayer(topbarRadiantPlayersContainer);

  var RadiantTeamContainer = FindDotaHudElement('RadiantTeamContainer');
  RadiantTeamContainer.style.height = '737px';

  // Top Bar Dire
  var TopBarDireTeam = FindDotaHudElement('TopBarDireTeam');
  TopBarDireTeam.style.width = '690px';

  var topbarDirePlayers = FindDotaHudElement('TopBarDirePlayers');
  topbarDirePlayers.style.width = '690px';

  var topbarDirePlayersContainer = FindDotaHudElement('TopBarDirePlayersContainer');
  topbarDirePlayersContainer.style.width = '630px';
  FillTopBarPlayer(topbarDirePlayersContainer);

  var DireTeamContainer = FindDotaHudElement('DireTeamContainer');
  DireTeamContainer.style.height = '737px';
}

function FillTopBarPlayer (TeamContainer) {
  // Fill players top bar in case on partial lobbies
  var playerCount = TeamContainer.GetChildCount();
  for (var i = playerCount + 1; i <= 10; i++) {
    var newPlayer = $.CreatePanel('DOTATopBarPlayer', TeamContainer, 'RadiantPlayer-1');
    if (newPlayer) {
      newPlayer.FindChildTraverse('PlayerColor').style.backgroundColor = '#FFFFFFFF';
    }
    newPlayer.SetHasClass('EnemyTeam', true);
  }
}

function MoveChatWindow () {
  var vanillaChat = FindDotaHudElement('HudChat');
  vanillaChat.SetHasClass('ChatExpanded', true);
  vanillaChat.SetHasClass('Active', true);
  vanillaChat.style.y = '0px';
  vanillaChat.hittest = true;
  vanillaChat.SetParent(FindDotaHudElement('ChatPlaceholder'));
}

function ReturnChatWindow () {
  var vanillaChat = FindDotaHudElement('HudChat');
  var vanillaChatParent = FindDotaHudElement('HUDElements');

  if (vanillaChat.GetParent() !== vanillaChatParent) {
    // Remove focus before change parent
    vanillaChatParent.SetFocus();
    vanillaChat.SetParent(vanillaChatParent);
    vanillaChat.style.y = '-240px';
    vanillaChat.hittest = false;
    vanillaChat.style.visibility = 'visible';
    vanillaChat.SetHasClass('ChatExpanded', false);
    vanillaChat.SetHasClass('Active', false);
  }
}

function UpdatePreviews (data) {
  if (!data) {
    data = CustomNetTables.GetTableValue('hero_selection', 'preview_table');
  }
  if (!data) {
    return;
  }
  var apData = CustomNetTables.GetTableValue('hero_selection', 'APdata');
  var heroesBySteamid = {};
  Object.keys(apData).forEach(function (playerId) {
    if (apData[playerId].selectedhero && apData[playerId].selectedhero !== 'empty' && apData[playerId].selectedhero !== 'random') {
      heroesBySteamid[apData[playerId].steamid] = apData[playerId].selectedhero;
    }
  });
  var teamID = Players.GetTeam(Game.GetLocalPlayerID());
  Object.keys(data[teamID] || {}).forEach(function (steamid) {
    if (heroesBySteamid[steamid]) {
      return;
    }
    var player = FindDotaHudElement(steamid);
    if (player) {
      player.heroname = data[teamID][steamid];
      player.AddClass('PreviewHero');
    }
  });
  Object.keys(heroesBySteamid).forEach(function (steamid) {
    var player = FindDotaHudElement(steamid);
    player.heroname = heroesBySteamid[steamid];
  });
}

function ReloadCMStatus (data) {
  if (!data) {
    return;
  }
  // reset all data for people, who lost it
  var teamID = Players.GetTeam(Game.GetLocalPlayerID());
  stepsCompleted = {
    2: 0,
    3: 0
  };

  var currentPick = null;
  if (!data['order'][data['currentstage']]) {
    return;
  }
  if (data['order'][data['currentstage']].hero === 'empty') {
    currentPick = data['currentstage'];
  } else {
    currentPick = data['currentstage'] + 1;
  }
  var currentPickData = data['order'][currentPick];

  if (data['currentstage'] === data['totalstages']) {
    ReturnChatWindow();
    FindDotaHudElement('CMHeroPreview').RemoveAndDeleteChildren();
    Object.keys(data['order']).forEach(function (nkey) {
      var obj = data['order'][nkey];
      // FindDotaHudElement('CMStep' + nkey).heroname = obj.hero;
      if (obj.hero !== 'empty') {
        DisableHero(obj.hero);
      }

      // the "select your hero at the end" thing
      if (obj.side === teamID && obj.type === 'Pick' && obj.hero !== 'empty') {
        $('#MainContent').SetHasClass('CMHeroChoices', true);

        var newbutton = $.CreatePanel('RadioButton', FindDotaHudElement('CMHeroPreview'), '');
        newbutton.group = 'CMHeroChoises';
        newbutton.AddClass('CMHeroPreviewItem');
        newbutton.SetPanelEvent('onactivate', function () { SelectHero(obj.hero); });
        newbutton.BCreateChildren('<Label class="HeroPickLabel" text="#' + obj.hero + '" />');

        CreateHeroPanel(newbutton, obj.hero);
        var newlabel = $.CreatePanel('DOTAUserName', newbutton, 'CMHeroPickLabel_' + obj.hero);
        newlabel.style.visibility = 'collapse';
        newlabel.steamid = null;
      }

      // the CM picking order phase thingy
      if (obj.hero && obj.hero !== 'empty') {
        FindDotaHudElement('CMStep' + nkey).heroname = obj.hero;
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
  FindDotaHudElement('CMRadiantProgress').style.width = ~~(stepsCompleted[2] / (data['totalstages'] / 2) * 100) + '%';
  FindDotaHudElement('CMDireProgress').style.width = ~~(stepsCompleted[3] / (data['totalstages'] / 2) * 100) + '%';
  if (currentPick < data['totalstages']) {
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
    disabledheroes.splice(disabledheroes.indexOf(name), 1);
  }
}

function DisableHero (name) {
  if (FindDotaHudElement(name) != null) {
    FindDotaHudElement(name).AddClass('Disabled');
    disabledheroes.push(name);
  }
}

function IsHeroDisabled (name) {
  // if it's not -1 it's in the disabled list
  return disabledheroes.indexOf(name) !== -1;
}

function PreviewHero (name) {
  var lockButton = null;
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
    var preview = FindDotaHudElement('HeroPreview');
    if (name !== 'random' && currentHeroPreview !== name) {
      currentHeroPreview = name;
      preview.RemoveAndDeleteChildren();
      CreateHeroPanel(preview, name);
      $('#SectionTitle').text = $.Localize('#' + name, $('#SectionTitle'));

      var abilityPreview = $('#AbilityPreview');
      abilityPreview.RemoveAndDeleteChildren();
      Object.keys(heroAbilities[name]).forEach(function (i) {
        var ability = heroAbilities[name][i];
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
  var playerID = Game.GetLocalPlayerID();
  $('#ArcanaSelection').RemoveAndDeleteChildren();

  if (heroName !== 'npc_dota_hero_sohei' && heroName !== 'npc_dota_hero_electrician') {
    $('#ArcanaPanel').SetHasClass('HasArcana', false);
    return;
  }
  $('#ArcanaPanel').SetHasClass('HasArcana', true);

  var selectedArcanas = CustomNetTables.GetTableValue('bottlepass', 'selected_arcanas');
  var selectedArcana = 'DefaultSet';

  if (selectedArcanas !== undefined && selectedArcanas[playerID.toString()] !== undefined) {
    selectedArcana = selectedArcanas[playerID.toString()][heroName];
  }

  $.Schedule(0.2, function () {
    $.Msg('UpdateBottlePassArcana(' + heroName + ')');
    var arcanas = null;

    var specialArcanas = CustomNetTables.GetTableValue('bottlepass', 'special_arcanas');
    for (var arcanaIndex in specialArcanas) {
      if (specialArcanas[arcanaIndex].PlayerId === playerID) {
        arcanas = specialArcanas[arcanaIndex].Arcanas;
      }
    }
    var radio = null;
    if (heroName === 'npc_dota_hero_sohei') {
      radio = $.CreatePanel('RadioButton', $('#ArcanaSelection'), 'DefaultSoheiSet');
      radio.BLoadLayoutSnippet('ArcanaRadio');
      radio.hero = heroName;
      radio.setName = 'DefaultSet';
      radio.checked = selectedArcana === radio.setName;

      for (var index in arcanas) {
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

      for (var index2 in arcanas) {
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
  var arcanasList = $('#ArcanaSelection');
  if (arcanasList.GetChildCount() > 0) {
    var selectedArcana = $('#ArcanaSelection').Children()[0].GetSelectedButton();

    var id = 'Scene' + ~~(Math.random() * 100);
    var preview = FindDotaHudElement('HeroPreview');
    preview.RemoveAndDeleteChildren();
    if (selectedArcana.setName !== 'DefaultSet') {
      preview.BCreateChildren('<DOTAScenePanel particleonly="false" id="' + id + '" style="opacity-mask: url(\'s2r://panorama/images/masks/softedge_box_png.vtex\');" map="prefabs\\heroes\\' + selectedArcana.setName + '"  renderdeferred="false"  camera="camera1" rotateonhover="true" yawmin="-10" yawmax="10" pitchmin="-10" pitchmax="10"/>');
    } else {
      if (selectedArcana.hero === 'npc_dota_hero_sohei') {
        preview.BCreateChildren('<DOTAScenePanel particleonly="false" id="' + id + '" style="opacity-mask: url(\'s2r://panorama/images/masks/softedge_box_png.vtex\');" map="prefabs\\heroes\\sohei" renderdeferred="false"  camera="camera1" rotateonhover="true" yawmin="-10" yawmax="10" pitchmin="-10" pitchmax="10"/>');
      } else if (selectedArcana.hero === 'npc_dota_hero_electrician') {
        preview.BCreateChildren('<DOTAScenePanel particleonly="false" id="' + id + '" style="opacity-mask: url(\'s2r://panorama/images/masks/softedge_box_png.vtex\');" map="prefabs\\heroes\\electrician" renderdeferred="false"  camera="camera1" rotateonhover="true" yawmin="-10" yawmax="10" pitchmin="-10" pitchmax="10"/>');
      }
    }

    var data = {
      Hero: selectedArcana.hero,
      Arcana: selectedArcana.setName
    };

    $.Msg('Selecting Arcana ' + data.Arcana + ' for Player #' + Game.GetLocalPlayerID() + ' for hero ' + data.Hero);
    GameEvents.SendCustomGameEventToServer('arcana_selected', data);
  }
}

function UpdateBottleList () {
  var playerID = Game.GetLocalPlayerID();
  var specialBottles = CustomNetTables.GetTableValue('bottlepass', 'special_bottles');
  if (!specialBottles) {
    $.Schedule(0.2, UpdateBottleList);
    return;
  }
  var bottles = specialBottles[playerID.toString()] ? specialBottles[playerID.toString()].Bottles : {};

  if ($('#BottleSelection').GetChildCount() === Object.keys(bottles).length + 1) {
    // ignore repaint if radio is already filled
    return;
  }

  $('#BottleSelection').RemoveAndDeleteChildren();
  // Wait the parent be updated
  $.Schedule(0.2, function () {
    var selectedBottle;

    var selectedBottles = CustomNetTables.GetTableValue('bottlepass', 'selected_bottles');
    if (selectedBottles !== undefined && selectedBottles[playerID.toString()] !== undefined) {
      selectedBottle = selectedBottles[playerID.toString()];
    }

    CreateBottleRadioElement(0, selectedBottle === 0);
    var bottleCount = Object.keys(bottles).length;
    Object.keys(bottles).forEach(function (bottleId, i) {
      var id = bottles[bottleId];
      CreateBottleRadioElement(bottles[bottleId], selectedBottle === undefined ? i === bottleCount - 1 : id === selectedBottle);
    });

    SelectBottle();
  });
}

function CreateBottleRadioElement (id, isChecked) {
  var radio = $.CreatePanel('RadioButton', $('#BottleSelection'), 'Bottle' + id);
  radio.BLoadLayoutSnippet('BottleRadio');
  radio.bottleId = id;
  radio.checked = isChecked;
}

function SelectBottle () {
  var bottleId = 0;
  var btn = $('#Bottle0');
  if (btn != null) {
    bottleId = $('#Bottle0').GetSelectedButton().bottleId;
  }
  var data = {
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
  if (!herolocked) {
    var newhero = 'empty';
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
      GameEvents.SendCustomGameEventToServer('hero_selected', {
        hero: newhero
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

function CreateHeroPanel (parent, hero) {
  var id = 'Scene' + ~~(Math.random() * 100);
  var scene = null;
  if (hero === 'npc_dota_hero_sohei') {
    scene = parent.BCreateChildren('<DOTAScenePanel particleonly="false" id="' + id + '" style="opacity-mask: url(\'s2r://panorama/images/masks/softedge_box_png.vtex\');" map="prefabs\\heroes\\sohei" renderdeferred="false"  camera="camera1" rotateonhover="true" yawmin="-10" yawmax="10" pitchmin="-10" pitchmax="10"/>');
  } else if (hero === 'npc_dota_hero_electrician') {
    scene = parent.BCreateChildren('<DOTAScenePanel particleonly="false" id="' + id + '" style="opacity-mask: url(\'s2r://panorama/images/masks/softedge_box_png.vtex\');" map="prefabs\\heroes\\electrician" renderdeferred="false"  camera="camera1" rotateonhover="true" yawmin="-10" yawmax="10" pitchmin="-10" pitchmax="10"/>');
  } else {
    scene = parent.BCreateChildren('<DOTAScenePanel hittest="false" id="' + id + '" style="opacity-mask: url(\'s2r://panorama/images/masks/softedge_box_png.vtex\');" drawbackground="0" renderdeferred="false" particleonly="false" unit="' + hero + '" rotateonhover="true" yawmin="-10" yawmax="10" pitchmin="-10" pitchmax="10" />');
    $.DispatchEvent('DOTAGlobalSceneSetCameraEntity', id, 'camera_end_top', 1.0);
  }

  return scene;
}

function CreateAbilityPanel (parent, ability) {
  var id = 'Ability_' + ability;
  parent.BCreateChildren('<DOTAAbilityImage abilityname="' + ability + '" id="' + id + '" />');
  var icon = $('#' + id);
  icon.SetPanelEvent('onmouseover', function () {
    $.DispatchEvent('DOTAShowAbilityTooltip', icon, ability);
  });
  icon.SetPanelEvent('onmouseout', function () {
    $.DispatchEvent('DOTAHideAbilityTooltip', icon);
  });
}
