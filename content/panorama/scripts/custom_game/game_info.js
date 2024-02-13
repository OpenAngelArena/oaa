/* global FindDotaHudElement, Game */

if (typeof module !== 'undefined' && module.exports) {
  module.exports = ToggleInfo;
}

let isopen = false;

function ToggleInfo () {
  const infoPanel = FindDotaHudElement('InfoButton').GetParent();
  if (isopen) {
    isopen = false;
    if (Game.IsHUDFlipped()) {
      infoPanel.style.transform = 'translateX(-450px) scaleX(-1)';
    } else {
      infoPanel.style.transform = 'translateX(-450px)';
    }
  } else {
    isopen = true;
    infoPanel.style.transform = 'translateX(0)';
  }
}

(function () {
  const infoButton = FindDotaHudElement('InfoButton');
  const infoPanel = infoButton.GetParent();
  if (Game.IsHUDFlipped()) {
    infoPanel.style.horizontalAlign = 'right';
    infoPanel.style.transform = 'translateX(-450px) scaleX(-1)';
    infoButton.style.transform = 'scaleX(-1)';
    infoButton.style.marginTop = '10%';
  }
})();
