/* global Players $ GameEvents CustomNetTables Game */

var musicPlaying = true;
$.GetContextPanel().FindChildTraverse('ToggleMusic').AddClass('MusicOn');
CustomNetTables.SubscribeNetTableListener('music', SetMusic);
SetMusic(null, 'info', CustomNetTables.GetTableValue('music', 'info'));
SetMute(CustomNetTables.GetTableValue('music', 'mute'));

$.GetContextPanel().SetHasClass('TenVTen', Game.GetMapInfo().map_display_name === 'oaa_10v10');

function ToggleMusic () {
  if (musicPlaying) {
    musicPlaying = false;
    // TURN OFF MUSIC(VOLUME)
    $.GetContextPanel().FindChildTraverse('ToggleMusic').RemoveClass('MusicOn');
    $.GetContextPanel().FindChildTraverse('ToggleMusic').AddClass('MusicOff');
    GameEvents.SendCustomGameEventToServer('music_mute', {
      mute: 1
    });
  } else {
    musicPlaying = true;
    // TURN ON MUSIC(VOLUME)
    $.GetContextPanel().FindChildTraverse('ToggleMusic').RemoveClass('MusicOff');
    $.GetContextPanel().FindChildTraverse('ToggleMusic').AddClass('MusicOn');
    GameEvents.SendCustomGameEventToServer('music_mute', {
      mute: 0
    });
  }
}

function SetMusic (table, key, data) {
  if (key === 'info') {
    $.GetContextPanel().FindChildTraverse('MusicTitle').text = data.title;
    $.GetContextPanel().FindChildTraverse('MusicSubTitle').text = 'by ' + data.subtitle;
  }
}

if (typeof module !== 'undefined' && module.exports) {
  module.exports = ToggleMusic;
}

function SetMute (data) {
  var mute = data[Players.GetLocalPlayer()];
  if (!mute || mute === 1) {
    return;
  }
  musicPlaying = false;
  $.GetContextPanel().FindChildTraverse('ToggleMusic').RemoveClass('MusicOn');
  $.GetContextPanel().FindChildTraverse('ToggleMusic').AddClass('MusicOff');
}
