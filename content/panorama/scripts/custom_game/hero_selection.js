/* global Players $ GameEvents CustomNetTables FindDotaHudElement Game */

if (typeof module !== 'undefined' && module.exports) {
  module.exports = {
    SelectHero: SelectHero,
    CaptainSelectHero: CaptainSelectHero,
    BecomeCaptain: BecomeCaptain,
    RandomHero: RandomHero
  };
}

var selectedhero = 'empty';
var disabledheroes = [];
var herolocked = false;
var panelscreated = 0;
var iscm = false;
var selectedherocm = 'empty';
var isfirstpick = 0;
var isPicking = true;
CustomNetTables.SubscribeNetTableListener('hero_selection', onPlayerStatChange);
onPlayerStatChange(null, 'herolist', CustomNetTables.GetTableValue('hero_selection', 'herolist'));
onPlayerStatChange(null, 'APdata', CustomNetTables.GetTableValue('hero_selection', 'APdata'));
onPlayerStatChange(null, 'CMdata', CustomNetTables.GetTableValue('hero_selection', 'CMdata'));
onPlayerStatChange(null, 'time', CustomNetTables.GetTableValue('hero_selection', 'time'));
onPlayerStatChange(null, 'preview_table', CustomNetTables.GetTableValue('hero_selection', 'preview_table'));
ReloadCMStatus(CustomNetTables.GetTableValue('hero_selection', 'CMdata'));
UpdatePreviews(CustomNetTables.GetTableValue('hero_selection', 'preview_table'));

