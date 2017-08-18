/* global Players, $, GameEvents */

var console = {
  log: $.Msg.bind($)
};

if (typeof module !== 'undefined' && module.exports) {
  module.exports = SelectHero;
}

function SelectHero () {
  FindDotaHudElement('MainContent').style.transform = 'translateX(0) translateY(100%)';
  FindDotaHudElement('MainContent').style.opacity = '0';
  FindDotaHudElement('StrategyContent').style.transform = 'scaleX(1) scaleY(1)';
  FindDotaHudElement('StrategyContent').style.opacity = '1';
  FindDotaHudElement('PregameBG').style.opacity = '0.15';



  var bossMarkers = ['Boss1r', 'Boss1d', 'Boss2r', 'Boss2d', 'Boss3r', 'Boss3d', 'Boss4r', 'Boss4d', 'Boss5r', 'Boss5d'];

  bossMarkers.forEach(function(element) {
    FindDotaHudElement(element).style.transform = 'translateY(0)';
    FindDotaHudElement(element).style.opacity = '1';
  });
}
