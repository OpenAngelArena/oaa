/* global $, GameUI, Entities, Players */
'use strict';

/*
  Author:
    Angel Arena Blackstar
  Credits:
    Angel Arena Blackstar
*/

if (typeof module !== 'undefined' && module.exports) {
  module.exports.FindDotaHudElement = FindDotaHudElement;
  module.exports.ColorToHexCode = ColorToHexCode;
  module.exports.ColoredText = ColoredText;
}

class HudNotFoundException {
  constructor(readonly message: string) {
  }
}

var PlayerTables = GameUI.CustomUIConfig().PlayerTables;

function FindDotaHudElement(id: string): Panel {
  return GetDotaHud().FindChildTraverse(id);
}

function GetDotaHud() {
  var p: Panel | null = $.GetContextPanel();
  while (p !== null && p.id !== 'Hud') {
    p = p.GetParent();
  }
  if (p === null) {
    throw new HudNotFoundException('Could not find Hud root as parent of panel with id: ' + $.GetContextPanel().id);
  } else {
    return p;
  }
}

/**
 * Takes an integer and returns a hex code string of the color represented by the integer
 */
function ColorToHexCode(color: number): string {
  let red = (color & 0xff).toString(16);
  let green = ((color & 0xff00) >> 8).toString(16);
  let blue = ((color & 0xff0000) >> 16).toString(16);
  return '#' + red + green + blue;
}

function ColoredText(colorCode: string, text: string): string {
  return `<font color="${colorCode}">${text}</font>`
}
// SNIPPET END
