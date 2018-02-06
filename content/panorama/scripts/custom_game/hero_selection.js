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

var currentMap = null;
var hasGoneToStrategy = false;
var selectedhero = 'empty';
var disabledheroes = [];
var herolocked = false;
var panelscreated = 0;
var iscm = false;
var selectedherocm = 'empty';
var isPicking = true;
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
  'Unboxing map'
];

CustomNetTables.SubscribeNetTableListener('hero_selection', onPlayerStatChange);
onPlayerStatChange(null, 'herolist', CustomNetTables.GetTableValue('hero_selection', 'herolist'));
onPlayerStatChange(null, 'APdata', CustomNetTables.GetTableValue('hero_selection', 'APdata'));
onPlayerStatChange(null, 'CMdata', CustomNetTables.GetTableValue('hero_selection', 'CMdata'));
onPlayerStatChange(null, 'time', CustomNetTables.GetTableValue('hero_selection', 'time'));
onPlayerStatChange(null, 'preview_table', CustomNetTables.GetTableValue('hero_selection', 'preview_table'));
ReloadCMStatus(CustomNetTables.GetTableValue('hero_selection', 'CMdata'));
UpdatePreviews(CustomNetTables.GetTableValue('hero_selection', 'preview_table'));
changeHilariousLoadingText();

$('#ARDMLoading').style.opacity = 0;

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
  if (key === 'herolist' && data != null) {
    currentMap = data.gametype;
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
    }
  } else if (key === 'time' && data != null) {
    // $.Msg(data);
    if (data.mode === 'STRATEGY') {
      FindDotaHudElement('TimeLeft').text = 'VS';
      FindDotaHudElement('GameMode').text = $.Localize(data['mode']);
      GoToStrategy();
    } else if (data['time'] > -1) {
      FindDotaHudElement('TimeLeft').text = data['time'];
      FindDotaHudElement('GameMode').text = $.Localize(data['mode']);
    } else {
      // CM Hides the chat on last pick before selecting plyer hero
      // ARDM don't have pick screen
      if (currentMap === 'oaa') {
        ReturnChatWindow();
      }
      HideStrategy();
    }
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
    vanillaChat.SetHasClass('ChatExpanded', false);
    vanillaChat.SetHasClass('Active', false);
  }
}

function UpdatePreviews (data) {
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
  if (data['order'][data['currentstage']].hero === 'empty') {
    currentPick = data['currentstage'];
  } else {
    currentPick = data['currentstage'] + 1;
  }
  var currentPickData = data['order'][currentPick];

  FindDotaHudElement('CMHeroPreview').RemoveAndDeleteChildren();
  Object.keys(data['order']).forEach(function (nkey) {
    var obj = data['order'][nkey];
    // FindDotaHudElement('CMStep' + nkey).heroname = obj.hero;
    if (obj.hero !== 'empty') {
      DisableHero(obj.hero);
    }

    // the "select your hero at the end" thing
    if (obj.side === teamID && obj.type === 'Pick' && obj.hero !== 'empty') {
      ReturnChatWindow();
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

function DisableHero (name) {
  if (FindDotaHudElement(name) != null) {
    FindDotaHudElement(name).AddClass('Disabled');
    disabledheroes.push(name);
  }
}

function IsHeroDisabled (name) {
  if (disabledheroes.indexOf(name) !== -1) {
    return true;
  }
  return false;
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
    }
    selectedhero = name;
    selectedherocm = name;

    lockButton.style.visibility = (!isPicking || IsHeroDisabled(currentHeroPreview)) ? 'collapse' : 'visible';
    $('#HeroRandom').style.visibility = !isPicking ? 'collapse' : 'visible';

    GameEvents.SendCustomGameEventToServer('preview_hero', {
      hero: name
    });
  }
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
      FindDotaHudElement('HeroLockIn').style.brightness = 0.5;
      FindDotaHudElement('HeroRandom').style.brightness = 0.5;
    } else if (!iscm && selectedhero !== 'empty' && !IsHeroDisabled(selectedhero)) {
      herolocked = true;
      isPicking = false;
      newhero = selectedhero;
      FindDotaHudElement('HeroLockIn').style.brightness = 0.5;
      FindDotaHudElement('HeroRandom').style.brightness = 0.5;
    }
    $.Msg('Selecting ' + newhero);
    GameEvents.SendCustomGameEventToServer('hero_selected', {
      PlayerID: Game.GetLocalPlayerID(),
      hero: newhero
    });
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
  var scene = parent.BCreateChildren('<DOTAScenePanel hittest="false" id="' + id + '" style="opacity-mask: url(\'s2r://panorama/images/masks/softedge_box_png.vtex\');" drawbackground="0" renderdeferred="false" particleonly="false" unit="' + hero + '" rotateonhover="true" yawmin="-10" yawmax="10" pitchmin="-10" pitchmax="10" />');
  $.DispatchEvent('DOTAGlobalSceneSetCameraEntity', id, 'camera_end_top', 1.0);

  return scene;
}
