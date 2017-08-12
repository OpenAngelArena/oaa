/* global $, CustomNetTables */

var console = {
  log: $.Msg.bind($)
};

var musicPlaying = true;
$.GetContextPanel().FindChildTraverse('ToggleMusic').AddClass('MusicOn');
CustomNetTables.SubscribeNetTableListener('music', SetMusic);
SetMusic(null, 'info', CustomNetTables.GetTableValue('music', 'info'));

function ToggleMusic () {
  if (musicPlaying) {
    musicPlaying = false;
    $.GetContextPanel().FindChildTraverse('ToggleMusic').RemoveClass('MusicOn');
    $.GetContextPanel().FindChildTraverse('ToggleMusic').AddClass('MusicOff');
    // TURN OFF MUSIC(VOLUME)
    GameEvents.SendCustomGameEventToServer('music_mute', {
      playerID: Players.GetLocalPlayer(),
      mute: 1
    });
  } else {
    musicPlaying = true;
    $.GetContextPanel().FindChildTraverse('ToggleMusic').RemoveClass('MusicOff');
    $.GetContextPanel().FindChildTraverse('ToggleMusic').AddClass('MusicOn');
    // TURN ON MUSIC(VOLUME)
    GameEvents.SendCustomGameEventToServer('music_mute', {
      playerID: Players.GetLocalPlayer(),
      mute: 0
    });
  }
}

function SetMusic (table, key, data) {
  if (key === 'info') {
    $.GetContextPanel().FindChildTraverse('MusicTitle').text = data.title;
    $.GetContextPanel().FindChildTraverse('MusicSubTitle').text = data.subtitle;
  }
}

if (typeof module !== 'undefined' && module.exports) {
  module.exports = ToggleMusic;
}
