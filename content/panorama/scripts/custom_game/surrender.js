/* global GameEvents, $ */

'use strict';

var isRunning = false;
var timeout;
var returnEventName;

GameEvents.Subscribe('show_yes_no_poll', Open);
GameEvents.Subscribe('surrender_visbility_changed', UpdateVisibility);

function Open (data) {
  if (!isRunning && data != null && data.returnEventName != null && data.pollText != null && data.pollTimeout != null) {
    isRunning = true;
    returnEventName = data.returnEventName;
    $('#SurrenderGG').SetHasClass('Show', true);
    timeout = data.pollTimeout;
    ScheduleSetTime(timeout);
  }
}

function UpdateVisibility (data) {
  if (!isRunning && data != null && data.visible != null) {
    $('#SurrenderBtn').SetHasClass('Show', data.visible === 1);
  }
}

function ScheduleSetTime (time) {
  $('#Time').visible = true;
  $('#Time').text = time;
  $.Schedule(1, SetTime);
}

function SetTime () {
  --timeout;
  if (timeout === 0) {
    SelectNo();
  } else if (isRunning) {
    ScheduleSetTime(timeout);
  }
}

function SelectYes () { // eslint-disable-line no-unused-vars
  SendResult(1);
}

function SelectNo () {
  SendResult(0);
}

function SendResult (result) {
  if (isRunning) { // you can get here if the timer has run out
    $('#SurrenderGG').SetHasClass('Show', false);
    GameEvents.SendCustomGameEventToServer(returnEventName, {
      result: result
    });

    isRunning = false;
  }
}

function StartSurrenderVote () { // eslint-disable-line no-unused-vars
  GameEvents.SendCustomGameEventToServer('surrender_start_vote', {});
}
