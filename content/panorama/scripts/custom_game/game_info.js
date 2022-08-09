/* global FindDotaHudElement */

if (typeof module !== 'undefined' && module.exports) {
  module.exports = ToggleInfo;
}

let isopen = false;

function ToggleInfo () {
  if (isopen) {
    isopen = false;
    FindDotaHudElement('InfoButton').GetParent().style.transform = 'translateX(-450px)';
  } else {
    isopen = true;
    FindDotaHudElement('InfoButton').GetParent().style.transform = 'translateX(0)';
  }
}
