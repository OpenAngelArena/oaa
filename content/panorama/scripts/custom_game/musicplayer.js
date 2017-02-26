/*
  Author:
    Relacibo
*/
'use strict';

var console = {
  log: $.Msg.bind($)
};
var container = $.GetContextPanel();
var display = $.GetContextPanel().FindChildTraverse('MusicPlayer_Display');

(function () {
  PlayerTables.SubscribeNetTableListener('musicplayer_music', onMusicChange);
}());

function onToggleMusic() {
  container.ToggleClass('MusicToggledOn');
  GameEvents.SendEventClientSide ('musicplayer_toggle', { });
}

function setMusicStatus(on) {
  if (on) {
    container.AddClass('MusicToggledOn');
  } else {
    container.RemoveClass('MusicToggledOn');
  }
}

function onMusicChange( table, data ) {
  var isMusicOn = data.isMusicOn;
  var musicOn = isMusicOn == 1;
  if (musicOn) {
    var musicTitle = data.musicTitle;
    var musicArtist = data.musicArtist;
    var title = display.FindChild('Title');
    var artist = display.FindChild('Artist');

    title.text = musicTitle;
    artist.text = musicArtist;
  }

  // Sets musicpanel to the right status
  if (musicOn ^ container.BHasClass('MusicToggledOn')) {
      setMusicStatus(musicOn);
  }
}