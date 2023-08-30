/* global $, GameEvents, Game, DOTA_GameState, CustomNetTables, Players, FindDotaHudElement, is10v10 */

if (typeof module !== 'undefined' && module.exports) {
  module.exports = {
    MMRShuffle: MMRShuffle,
    onPanelChange: onPanelChange,
    onFocus: onFocus
  };
}

const IsHost = Game.GetLocalPlayerInfo().player_has_host_privileges;

(function () {
  hideShowUI(Game.GetState());
  if (Game.GameStateIsBefore(DOTA_GameState.DOTA_GAMERULES_STATE_HERO_SELECTION)) {
    listenToGameEvent('oaa_state_change', onStateChange);
  }

  hostTitle();

  if (Game.GetMapInfo().map_display_name === '1v1') {
    const smallPlayerPoolButton = $('#small_player_pool');
    if (smallPlayerPoolButton) {
      smallPlayerPoolButton.enabled = false;
      smallPlayerPoolButton.style.opacity = 0;
      smallPlayerPoolButton.style.visibility = 'collapse';
    }
  }

  $.GetContextPanel().SetHasClass('TenVTen', is10v10());

  $('#SettingsBody').enabled = IsHost;

  CustomNetTables.SubscribeNetTableListener('oaa_settings', handleOAASettingsChange);
  handleOAASettingsChange(null, 'settings', CustomNetTables.GetTableValue('oaa_settings', 'settings'));
  handleOAASettingsChange(null, 'average_team_mmr', CustomNetTables.GetTableValue('oaa_settings', 'average_team_mmr'));

  GameEvents.SendCustomGameEventToServer('updateAverageMMR', {});
}());

// function RandomizeModifiers () {
// $.Msg('Clicked randomize!');
// if (!IsHost) {
// return;
// }
// GameEvents.SendCustomGameEventToServer('randomizeModifiers', {
// shuffle: true
// });
// }

function onStateChange (data) {
  hideShowUI(data.newState);
}

function handleOAASettingsChange (t, key, kv) {
  if (key === 'settings') {
    $.Msg('oaa_settings :' + key);
    loadSettings(kv);
    return;
  }
  if (key === 'locked') {
    $.Msg('oaa_settings :' + key);
    $('#SettingsBody').enabled = false;
    loadSettings(kv);
    return;
  }
  if (key === 'average_team_mmr') {
    $.Msg('oaa_settings :' + key);
    loadAverageMMRValues(kv);
  }
}

function loadAverageMMRValues (values) {
  $('#RadiantAverageMMR').text = 'Average MMR: ' + values.radiant;
  $('#DireAverageMMR').text = 'Average MMR: ' + values.dire;
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

function listenToGameEvent (event, handler) {
  const handle = GameEvents.Subscribe(event, handleWrapper);
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

function hostTitle () {
  if ($('#Host')) {
    for (const i of Game.GetAllPlayerIDs()) {
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
    for (const i in kv) {
      updatePanel({ setting: i, value: kv[i] });
    }
    $.Msg('Succesfully loaded/changed Game Settings.');
  }
}

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
    GameEvents.SendCustomGameEventToAllClients('oaa_setting_changed', { setting: name, value: val });
    GameEvents.SendCustomGameEventToServer('oaa_setting_changed', { setting: name, value: val });
  }
  if (panelType === 'Button') {
    GameEvents.SendCustomGameEventToServer('oaa_button_clicked', { button: name });
  }
}

function updatePanel (kv) {
  const name = kv.setting;
  const val = kv.value;
  const panel = $('#' + name);
  if (panel) {
    const panelType = panel.paneltype;
    switch (panelType) {
      case 'DropDown':
        panel.SetSelected(val);
        break;
      case 'Label':
        panel.text = val;
        break;
      case 'ToggleButton':
        panel.checked = val;
        break;
      case 'TextEntry':
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
  const panel = $('#' + name);
  const panelType = panel.paneltype;
  if (panelType === 'TextEntry') {
    panel.text = parseFloat(panel.text);
  }
  panel.SetAcceptsFocus(true);
}
