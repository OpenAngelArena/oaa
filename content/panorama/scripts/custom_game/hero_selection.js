/* global Players, $, GameEvents */

var console = {
  log: $.Msg.bind($)
};

if (typeof module !== 'undefined' && module.exports) {
  module.exports = SelectHero;
}

function SelectHero () {
  FindDotaHudElement('MainContent').style.transform = 'scaleX(15) scaleY(15)';
  FindDotaHudElement('MainContent').style.opacity = '0';
  FindDotaHudElement('StrategyContent').style.transform = 'scaleX(1) scaleY(1)';
  FindDotaHudElement('StrategyContent').style.opacity = '1';
}
