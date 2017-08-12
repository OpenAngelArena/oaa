var musicPlaying = true;
$.GetContextPanel().FindChildTraverse('ToggleMusic').AddClass('MusicOn');
CustomNetTables.SubscribeNetTableListener('info', SetMusic);


function ToggleMusic() {
  if (musicPlaying) {
    musicPlaying = false;
    $.GetContextPanel().FindChildTraverse('ToggleMusic').RemoveClass('MusicOn');
    $.GetContextPanel().FindChildTraverse('ToggleMusic').AddClass('MusicOff');
    //TURN OFF MUSIC(VOLUME)
  } else {
    musicPlaying = true;
    $.GetContextPanel().FindChildTraverse('ToggleMusic').RemoveClass('MusicOff');
    $.GetContextPanel().FindChildTraverse('ToggleMusic').AddClass('MusicOn');
    //TURN ON MUSIC(VOLUME)
  }
}

// TESTED, data format is set as followed
// CustomNetTables:SetTableValue("info", "music", { title = "XD", subtitle = "XDD" })
function SetMusic(table, key, data) {
  if (key == 'music');
  $.GetContextPanel().FindChildTraverse('MusicTitle').text = data.title;
  $.GetContextPanel().FindChildTraverse('MusicSubTitle').text = data.subtitle;
}
