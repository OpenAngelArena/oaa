/* global $, GameEvents, Game, DOTA_GameState */

var HudNotFoundException = /** @class */ (function () {
  function HudNotFoundException(message) {
      this.message = message;
  }
  return HudNotFoundException;
}());
function FindDotaHudElement(id) {
  return GetDotaHud().FindChildTraverse(id);
}
function GetDotaHud() {
  var p = $.GetContextPanel();
  while (p !== null && p.id !== 'Hud') {
      p = p.GetParent();
  }
  if (p === null) {
      throw new HudNotFoundException('Could not find Hud root as parent of panel with id: ' + $.GetContextPanel().id);
  }
  else {
      return p;
  }
}

(function () {
  hideShowUI(Game.GetState());
  if (Game.GameStateIsBefore(DOTA_GameState.DOTA_GAMERULES_STATE_HERO_SELECTION)) {
    listenToGameEvent('oaa_state_change', onStateChange);
  }

  function onStateChange (data) {
    hideShowUI(data.newState);
  }
}());

function hideShowUI (state) {
  if (state === 2) {
    hidePregameUI();
  } else if (state < 7) {
    showPregameUI();
  } else {
    hidePregameUI();
  }
}

function hidePregameUI () {
  FindDotaHudElement('PreGame').style.opacity = 0;
  FindDotaHudElement('PreGame').style.visibility = 'collapse';
}
function showPregameUI () {
  FindDotaHudElement('PreGame').style.opacity = 1;
  FindDotaHudElement('PreGame').style.visibility = 'visible';
}

function FindDotaHudElement (id) {
  return GetDotaHud().FindChildTraverse(id);
}

function GetDotaHud () {
  var p = $.GetContextPanel();
  try {
    while (true) {
      if (p.id === 'Hud') {
        return p;
      } else {
        p = p.GetParent();
      }
    }
  } catch (e) {}
}

function listenToGameEvent (event, handler) {
  var handle = GameEvents.Subscribe(event, handleWrapper);
  var doneListening = false;

  return unlisten;

  function unlisten () {
    doneListening = true;
    GameEvents.Unsubscribe(handle);
  }
  function handleWrapper () {
    if (doneListening) {
      return;
    }
    handler.apply(this, arguments);
  }
}

$.GetContextPanel().SetHasClass('TenVTen', Game.GetMapInfo().map_display_name === 'oaa_10v10');
