/* global $, GameEvents, Game, GameUI, CustomNetTables, Players, is10v10, DOTATeam_t */

'use strict';

if (typeof module !== 'undefined' && module.exports) {
  module.exports = {
    MMRShuffle: MMRShuffle,
    onPanelChange: onPanelChange,
    onFocus: onFocus,
    OnLeaveTeamPressed: OnLeaveTeamPressed,
    OnLockAndStartPressed: OnLockAndStartPressed,
    OnCancelAndUnlockPressed: OnCancelAndUnlockPressed,
    OnAutoAssignPressed: OnAutoAssignPressed,
    OnShufflePlayersPressed: OnShufflePlayersPressed
  };
}

// Global list of panels representing each of the teams
const teamPanels = [];
// Global list of panels representing each of the players (1 per-player). These are reparented
// to the appropriate team panel to indicate which team the player is on.
const playerPanels = [];
// Spectator team constant
const DOTA_TEAM_SPECTATOR = 1;
// object to store the mmr values for each player
const playerMmrValues = {};
// Is the local player host?
const IsHost = Game.GetLocalPlayerInfo().player_has_host_privileges;
// Current map name
const mapName = Game.GetMapInfo().map_display_name;

// --------------------------------------------------------------------------------------------------
// Handler for when the unssigned players panel is clicked that causes the player to be reassigned
// to the unssigned players team
// --------------------------------------------------------------------------------------------------
function OnLeaveTeamPressed () {
  Game.PlayerJoinTeam(DOTATeam_t.DOTA_TEAM_NOTEAM);
}

// --------------------------------------------------------------------------------------------------
// Handler for when the Lock and Start button is pressed
// --------------------------------------------------------------------------------------------------
function OnLockAndStartPressed () {
  // Don't allow a forced start if there are unassigned players
  if (Game.GetUnassignedPlayerIDs().length > 0) { return; }

  // Lock the team selection so that no more team changes can be made
  Game.SetTeamSelectionLocked(true);

  // Disable the auto start count down
  Game.SetAutoLaunchEnabled(false);

  // Set the remaining time before the game starts
  Game.SetRemainingSetupTime(4);
}

// --------------------------------------------------------------------------------------------------
// Handler for when the Cancel and Unlock button is pressed
// --------------------------------------------------------------------------------------------------
function OnCancelAndUnlockPressed () {
  // Unlock the team selection, allowing the players to change teams again
  Game.SetTeamSelectionLocked(false);

  // Stop the countdown timer
  Game.SetRemainingSetupTime(-1);
}

// --------------------------------------------------------------------------------------------------
// Handler for the auto assign button being pressed
// --------------------------------------------------------------------------------------------------
function OnAutoAssignPressed () {
  // Assign all of the currently unassigned players to a team, trying
  // to keep any players that are in a party on the same team.
  Game.AutoAssignPlayersToTeams();
}

// --------------------------------------------------------------------------------------------------
// Handler for the shuffle player teams button being pressed - unused
// --------------------------------------------------------------------------------------------------
function OnShufflePlayersPressed () {
  // Shuffle the team assignments of any players which are assigned to a team,
  // this will not assign any players to a team which are currently unassigned.
  // This will also not attempt to keep players in a party on the same team.
  Game.ShufflePlayerTeamAssignments();
}

// --------------------------------------------------------------------------------------------------
// Find the player panel for the specified player in the global list or create the panel if there
// is not already one in the global list. Make the new or existing panel a child panel of the
// specified parent panel
// --------------------------------------------------------------------------------------------------
function FindOrCreatePanelForPlayer (playerId, parent) {
  // Search the list of player player panels for one witht the specified player id
  for (let i = 0; i < playerPanels.length; ++i) {
    const playerPanel = playerPanels[i];

    if (playerPanel.GetAttributeInt('player_id', -1) === playerId) {
      playerPanel.SetParent(parent);
      let badgeLevel = 1;
      const mmr = playerMmrValues[playerId];

      if (mmr > 1100) {
        badgeLevel++;
      }
      if (mmr > 1300) {
        badgeLevel++;
      }
      if (mmr > 1500) {
        badgeLevel++;
      }
      if (mmr > 1700) {
        badgeLevel++;
      }
      playerPanel.SetHasClass(`mmr_badge_${badgeLevel}`, true);
      return playerPanel;
    }
  }

  // Create a new player panel for the specified player id if an existing one was not found
  const newPlayerPanel = $.CreatePanel('Panel', parent, 'player_root');
  newPlayerPanel.SetAttributeInt('player_id', playerId);
  newPlayerPanel.BLoadLayout('file://{resources}/layout/custom_game/team_select_player.xml', false, false);

  newPlayerPanel.SetPanelEvent('onmouseover', function () {
    if (playerMmrValues[playerId]) {
      $.DispatchEvent('DOTAShowTextTooltip', newPlayerPanel, `OAA Rating: ${Math.round(playerMmrValues[playerId])}`);
    }
  });

  newPlayerPanel.SetPanelEvent('onmouseout', function () {
    $.DispatchEvent('DOTAHideTextTooltip', newPlayerPanel);
  });

  // Add the panel to the global list of player planels so that we will find it next time
  playerPanels.push(newPlayerPanel);

  return newPlayerPanel;
}

