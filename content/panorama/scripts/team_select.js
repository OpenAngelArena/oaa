/* global $, GameEvents, Game, DOTA_GameState, CustomNetTables */

if (typeof module !== 'undefined' && module.exports) {
  module.exports = {
    MMRShuffle: MMRShuffle,
    onPanelChange: onPanelChange,
    onFocus: onFocus
  };
}

let IsHost = Game.GetLocalPlayerInfo().player_has_host_privileges;

(function () {
  hideShowUI(Game.GetState());
  if (Game.GameStateIsBefore(DOTA_GameState.DOTA_GAMERULES_STATE_HERO_SELECTION)) {
    listenToGameEvent('oaa_state_change', onStateChange);
  }

  function onStateChange (data) {
    hideShowUI(data.newState);
  }

  hostTitle();
  loadSettings(CustomNetTables.GetTableValue('oaa_settings', 'default'));
}());

if (Game.GetMapInfo().map_display_name === '1v1') {
  let smallPlayerPoolButton = $('#small_player_pool');
  if (smallPlayerPoolButton) {
    smallPlayerPoolButton.enabled = false;
    smallPlayerPoolButton.style.opacity = 0;
    smallPlayerPoolButton.style.visibility = 'collapse';
  }
}

function MMRShuffle () {
  $.Msg('Clicked shuffle!');
  if (!IsHost) {
    return;
  }
  GameEvents.SendCustomGameEventToServer('mmrShuffle', {
    shuffle: true
  });
}

function hideShowUI (state) {
  if (state === DOTA_GameState.DOTA_GAMERULES_STATE_CUSTOM_GAME_SETUP) {
    hidePregameUI();
  } else if (state < DOTA_GameState.DOTA_GAMERULES_STATE_PRE_GAME) {
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
  let handle = GameEvents.Subscribe(event, handleWrapper);
  let doneListening = false;

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

$.GetContextPanel().SetHasClass('TenVTen', Game.GetMapInfo().map_display_name === '10v10');

if (!IsHost) {
  $('#SettingsBody').enabled = false;
}

function hostTitle () {
  if ($('#Host')) {
    for (let i of Game.GetAllPlayerIDs()) {
      if (Game.GetPlayerInfo(i) && Game.GetPlayerInfo(i).player_has_host_privileges) {
        $('#Host').text = 'HOST: ' + Players.GetPlayerName(i);
      }
    }
  } else {
    $.Msg('Failed to set host name on Team Select screen');
    // $.Schedule(0.1, hostTitle);
  }
}

function loadSettings (kv, secondTime) {
  if (kv) {
    for (let i in kv) {
      updatePanel({setting: i, value: kv[i]});
    }
    $.Msg('Succesfully loaded/changed Game Settings.');
  } else {
    // didnt happen, lua loads before clients?
    if (!secondTime) {
      $.Msg('Failed to load Game Settings. Trying again one more time.');
      $.Schedule(0.1, loadSettings(kv, true));
    }
  }
}

CustomNetTables.SubscribeNetTableListener('oaa_settings', function (t, k, kv) {
  if (k === 'locked') {
    $.Msg('oaa_settings :', k);
    $('#SettingsBody').enabled = false;
    loadSettings(kv);
  }
});

function onPanelChange (name) {
  if (!IsHost) {
    return;
  }
  const panel = $('#' + name);
  if (!panel) {
    return;
  }
  const panelType = panel.paneltype;
  let val;

  if (panelType === 'DropDown') {
    val = panel.GetSelected().id;
  } else if (panelType === 'ToggleButton') {
    val = panel.checked;
  } else if (panelType === 'TextEntry') {
    val = parseFloat(panel.text);
    if (isNaN(val)) {
      val = 0;
    }
  }
  if (val !== undefined) {
    GameEvents.SendCustomGameEventToAllClients('oaa_setting_changed', {setting: name, value: val});
    GameEvents.SendCustomGameEventToServer('oaa_setting_changed', {setting: name, value: val});
  }
  if (panelType === 'Button') {
    GameEvents.SendCustomGameEventToServer('oaa_button_clicked', {button: name});
  }
}

GameEvents.Subscribe('oaa_setting_changed', updatePanel);

function updatePanel (kv) {
  let name = kv.setting;
  let val = kv.value;
  let panel = $('#' + name);
  if (panel) {
    let panelType = panel.paneltype;
    switch (true) {
      case (panelType === 'DropDown'):
        panel.SetSelected(val);
        break;
      case (panelType === 'Label'):
        panel.text = val;
        break;
      case (panelType === 'ToggleButton'):
        panel.checked = val;
        break;
      case (panelType === 'TextEntry'):
        panel.text = val + panel.GetAttributeString('unit', '');
        if (parseFloat(val) !== parseFloat(panel.text)) {
          panel.text = val;
        }
        break;
      default:
        break;
    }
  }
}

function onFocus (name) {
  if (!IsHost) {
    return;
  }
  let panel = $('#' + name);
  let panelType = panel.paneltype;
  if (panelType === 'TextEntry') {
    panel.text = parseFloat(panel.text);
  }
  panel.SetAcceptsFocus(true);
}
