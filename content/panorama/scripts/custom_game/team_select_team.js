/* global $, Game, GameUI */

'use strict';

if (typeof module !== 'undefined' && module.exports) {
  module.exports = {
    OnJoinTeamPressed: OnJoinTeamPressed
  };
}

// --------------------------------------------------------------------------------------------------
// Handle the team panel button press and assign the player to the team
// --------------------------------------------------------------------------------------------------
function OnJoinTeamPressed () {
  // Get the team id asscociated with the team button that was pressed
  const teamId = $.GetContextPanel().GetAttributeInt('team_id', -1);

  // Request to join the team of the button that was pressed
  Game.PlayerJoinTeam(teamId);
}

// --------------------------------------------------------------------------------------------------
// Entry point function for a team panel, there is one team panel per-team, so this will be called
// once for each each of the teams.
// --------------------------------------------------------------------------------------------------
(function () {
  const teamId = $.GetContextPanel().GetAttributeInt('team_id', -1);
  const teamDetails = Game.GetTeamDetails(teamId);

  // Add the team logo to the panel
  const logoXML = GameUI.CustomUIConfig().team_logo_xml;
  if (logoXML) {
    const teamLogoPanel = $('#TeamLogo');
    teamLogoPanel.SetAttributeInt('team_id', teamId);
    teamLogoPanel.BLoadLayout(logoXML, false, false);
  }

  // Set the team name
  $('#TeamNameLabel').text = $.Localize(teamDetails.team_name);

  // Get the player list and add player slots so that there are upto team_max_player slots
  const playerListNode = $.GetContextPanel().FindChildInLayoutFile('PlayerList');

  const numPlayerSlots = teamDetails.team_max_players;
  for (let i = 0; i < numPlayerSlots; ++i) {
    // Add the slot itself
    const slot = $.CreatePanel('Panel', playerListNode, '');
    slot.AddClass('player_slot');
    slot.SetAttributeInt('player_slot', i);
  }

  if (GameUI.CustomUIConfig().team_colors) {
    let teamColor = GameUI.CustomUIConfig().team_colors[teamId];
    teamColor = teamColor.replace(';', '');

    let gradientText;

    const teamBackgroundGradient = $('#TeamBackgroundGradient');
    if (teamBackgroundGradient) {
      gradientText = 'gradient( linear, -800% -1600%, 50% 100%, from( ' + teamColor + ' ), to( #00000088 ) );';
      teamBackgroundGradient.style.backgroundColor = gradientText;
    }

    const teamBackgroundGradientHighlight = $('#TeamBackgroundGradientHighlight');
    if (teamBackgroundGradientHighlight) {
      gradientText = 'gradient( linear, -800% -1600%, 90% 100%, from( ' + teamColor + ' ), to( #00000088 ) );';
      teamBackgroundGradientHighlight.style.backgroundColor = gradientText;
    }

    const teamNameLabel = $('#TeamNameLabel');
    if (teamNameLabel) {
      const colorText = teamColor + ';';
      teamNameLabel.style.color = colorText;
    }
  }
})();