function onPlayerStatChange (table, key, data) {
  // travis asked me, i didnt want to!
  var nkey = null;
  var newimage = null;
  if (key === 'herolist' && data != null) {
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
      newhero.SetPanelEvent('onactivate', (function () { PreviewHero(heroName); }));
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
      Object.keys(data).forEach(function(nkey) {
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
        var teamID = Players.GetTeam(Game.GetLocalPlayerID());
        var cmData = CustomNetTables.GetTableValue('hero_selection', 'CMdata');
        Object.keys(cmData['order']).forEach(function (nkey) {
          var obj = cmData['order'][nkey];
          FindDotaHudElement('CMStep' + nkey).heroname = obj.hero;
          if (obj.side === teamID && obj.type === 'Pick' && obj.hero !== 'empty') {
            var label = FindDotaHudElement('CMHeroPickLabel_' + obj.hero);

            label.style.visibility = 'collapse';
            label.steamid = null;
          }
        });
      }
      Object.keys(data).forEach(function(nkey) {
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
    var teamID = Players.GetTeam(Game.GetLocalPlayerID());
    var teamName = teamID === 2 ? 'radiant' : 'dire';
    if (data['captain' + teamName] === 'empty') {
      // "BECOME CAPTAIN" button
      FindDotaHudElement('CMPanel').style.visibility = 'visible';
      FindDotaHudElement('CMHeroPreview').style.visibility = 'collapse';
      // FindDotaHudElement('HeroPreview').style.visibility = 'collapse';
      FindDotaHudElement('HeroLockIn').style.visibility = 'collapse';
      FindDotaHudElement('HeroRandom').style.visibility = 'collapse';
      FindDotaHudElement('BecomeCaptain').style.visibility = 'visible';
    } else {
      FindDotaHudElement('CMPanel').style.visibility = 'visible';
      FindDotaHudElement('CMProgress').style.visibility = 'visible';
      FindDotaHudElement('CMHeroPreview').style.visibility = 'collapse';
      FindDotaHudElement('HeroLockIn').style.visibility = 'collapse';
      FindDotaHudElement('HeroRandom').style.visibility = 'collapse';
      FindDotaHudElement('BecomeCaptain').style.visibility = 'collapse';
    }

    if (data['currentstage'] === 0) {
      isfirstpick = 1;
    } else if (data['currentstage'] < data['totalstages']) {
      $.Msg('Current phase is mid-pick.. keeping going!')
      FindDotaHudElement('CMPanel').style.visibility = 'visible';
      FindDotaHudElement('CMHeroPreview').style.visibility = 'collapse';
      FindDotaHudElement('HeroLockIn').style.visibility = 'collapse';
      FindDotaHudElement('HeroRandom').style.visibility = 'collapse';
      FindDotaHudElement('BecomeCaptain').style.visibility = 'collapse';
      var currentPickType = data['order'][data['currentstage'] + 1].type;

      FindDotaHudElement('CaptainLockIn').RemoveClass('PickHero');
      FindDotaHudElement('CaptainLockIn').RemoveClass('BanHero');
      FindDotaHudElement('CaptainLockIn').AddClass(currentPickType + 'Hero');

      if (isfirstpick === 1) {
        data['currentstage'] = 0;
        isfirstpick = 2;
      } else if (isfirstpick === 0) {
        ReloadCMStatus(data);
      } else {
        FindDotaHudElement('CMStep' + data['currentstage']).heroname = data['order'][data['currentstage']].hero;
        DisableHero(data['order'][data['currentstage']].hero);
      }
      if (Game.GetLocalPlayerID() === data['captain' + teamName] && teamID === data['order'][data['currentstage'] + 1].side) {
        // FindDotaHudElement('CaptainLockIn').style.visibility = 'visible';
        isPicking = true;
        PreviewHero();
      } else {
        isPicking = false;
        FindDotaHudElement('CaptainLockIn').style.visibility = 'collapse';
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
      FindDotaHudElement('CMHeroPreview').style.visibility = 'visible';
    }
  } else if (key === 'time' && data != null) {
    if (data['time'] > -1) {
      FindDotaHudElement('TimeLeft').text = data['time'];
      FindDotaHudElement('GameMode').text = data['mode'];
    } else {
      FindDotaHudElement('TimeLeft').text = 'VS';
      FindDotaHudElement('GameMode').text = data['mode'];
      GoToStrategy();
    }
  }
}


function UpdatePreviews (data) {
  if (!data) {
    return;
  }
  var teamID = Players.GetTeam(Game.GetLocalPlayerID());
  Object.keys(data[teamID] || {}).forEach(function (steamid) {
    var player = FindDotaHudElement(steamid);
    if (player) {
      player.heroname = data[teamID][steamid];
      player.AddClass('PreviewHero');
    }
  });
}

function ReloadCMStatus (data) {
  if (!data) {
    return;
  }
  // reset all data for people, who lost it
  var teamID = Players.GetTeam(Game.GetLocalPlayerID());
  FindDotaHudElement('CMHeroPreview').RemoveAndDeleteChildren();
  Object.keys(data['order']).forEach(function (nkey) {
    var obj = data['order'][nkey];
    // FindDotaHudElement('CMStep' + nkey).heroname = obj.hero;
    if (obj.hero !== 'empty') {
      DisableHero(obj.hero);
    }

    // the "select your hero at the end" thing
    if (obj.side === teamID && obj.type === 'Pick' && obj.hero !== 'empty') {
      var newbutton = $.CreatePanel('RadioButton', FindDotaHudElement('CMHeroPreview'), '');
      newbutton.group = 'CMHeroChoises';
      newbutton.AddClass('CMHeroPreviewItem');
      newbutton.SetPanelEvent('onactivate', (function () { SelectHero(obj.hero); }));
      newbutton.BCreateChildren('<Label class="HeroPickLabel" text="#' + obj.hero + '" />');

      var newimage = newbutton.BCreateChildren("<DOTAScenePanel unit='" + obj.hero + "'/>");
      var newlabel = $.CreatePanel('DOTAUserName', newbutton, 'CMHeroPickLabel_' + obj.hero);
      newlabel.style.visibility = 'collapse';
      newlabel.steamid = null;
    }

    // the CM picking order phase thingy
    if (obj.hero && obj.hero !== 'empty') {
      FindDotaHudElement('CMStep' + nkey).heroname = obj.hero;
    }
  });
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
    preview.RemoveAndDeleteChildren();
    preview.BCreateChildren("<DOTAScenePanel unit='" + name + "'/>");
    selectedhero = name;
    selectedherocm = name;

    lockButton.style.visibility = (!isPicking || IsHeroDisabled(name)) ? 'collapse' : 'visible';
    $('#SectionTitle').text = $.Localize('#' + name, $('#SectionTitle'));

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

function GoToStrategy () {
  FindDotaHudElement('MainContent').style.transform = 'translateX(0) translateY(100%)';
  FindDotaHudElement('MainContent').style.opacity = '0';
  FindDotaHudElement('StrategyContent').style.transform = 'scaleX(1) scaleY(1)';
  FindDotaHudElement('StrategyContent').style.opacity = '1';
  // FindDotaHudElement('PregameBG').style.opacity = '0.15';
  FindDotaHudElement('PregameBG').RemoveClass('BluredAndDark');

  // var bossMarkers = ['Boss1r', 'Boss1d', 'Boss2r', 'Boss2d', 'Boss3r', 'Boss3d', 'Boss4r', 'Boss4d', 'Boss5r', 'Boss5d', 'Duel1', 'Duel2', 'Cave1r', 'Cave1d', 'Cave2r', 'Cave2d', 'Cave3r', 'Cave3d'];

  // bossMarkers.forEach(function (element) {
  //   FindDotaHudElement(element).style.transform = 'translateY(0)';
  //   FindDotaHudElement(element).style.opacity = '1';
  // });

  FindDotaHudElement('MainContent').GetParent().style.opacity = '0';
  FindDotaHudElement('MainContent').GetParent().style.transform = 'scaleX(3) scaleY(3) translateY(25%)';
}

function RandomHero () {
  selectedhero = 'random';
  SelectHero();
}
