/* global Players, $, GameEvents */

var console = {
  log: $.Msg.bind($)
};

if (typeof module !== 'undefined' && module.exports) {
  module.exports = SelectHero;
}

(function () {
  onPlayerStatChange( null, "herolist", CustomNetTables.GetTableValue('hero_selection', "herolist"));
  onPlayerStatChange( null, "data", CustomNetTables.GetTableValue('hero_selection', "data"));
  CustomNetTables.SubscribeNetTableListener('hero_selection', onPlayerStatChange);
}());

var selectedhero = "empty";
var herolocked = false;
var panelscreated = 0;


function onPlayerStatChange (table, key, data) {
  if (key == "herolist" && data != null) {
    var strengthholder = FindDotaHudElement('StrengthHeroes');
    var agilityholder = FindDotaHudElement('AgilityHeroes');
    var intelligenceholder = FindDotaHudElement('IntelligenceHeroes');
    for (key in data) {
      var currentstat = null;
      switch(data[key]) {
        case "DOTA_ATTRIBUTE_STRENGTH":
          currentstat = strengthholder;
          break;
        case "DOTA_ATTRIBUTE_AGILITY":
          currentstat = agilityholder;
          break;
        case "DOTA_ATTRIBUTE_INTELLECT":
          currentstat = intelligenceholder;
          break;
      }
      var newelement = $.CreatePanel('RadioButton', currentstat, key);
      newelement.group = "HeroChoises";
      newelement.SetPanelEvent("onactivate", (function(newkey) { return function() { PreviewHero(newkey) }}(key)) );
      var newimage = $.CreatePanel('DOTAHeroImage', newelement, '');
      newimage.hittest = false;
      newimage.AddClass("HeroCard");
      newimage.heroname = key;
    }
  } else if (key == "data" && data != null) {
    var length = Object.keys(data).length;
    if (panelscreated != length) {
      panelscreated = length;
      var teamdire = FindDotaHudElement('TeamDire');
      var teamradiant = FindDotaHudElement('TeamRadiant');
      teamdire.RemoveAndDeleteChildren();
      teamradiant.RemoveAndDeleteChildren();
      for (var key in data) {
        // skip loop if the property is from prototype
        if (data.hasOwnProperty(key)) {
          var currentteam = null;
          switch(data[key].team) {
            case 2:
              currentteam = teamradiant;
              break;
            case 2:
              currentteam = teamdire;
              break;
          };
          var newelement = $.CreatePanel('Panel', currentteam, '');
          newelement.AddClass("Player");
          var newimage = $.CreatePanel('DOTAHeroImage', newelement, data[key].steamid);
          newimage.hittest = false;
          newimage.AddClass("PlayerImage");
          newimage.heroname = data[key].selectedhero;
          var newlabel = $.CreatePanel('Label', newelement, '');
          newlabel.AddClass("PlayerLabel");
          newlabel.text = data[key].steamid;
        }
      }
    }
  }
}

function PreviewHero(name) {
  if (!herolocked) {
    var preview = FindDotaHudElement('HeroPreview');
    preview.RemoveAndDeleteChildren();
    preview.BCreateChildren("<DOTAScenePanel unit='" + name + "'/>");
    selectedhero = name;
  }
}


function SelectHero () {
  if (!herolocked) {
    herolocked = true;
    GameEvents.SendCustomGameEventToServer('hero_selected', {
      hero: selectedhero
    });
  }
}

function GoToStrategy() {
  FindDotaHudElement('MainContent').style.transform = 'translateX(0) translateY(100%)';
  FindDotaHudElement('MainContent').style.opacity = '0';
  FindDotaHudElement('StrategyContent').style.transform = 'scaleX(1) scaleY(1)';
  FindDotaHudElement('StrategyContent').style.opacity = '1';
  FindDotaHudElement('PregameBG').style.opacity = '0.15';

  var bossMarkers = ['Boss1r', 'Boss1d', 'Boss2r', 'Boss2d', 'Boss3r', 'Boss3d', 'Boss4r', 'Boss4d', 'Boss5r', 'Boss5d', 'Duel1', 'Duel2'];

  bossMarkers.forEach(function(element) {
    FindDotaHudElement(element).style.transform = 'translateY(0)';
    FindDotaHudElement(element).style.opacity = '1';
  });
}
