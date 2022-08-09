/* global CustomNetTables $ FindDotaHudElement  */
const topBar = FindDotaHudElement('topbar');
let extraInfo = FindDotaHudElement('ExtraInfo');
let killLimit = FindDotaHudElement('KillLimitValue');
let nextDuel = FindDotaHudElement('TimeToNextDuelValue');
let nextCapture = FindDotaHudElement('TimeToNextCaptureValue');

if (extraInfo.GetParent().id !== 'topbar') {
  extraInfo.SetParent(topBar);
  extraInfo = null;
  killLimit = null;
  nextDuel = null;
  nextCapture = null;
}

(function () {
  CustomNetTables.SubscribeNetTableListener('timer', UpdateClock);
  UpdateClock(null, 'data', CustomNetTables.GetTableValue('timer', 'data'));
}());

function UpdateClock (table, name, data) {
  if (!data || data.time === undefined) {
    return;
  }
  if (killLimit === null) {
    killLimit = FindDotaHudElement('KillLimitValue');
  }
  if (nextDuel === null) {
    nextDuel = FindDotaHudElement('TimeToNextDuelValue');
  }
  if (nextCapture === null) {
    nextCapture = FindDotaHudElement('TimeToNextCaptureValue');
  }

  killLimit.text = data.killLimit;
  nextDuel.text = formatTime(data.timeToNextDuel);
  nextCapture.text = formatTime(data.timeToNextCapture);

  $('#TimeHider').style.visibility = 'visible';
  $('#GameTime').text = formatTime(data.time);
  const dayTime = $('#DayTime');
  const nightTime = $('#NightTime');
  const nightstalkerNight = $('#NightstalkerNight');
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
  let seconds = time % 60;
  if (seconds >= 0) {
    return [Math.floor(time / 60), seconds < 10 ? '0' + seconds : seconds].join(':');
  } else {
    seconds = Math.abs(seconds);
    return ['-' + Math.abs(Math.ceil(time / 60)), seconds < 10 ? '0' + seconds : seconds].join(':');
  }
}
