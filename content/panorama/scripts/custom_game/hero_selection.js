/* global Players, $, GameEvents */

var console = {
  log: $.Msg.bind($)
};

if (typeof module !== 'undefined' && module.exports) {
  module.exports = SelectHero;
}

var gotHeroList = false;

(function () {

  onPlayerStatChange( null, null, CustomNetTables.GetTableValue('hero_selection', "data"));
  CustomNetTables.SubscribeNetTableListener('hero_selection', onPlayerStatChange);

}());

function onPlayerStatChange (table, key, data) {
  if (!gotHeroList && data.herolist != null) {
    var agilityholder = FindDotaHudElement('AgilityHeroes');
    for (key in data.herolist) {
      if (data.herolist[key] == 1) {
        var newelement = $.CreatePanel('RadioButton', agilityholder, key);
        newelement.group = "HeroChoises";
        newelement.SetPanelEvent("onactivate", (function(newkey) { return function() { PreviewHero(newkey) }}(key)) );
        var newimage = $.CreatePanel('DOTAHeroImage', newelement, '');
        newimage.hittest = false;
        newimage.AddClass("HeroCard");
        newimage.heroname = key;
      }
    }
  }
}

function PreviewHero(name) {
  console.log(name);
  var preview = FindDotaHudElement('HeroPreview');
  preview.RemoveAndDeleteChildren();
  preview.BCreateChildren("<DOTAScenePanel unit='" + name + "'/>");
}


function SelectHero () {
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
