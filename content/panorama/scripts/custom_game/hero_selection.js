/* global Players $ GameEvents CustomNetTables FindDotaHudElement */

if (typeof module !== 'undefined' && module.exports) {
  module.exports = SelectHero;
}

var console = {
  log: $.Msg.bind($)
};

(function () {
  onPlayerStatChange(null, 'herolist', CustomNetTables.GetTableValue('hero_selection', 'herolist'));
  onPlayerStatChange(null, 'APdata', CustomNetTables.GetTableValue('hero_selection', 'APdata'));
  onPlayerStatChange(null, 'CMdata', CustomNetTables.GetTableValue('hero_selection', 'CMdata'));
  onPlayerStatChange(null, 'time', CustomNetTables.GetTableValue('hero_selection', 'time'));
  CustomNetTables.SubscribeNetTableListener('hero_selection', onPlayerStatChange);
}());

var selectedhero = 'empty';
var herolocked = false;
var panelscreated = 0;
var cmsetup = 0;

function onPlayerStatChange (table, key, data) {
  if (key === 'herolist' && data != null) {
    var strengthholder = FindDotaHudElement('StrengthHeroes');
    var agilityholder = FindDotaHudElement('AgilityHeroes');
    var intelligenceholder = FindDotaHudElement('IntelligenceHeroes');
    for (key in data.herolist) {
      var currentstat = null;
      switch (data.herolist[key]) {
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
      var newhero = $.CreatePanel('RadioButton', currentstat, key);
      newhero.group = 'HeroChoises';
      newhero.SetPanelEvent('onactivate', (function (newkey) { return function () { PreviewHero(newkey); }; }(key)));
      var newheroimage = $.CreatePanel('DOTAHeroImage', newhero, '');
      newheroimage.hittest = false;
      newheroimage.AddClass('HeroCard');
      newheroimage.heroname = key;
    }
  } else if (key === 'APdata' && data != null) {
    var length = Object.keys(data).length;
    if (panelscreated !== length) {
      var teamdire = FindDotaHudElement('TeamDire');
      var teamradiant = FindDotaHudElement('TeamRadiant');
      panelscreated = length;
      teamdire.RemoveAndDeleteChildren();
      teamradiant.RemoveAndDeleteChildren();
      for (var nkey in data) {
        if (data.hasOwnProperty(nkey)) {
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
          var newimage = $.CreatePanel('DOTAHeroImage', newelement, data[nkey].steamid);
          newimage.hittest = false;
          newimage.AddClass('PlayerImage');
          newimage.heroname = data[nkey].selectedhero;
          var newlabel = $.CreatePanel('DOTAUserName', newelement, '');
          newlabel.AddClass('PlayerLabel');
          // I DO NOT KNOW WHY, BUT IT MESSES ID UP SOMEHOW BY +-3 WTF???
          newlabel.steamid = data[nkey].steamid;
        }
      }
    } else {
      for (var ind in data) {
        if (data.hasOwnProperty(ind)) {
          var currentplayer = FindDotaHudElement(data[ind].steamid);
          currentplayer.heroname = data[ind].selectedhero;
        }
      }
    }
  } else if (key === 'CMdata' && data != null) {
    var teamID = Players.GetTeam(Game.GetLocalPlayerID());
    var weare = teamID === 2 ? 'radiant' : 'dire';
    if (data["currentstage"] == 0) {
      if (data["captain" + weare] == "empty") {
        FindDotaHudElement('HeroPreview').style.visibility = "collapse";
        FindDotaHudElement('HeroLockIn').style.visibility = "collapse";
        FindDotaHudElement('HeroRandom').style.visibility = "collapse";
        FindDotaHudElement('BecomeCaptain').style.visibility = "visible";
      } else {
        FindDotaHudElement('HeroPreview').style.visibility = "collapse";
        FindDotaHudElement('HeroLockIn').style.visibility = "collapse";
        FindDotaHudElement('HeroRandom').style.visibility = "collapse";
        FindDotaHudElement('BecomeCaptain').style.visibility = "collapse";
        for (var nkey in data["order"]) {
          var obj = data["order"][nkey];
          if (obj.side == 2) {
            var newimage = $.CreatePanel('DOTAHeroImage', FindDotaHudElement('CM' + 'Radiant' + obj.type), "CMStep" + nkey);
          } else if (obj.side == 3) {
            var newimage = $.CreatePanel('DOTAHeroImage', FindDotaHudElement('CM' + 'Dire' + obj.type), "CMStep" + nkey);
          }

      }
        // setup right hand panel
      }
    } else if (data["currentstage"] <= data["totalstages"]) {
      FindDotaHudElement('HeroPreview').style.visibility = "collapse";
      FindDotaHudElement('HeroLockIn').style.visibility = "collapse";
      FindDotaHudElement('HeroRandom').style.visibility = "collapse";
      FindDotaHudElement('BecomeCaptain').style.visibility = "collapse";
      if (Game.GetLocalPlayerID() == data["captain" + weare]) {
        FindDotaHudElement('CaptainLockIn').style.visibility = "visible";
      }
      console.log(data["currentstage"]);
      console.log(data["totalstages"]);
      //console.log(data["order"][data["currentstage"]]);
      FindDotaHudElement("CMStep" + data["currentstage"]).heroname = data["order"][data["currentstage"]].hero;
    } else {
      // up[date] right panel button for everybody to select out of five
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

function PreviewHero (name) {
  if (!herolocked) {
    var preview = FindDotaHudElement('HeroPreview');
    preview.RemoveAndDeleteChildren();
    preview.BCreateChildren("<DOTAScenePanel unit='" + name + "'/>");
    selectedhero = name;
  }
}

function SelectHero () {
  if (!herolocked && selectedhero !== 'empty') {
    herolocked = true;
    GameEvents.SendCustomGameEventToServer('hero_selected', {
      hero: selectedhero
    });
    FindDotaHudElement('HeroLockIn').style.brightness = 0.5;
    FindDotaHudElement('HeroRandom').style.brightness = 0.5;
  }
}

function BecomeCaptain () {
  GameEvents.SendCustomGameEventToServer('cm_become_captain', {
    test: "1"
  });
}

function CaptainSelectHero () {
  if (selectedhero !== 'empty') {
    GameEvents.SendCustomGameEventToServer('cm_hero_selected', {
      hero: selectedhero
    });
  }
}

function GoToStrategy () {
  FindDotaHudElement('MainContent').style.transform = 'translateX(0) translateY(100%)';
  FindDotaHudElement('MainContent').style.opacity = '0';
  FindDotaHudElement('StrategyContent').style.transform = 'scaleX(1) scaleY(1)';
  FindDotaHudElement('StrategyContent').style.opacity = '1';
  FindDotaHudElement('PregameBG').style.opacity = '0.15';

  var bossMarkers = ['Boss1r', 'Boss1d', 'Boss2r', 'Boss2d', 'Boss3r', 'Boss3d', 'Boss4r', 'Boss4d', 'Boss5r', 'Boss5d', 'Duel1', 'Duel2', 'Cave1r', 'Cave1d', 'Cave2r', 'Cave2d', 'Cave3r', 'Cave3d'];

  bossMarkers.forEach(function (element) {
    FindDotaHudElement(element).style.transform = 'translateY(0)';
    FindDotaHudElement(element).style.opacity = '1';
  });

  FindDotaHudElement('MainContent').GetParent().style.opacity = 0;
  FindDotaHudElement('MainContent').GetParent().style.transform = 'scaleX(3) scaleY(3) translateY(25%)';
}
