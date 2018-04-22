'use strict';

var isRunning = false;
var timeout;
var returnEventName;

(function () {
  GameEvents.Subscribe('show_yes_no_poll', Open);
}());

function Open (data) {
  if (!isRunning &&
    data != null &&
    data.returnEventName != null &&
    data.pollText != null &&
    data.pollTimeout != null) {
      isRunning = true;
      returnEventName = data.returnEventName;
      $('#YesNoPollPanel').SetHasClass('Show', true);
      $('#YesNoPollText').text = data.pollText;
      timeout = data.pollTimeout;
      ScheduleSetTime(timeout);
  }
}

function ScheduleSetTime (time) {
  $('#YesNoPollTime').text = time;
  $.Schedule(1, SetTime);
}

function SetTime () {
  --timeout;
  if (timeout == 0) {
    No();
  } else if (isRunning) {
    ScheduleSetTime(timeout);
  }
}

function Yes () {
  SendResult(1);
}

function No () {
  SendResult(0);
}

function SendResult (result) {
  if (isRunning) { // you can get here if the timer has run out
    $('#YesNoPollPanel').SetHasClass('Show', false);
    GameEvents.SendCustomGameEventToServer(returnEventName, {
      result: result
    });

    isRunning = false;
  }
}
