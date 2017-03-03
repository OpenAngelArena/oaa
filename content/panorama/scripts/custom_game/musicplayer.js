/*
 *  Author:
 *    Relacibo
 */
'use strict';

var console = {
  log: $.Msg.bind($)
};
var container = $.GetContextPanel();
var display = $.GetContextPanel().FindChildTraverse('MusicPlayer_Display');

(function () {
  CustomNetTables.SubscribeNetTableListener('musicplayer', onMusicTableChange);
}());

function onToggleMusic() {
  container.ToggleClass('MusicToggledOn');
  GameEvents.SendCustomGameEventToServer('musicplayer_toggle', { });
}

function setMusicStatus(on) {
  if (on) {
    container.AddClass('MusicToggledOn');
  } else {
    container.RemoveClass('MusicToggledOn');
  }
}

function onMusicTableChange( tableName, key, data ) {
  // var playerID = Game.GetLocalPlayerID()
  var isMusicOn = data.musicOn;
  if (isMusicOn) {
    var musicTitle = data.title;
    var musicArtist = data.artist;
    var title = display.FindChild('Title');
    var artist = display.FindChild('Artist');

    title.text = musicTitle;
    artist.text = musicArtist;
  }

  // Sets musicpanel to the right status
  if (isMusicOn ^ container.BHasClass('MusicToggledOn')) {
      setMusicStatus(isMusicOn);
  }
}
