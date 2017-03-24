var parseKV = require('parse-kv');
var fs = require('fs');
var path = require('path');

module.exports = function () {
  var fileData = fs.readFileSync(path.join(__dirname, '../game/resource/addon_english.txt'), {
    encoding: 'ucs2'
  });
  return parseKV(fileData);
};
