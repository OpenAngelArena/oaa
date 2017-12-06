/* global CustomNetTables */

(function () {
  CustomNetTables.SubscribeNetTableListener('timer', UpdateClock);
  UpdateClock(null, 'data', CustomNetTables.GetTableValue('timer', 'data'));
}());

function UpdateClock (table, name, data) {
  if (!data || data.time === undefined) {
    return;
  }
  $('#TimeHider').style.visibility = 'visible';

  $('#GameTime').text = formatTime(data.time);
  var dayTime = $('#DayTime');
  var nightTime = $('#NightTime');
  var nightstalkerNight = $('#NightstalkerNight');
  dayTime.style.visibility = 'collapse';
  nightTime.style.visibility = 'collapse';
  nightstalkerNight.style.visibility = 'collapse';
  if (data.isDay) {
    dayTime.style.visibility = 'visible';
  } else if (data.isNightstalker) {
    nightstalkerNight.style.visibility = 'visible';
  } else {
    nightTime.style.visibility = 'visible';
  }
}

function formatTime (time) {
  var seconds = time % 60;
  if (seconds >= 0) {
    return [Math.floor(time / 60), seconds < 10 ? '0' + seconds : seconds].join(':');
  } else {
    seconds = Math.abs(seconds);
    return ['-' + Math.floor(time / 60), seconds < 10 ? '0' + seconds : seconds].join(':');
  }
}