// --------------------------------------------------------------------------------------------------
// Find player slot n in the specified team panel
// --------------------------------------------------------------------------------------------------
function FindPlayerSlotInTeamPanel (teamPanel, playerSlot) {
  const playerListNode = teamPanel.FindChildInLayoutFile('PlayerList');
  if (playerListNode == null) { return null; }

  const nNumChildren = playerListNode.GetChildCount();
  for (let i = 0; i < nNumChildren; ++i) {
    const panel = playerListNode.GetChild(i);
    if (panel.GetAttributeInt('player_slot', -1) === playerSlot) {
      return panel;
    }
  }

  return null;
}

// --------------------------------------------------------------------------------------------------
// Update the specified team panel ensuring that it has all of the players currently assigned to its
// team and the the remaining slots are marked as empty
// --------------------------------------------------------------------------------------------------
function UpdateTeamPanel (teamPanel) {
  // Get the id of team this panel is displaying
  const teamId = teamPanel.GetAttributeInt('team_id', -1);
  if (teamId <= 0) { return; }

  let playerSlot;

  // Add all of the players currently assigned to the team
  const teamPlayers = Game.GetPlayerIDsOnTeam(teamId);
  for (let i = 0; i < teamPlayers.length; ++i) {
    playerSlot = FindPlayerSlotInTeamPanel(teamPanel, i);
    if (playerSlot) {
      playerSlot.RemoveAndDeleteChildren();
      FindOrCreatePanelForPlayer(teamPlayers[i], playerSlot);
    }
  }

  // Fill in the remaining player slots with the empty slot indicator
  const teamDetails = Game.GetTeamDetails(teamId);
  const nNumPlayerSlots = teamDetails.team_max_players;
  for (let i = teamPlayers.length; i < nNumPlayerSlots; ++i) {
    playerSlot = FindPlayerSlotInTeamPanel(teamPanel, i);
    if (playerSlot.GetChildCount() === 0) {
      const emptySlot = $.CreatePanel('Panel', playerSlot, 'player_root');
      emptySlot.BLoadLayout('file://{resources}/layout/custom_game/team_select_empty_slot.xml', false, false);
    }
  }

  // Change the display state of the panel to indicate the team is full
  teamPanel.SetHasClass('team_is_full', (teamPlayers.length === teamDetails.team_max_players));

  // If the local player is on this team change team panel to indicate this
  const localPlayerInfo = Game.GetLocalPlayerInfo();
  if (localPlayerInfo) {
    const localPlayerIsOnTeam = (localPlayerInfo.player_team_id === teamId);
    teamPanel.SetHasClass('local_player_on_this_team', localPlayerIsOnTeam);
  }
}

// --------------------------------------------------------------------------------------------------
// Update the unassigned players list and all of the team panels whenever a change is made to the
// player team assignments
// --------------------------------------------------------------------------------------------------
function OnTeamPlayerListChanged () {
  const unassignedPlayersContainerNode = $('#UnassignedPlayersContainer');
  if (unassignedPlayersContainerNode === null) { return; }

  // Move all existing player panels back to the unassigned player list
  for (let i = 0; i < playerPanels.length; ++i) {
    const playerPanel = playerPanels[i];
    playerPanel.SetParent(unassignedPlayersContainerNode);
  }

  // Make sure all of the unassigned player have a player panel
  // and that panel is a child of the unassigned player panel.
  const unassignedPlayers = Game.GetUnassignedPlayerIDs();
  for (let i = 0; i < unassignedPlayers.length; ++i) {
    const playerId = unassignedPlayers[i];
    FindOrCreatePanelForPlayer(playerId, unassignedPlayersContainerNode);
  }

  // Update all of the team panels moving the player panels for the
  // players assigned to each team to the corresponding team panel.
  for (let i = 0; i < teamPanels.length; ++i) {
    UpdateTeamPanel(teamPanels[i]);
  }

  // Set the class on the panel to indicate if there are any unassigned players
  $('#GameAndPlayersRoot').SetHasClass('unassigned_players', unassignedPlayers.length !== 0);
  $('#GameAndPlayersRoot').SetHasClass('no_unassigned_players', unassignedPlayers.length === 0);
}

// --------------------------------------------------------------------------------------------------
// --------------------------------------------------------------------------------------------------
function OnPlayerSelectedTeam (nPlayerId, nTeamId, bSuccess) {
  const playerInfo = Game.GetLocalPlayerInfo();
  if (!playerInfo) { return; }

  // Check to see if the event is for the local player
  if (playerInfo.player_id === nPlayerId) {
    // Play a sound to indicate success or failure
    if (bSuccess) {
      Game.EmitSound('ui_team_select_pick_team');
    } else {
      Game.EmitSound('ui_team_select_pick_team_failed');
    }
  }
}

