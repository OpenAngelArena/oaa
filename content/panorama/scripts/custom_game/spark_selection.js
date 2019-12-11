/* global CustomNetTables, Game, GameEvents, Players */

var forcedPickSpark = false;
var currentSpark = null;

(function () {
  if (Game.GetLocalPlayerID() === -1) {
    return;
  }
  CustomNetTables.SubscribeNetTableListener('hero_selection', SparkSelection);
  ResetSparkDisplay();
})();

if (typeof module !== 'undefined' && module.exports) {
  module.exports = {
    SelectSpark: SelectSpark,
    OpenSparkSelection: OpenSparkSelection,
    SparkFinished: SparkFinished
  };
}

function ResetSparkDisplay () {
  SparkSelection(null, 'team_sparks', CustomNetTables.GetTableValue('hero_selection', 'team_sparks'));
}

function SparkSelection (table, key, args) {
  if (key !== 'team_sparks') {
    return;
  }
  var playerID = Game.GetLocalPlayerID();
  var teamID = Players.GetTeam(playerID);
  if (!args) {
    args = {
      hasSpark: {},
      cooldowns: {}
    };
  }
  var teamData = args[teamID] || {};
  teamData.gpm = teamData.gpm || 0;
  teamData.midas = teamData.midas || 0;
  teamData.power = teamData.power || 0;
  teamData.cleave = teamData.cleave || 0;

  if (!args.hasSpark[playerID]) {
    $.Msg('Forcing picking this spark');
    $('#SparkSelection').AddClass('show');
    forcedPickSpark = true;
  }

  if (currentSpark) {
    teamData[currentSpark]++;
    if (args.hasSpark[playerID]) {
      teamData[args.hasSpark[playerID]]--;
    }
  }

  var selectedSpark = currentSpark || args.hasSpark[playerID];

  Object.keys(teamData).forEach(function (value) {
    var elem = $('#' + value + 'Count');
    elem.text = teamData[value];
    if (selectedSpark === value) {
      $('#' + value + 'Panel').AddClass('active');
    } else {
      $('#' + value + 'Panel').RemoveClass('active');
    }
  });

  if (args.cooldowns[playerID] && args.cooldowns[playerID] !== '0') {
    $('#ChangeSparkCooldown').text = args.cooldowns[playerID];
    $('#SubmitSparkCooldown').text = args.cooldowns[playerID];
    $('#Finished').disabled = true;
  } else {
    $('#ChangeSparkCooldown').text = '';
    $('#SubmitSparkCooldown').text = '';
    $('#Finished').disabled = false;
  }
}

function SelectSpark (spark) {
  $.Msg(spark);

  if (Game.GetLocalPlayerID() === -1) {
    return;
  }

  if (currentSpark) {
    $('#' + currentSpark + 'Panel').RemoveClass('active');
  }
  $('#' + spark + 'Panel').AddClass('active');
  currentSpark = spark;
  ResetSparkDisplay();
}

function SparkFinished () {
  if (!forcedPickSpark || currentSpark) {
    $('#SparkSelection').RemoveClass('show');
  }

  if (currentSpark) {
    $.Msg('Selecting ' + currentSpark);
    GameEvents.SendCustomGameEventToServer('select_spark', {
      spark: currentSpark
    });
    currentSpark = null;
    forcedPickSpark = false;
  }
}

function OpenSparkSelection () {
  $('#SparkSelection').AddClass('show');
  currentSpark = null;
  forcedPickSpark = false;
  ResetSparkDisplay();
}
