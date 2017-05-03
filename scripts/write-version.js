const fs = require('fs');
var pjson = require('./package.json');

const addonGameMode = './game/scripts/vscripts/addon_game_mode.lua';

fs.readFile(addonGameMode, (err, data) => {
  if (err) return console.log(err);
  var result = data.replace(/GAME_VERSION = "\d+.\d+.\d+"/g, 'GAME_VERSION = "' + pjson.version + '"');

  fs.writeFile(addonGameMode, result, 'utf8', function (err) {
    if (err) return console.log(err);
  });
});