// --------------------------------------------------------------------------------------------------
// Check to see if the local player has host privileges and set the 'player_has_host_privileges' on
// the root panel if so, this allows buttons to only be displayed for the host.
// --------------------------------------------------------------------------------------------------
function CheckForHostPrivileges () {
  const playerInfo = Game.GetLocalPlayerInfo();
  if (!playerInfo) { return; }

  // Set the "player_has_host_privileges" class on the panel, this can be used
  // to have some sub-panels on display or be enabled for the host player.
  $.GetContextPanel().SetHasClass('player_has_host_privileges', playerInfo.player_has_host_privileges);
}

// --------------------------------------------------------------------------------------------------
// Update the state for the transition timer periodically
// --------------------------------------------------------------------------------------------------
function UpdateTimer () {
  const gameTime = Game.GetGameTime();
  const transitionTime = Game.GetStateTransitionTime();

  CheckForHostPrivileges();

  $('#MapInfo').SetDialogVariable('map_name', mapName);

  if (transitionTime >= 0) {
    $('#StartGameCountdownTimer').SetDialogVariableInt('countdown_timer_seconds', Math.max(0, Math.floor(transitionTime - gameTime)));
    $('#StartGameCountdownTimer').SetHasClass('countdown_active', true);
    $('#StartGameCountdownTimer').SetHasClass('countdown_inactive', false);
  } else {
    $('#StartGameCountdownTimer').SetHasClass('countdown_active', false);
    $('#StartGameCountdownTimer').SetHasClass('countdown_inactive', true);
  }

  const autoLaunch = Game.GetAutoLaunchEnabled();
  $('#StartGameCountdownTimer').SetHasClass('auto_start', autoLaunch);
  $('#StartGameCountdownTimer').SetHasClass('forced_start', (autoLaunch === false));

  // Allow the ui to update its state based on team selection being locked or unlocked
  $.GetContextPanel().SetHasClass('teams_locked', Game.GetTeamSelectionLocked());
  $.GetContextPanel().SetHasClass('teams_unlocked', Game.GetTeamSelectionLocked() === false);

  $.Schedule(0.1, UpdateTimer);
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
  if (key === 'player_mmr') {
    if (typeof kv === 'object') {
      Object.keys(kv).forEach((k) => {
        playerMmrValues[k] = kv[k];
      });
    }
  }

  OnTeamPlayerListChanged();
}

function loadAverageMMRValues (values) {
  $('#RadiantAverageMMR').text = 'Average MMR: ' + values.radiant;
  $('#DireAverageMMR').text = 'Average MMR: ' + values.dire;
}

function MMRShuffle () {
  if (!IsHost) {
    return;
  }
  GameEvents.SendCustomGameEventToServer('mmrShuffle', {
    shuffle: true
  });
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

// --------------------------------------------------------------------------------------------------
// Entry point called when the team select panel is created
// --------------------------------------------------------------------------------------------------
(function () {
  let bShowSpectatorTeam = false;
  let bAutoAssignTeams = true;

  // get any custom config
  if (GameUI.CustomUIConfig().team_select) {
    const cfg = GameUI.CustomUIConfig().team_select;
    if (cfg.bShowSpectatorTeam !== undefined) {
      bShowSpectatorTeam = cfg.bShowSpectatorTeam;
    }
    if (cfg.bAutoAssignTeams !== undefined) {
      bAutoAssignTeams = cfg.bAutoAssignTeams;
    }
  }

  $('#TeamSelectContainer').SetAcceptsFocus(true); // Prevents the chat window from taking focus by default
  const teamsListRootNode = $('#TeamsListRoot');

  // Construct the panels for each team
  const allTeamIDs = Game.GetAllTeamIDs();

  if (bShowSpectatorTeam) {
    allTeamIDs.unshift(DOTA_TEAM_SPECTATOR);
  }

  for (const teamId of allTeamIDs) {
    const teamNode = $.CreatePanel('Panel', teamsListRootNode, '');
    teamNode.AddClass('team_' + teamId); // team_1, etc.
    teamNode.SetAttributeInt('team_id', teamId);
    teamNode.BLoadLayout('file://{resources}/layout/custom_game/team_select_team.xml', false, false);

    // Add the team panel to the global list so we can get to it easily later to update it
    teamPanels.push(teamNode);
  }

  // Automatically assign players to teams.
  if (bAutoAssignTeams) {
    Game.AutoAssignPlayersToTeams();
  }

  // Do an initial update of the player team assignment
  OnTeamPlayerListChanged();

  // Start updating the timer, this function will schedule itself to be called periodically
  UpdateTimer();

  // Register a listener for the event which is brodcast when the team assignment of a player is actually assigned
  $.RegisterForUnhandledEvent('DOTAGame_TeamPlayerListChanged', OnTeamPlayerListChanged);

  // Register a listener for the event which is broadcast whenever a player attempts to pick a team
  $.RegisterForUnhandledEvent('DOTAGame_PlayerSelectedCustomTeam', OnPlayerSelectedTeam);

  hostTitle();

  if (mapName === '1v1' || mapName === 'tinymode') {
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
  handleOAASettingsChange(null, 'player_mmr', CustomNetTables.GetTableValue('oaa_settings', 'player_mmr'));

  GameEvents.SendCustomGameEventToServer('updateAverageMMR', {});
}());
