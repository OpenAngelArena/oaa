/* global FindDotaHudElement Game GameEvents */

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

function HideOrShowInfoButton () {
  const infoButton = FindDotaHudElement('InfoButton');
  const hidden = infoButton.style.opacity === '0.0';
  if (isopen) {
    ToggleInfo(); // close it first before hiding
  }
  if (hidden) {
    infoButton.style.opacity = 1;
    infoButton.style.visibility = 'visible';
  } else {
    infoButton.style.opacity = 0;
    infoButton.style.visibility = 'collapse';
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
  } else {
    // Killcam (death summary) creation and removal event
    GameEvents.Subscribe('dota_player_update_killcam_unit', HideOrShowInfoButton);
  }
})();
