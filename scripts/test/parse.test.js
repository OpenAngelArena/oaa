var test = require('tape');
var parseKV = require('parse-kv');
var fs = require('fs');
var path = require('path');
var parseTranslations = require('../parse-translation');

test('can parse addon_english', function (t) {
  var fileData = fs.readFileSync(path.join(__dirname, '../../game/resource/addon_english.txt'), {
    encoding: 'ucs2'
  });
  t.doesNotThrow(function () { parseKV(fileData); }, 'can parse with kv');
  t.end();
});

test('can run parse script', function (t) {
  t.doesNotThrow(parseTranslations);
  t.end();
});
