/* global $, Game, Entities, Buffs */
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
  module.exports.LuaTableToArray = LuaTableToArray;
  module.exports.is10v10 = is10v10;
  module.exports.FindModifier = FindModifier;
  module.exports.HasModifier = HasModifier;
  module.exports.GetStackCount = GetStackCount;
  module.exports.GetDotaHud = GetDotaHud;
}
const HudNotFoundException = /** @class */ (function () {
  function HudNotFoundException (message) {
    this.message = message;
  }
  return HudNotFoundException;
}());

function FindDotaHudElement (id) {
  return GetDotaHud().FindChildTraverse(id);
}

function GetDotaHud () {
  let p = $.GetContextPanel();
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
 * Takes an array-like table passed from Lua that has stringified indices starting from 1
 * and returns an array of type T containing the elements of the table.
 * Order of elements is preserved.
 */
function LuaTableToArray (table) {
  const array = [];
  for (let i = 1; table[i.toString()] !== undefined; i++) {
    array.push(table[i.toString()]);
  }
  return array;
}
/**
 * Takes an integer and returns a hex code string of the color represented by the integer
 */
function ColorToHexCode (color) {
  let red = (color & 0xff).toString(16);
  let green = ((color & 0xff00) >> 8).toString(16);
  let blue = ((color & 0xff0000) >> 16).toString(16);
  if (red === '0') {
    red = '00';
  }
  if (green === '0') {
    green = '00';
  }
  if (blue === '0') {
    blue = '00';
  }
  return '#' + red + green + blue;
}

function ColoredText (colorCode, text) {
  return '<font color="' + colorCode + '">' + text + '</font>';
}

function is10v10 () {
  const mapname = Game.GetMapInfo().map_display_name;
  return mapname === '10v10' || mapname === 'oaa_bigmode' || mapname == 'oaa_alternate';
}

// FindModifier returns BuffID or undefined
function FindModifier (unit, modifierName) {
  for (let i = 0; i < Entities.GetNumBuffs(unit); i++) {
    if (Buffs.GetName(unit, Entities.GetBuff(unit, i)) === modifierName) {
      return Entities.GetBuff(unit, i);
    }
  }
}

// HasModifier returns a boolean
function HasModifier (unit, modifierName) {
  return FindModifier(unit, modifierName) !== undefined;
}

// GetStackCount returns a number
function GetStackCount (unit, modifierName) {
  const m = FindModifier(unit, modifierName);
  return m !== undefined ? Buffs.GetStackCount(unit, m) : 0;
}
