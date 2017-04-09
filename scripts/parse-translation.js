var parseKV = require('parse-kv');
var fs = require('fs');
var path = require('path');

var basePath = path.join(__dirname, '../');

module.exports = function (shouldParse) {
  var fileData = readdir(path.join(basePath, 'game/resource/English/'));

  fileData = [
    '"lang"',
    '{',
    '"Language"      "English"',
    '"Tokens"',
    '{',
    fileData[1],
    '}',
    '}'
  ].join('\n');

  return shouldParse === false ? fileData : parseKV(fileData);

  function readdir (dir) {
    var fileList = fs.readdirSync(dir);
    var fileData = fileList.map(function (file) {
      try {
        var filePath = path.join(dir, file);
        var fileData = fs.readFileSync(filePath);
        if (fileData.toString().match(new RegExp('[^\x00-\x7F]'))) { // eslint-disable-line no-control-regex
          throw new Error(filePath.substr(basePath.length) + ' contains invalid text or bad formatting');
        }
        return [filePath, fileData];
      } catch (e) {
        if (e.code === 'EISDIR') {
          return readdir(path.join(dir, file));
        } else {
          throw e;
        }
      }
    })
    .reduce(function (memo, data) {
      var [filePath, val] = data;
      return [
        memo,
        '//---------------------------------------------------------------------------',
        '//      Generated from ' + filePath.substr(basePath.length),
        '//---------------------------------------------------------------------------',
        val
      ].join('\n');
    }, '');

    return [dir, fileData];
  }
};

if (require.main === module) {
  console.log(module.exports());
}
