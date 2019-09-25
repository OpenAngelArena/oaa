var forcedPickSpark = false;
var currentSpark = null;

(function () {
  CustomNetTables.SubscribeNetTableListener('hero_selection', SparkSelection);
  ResetSparkDisplay();
})();

function ResetSparkDisplay () {
  SparkSelection(null, 'team_sparks', CustomNetTables.GetTableValue('hero_selection', 'team_sparks'));
}

function SparkSelection (table, key, args) {
  if (key !== 'team_sparks') {
    return;
  }
  var playerID = Game.GetLocalPlayerID();
  var teamID = Players.GetTeam(playerID);
  $.Msg(key);
  if (!args) {
    args = {
      hasSpark: {}
    };
  }
  var teamData = args[teamID] || {};
  teamData.gpm = teamData.gpm || 0;
  teamData.midas = teamData.midas || 0;
  teamData.power = teamData.power || 0;
  teamData.cleave = teamData.cleave || 0;

  if (!args.hasSpark[playerID]) {
    $.Msg('Forcing picking this spark');
    $("#SparkSelection").AddClass('show');
    forcedPickSpark = true;
  }

  if (currentSpark) {
    teamData[currentSpark]++;
    if (args.hasSpark[playerID]) {
      teamData[args.hasSpark[playerID]]--;
    }
  }
  $.Msg(teamData);

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
}

function SelectSpark (spark) {
  $.Msg(spark);

  if (currentSpark) {
    $('#' + currentSpark + 'Panel').RemoveClass('active');
  }
  $('#' + spark + 'Panel').AddClass('active');
  currentSpark = spark;
  ResetSparkDisplay();
}

function SparkFinished () {
  if (!forcedPickSpark || currentSpark) {
    $("#SparkSelection").RemoveClass('show');
  }

  if (currentSpark) {
    $.Msg('Selecting ' + currentSpark)
    GameEvents.SendCustomGameEventToServer('select_spark', {
      spark: currentSpark
    });
    currentSpark = null;
    forcedPickSpark = false;
  }
}

function OpenSparkSelection () {
  $("#SparkSelection").AddClass('show');
  currentSpark = null;
  forcedPickSpark = false;
  ResetSparkDisplay();
}
