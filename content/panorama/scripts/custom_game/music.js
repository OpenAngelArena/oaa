var musicPlaying = true;
$.GetContextPanel().FindChildTraverse('ToggleMusic').AddClass("MusicOn");
function ToggleMusic () {
    if (musicPlaying) {
        musicPlaying = false;
        $.GetContextPanel().FindChildTraverse('ToggleMusic').RemoveClass("MusicOn");
        $.GetContextPanel().FindChildTraverse('ToggleMusic').AddClass("MusicOff");
    } else {
        musicPlaying = true;
        $.GetContextPanel().FindChildTraverse('ToggleMusic').RemoveClass("MusicOff");
        $.GetContextPanel().FindChildTraverse('ToggleMusic').AddClass("MusicOn");
    }
}
