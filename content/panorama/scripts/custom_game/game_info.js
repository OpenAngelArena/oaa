/* global $ */

var HudNotFoundException = /** @class */ (function () {
  function HudNotFoundException (message) {
    this.message = message;
  }
  return HudNotFoundException;
}());
function FindDotaHudElement (id) {
  return GetDotaHud().FindChildTraverse(id);
}
function GetDotaHud () {
  var p = $.GetContextPanel();
  while (p !== null && p.id !== 'Hud') {
    p = p.GetParent();
  }
  if (p === null) {
    throw new HudNotFoundException('Could not find Hud root as parent of panel with id: ' + $.GetContextPanel().id);
  } else {
    return p;
  }
}

if (typeof module !== 'undefined' && module.exports) {
  module.exports = ToggleInfo;
}

var isopen = false;

function ToggleInfo () {
  if (isopen) {
    isopen = false;
    FindDotaHudElement('InfoButton').GetParent().style.transform = 'translateX(-450px)';
  } else {
    isopen = true;
    FindDotaHudElement('InfoButton').GetParent().style.transform = 'translateX(0)';
  }
}
