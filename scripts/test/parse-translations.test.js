const parseKV = require('parse-kv');
const request = require('request');
const test = require('tape');
const path = require('path');
const parseTranslation = require('../parse-translation');

let dotaEnglish = null;

test('before', function (t) {
  request.get({
    url: 'https://raw.githubusercontent.com/SteamDatabase/GameTracking-Dota2/master/game/dota/resource/dota_english.txt'
    // url: 'https://raw.githubusercontent.com/SteamDatabase/GameTracking-Dota2/master/game/dota/pak01_dir/resource/localization/abilities_english.txt'
  }, function (err, result) {
    if (err) {
      t.fail(err);
    }
    dotaEnglish = parseKV(result.body);
    t.ok(dotaEnglish);
    t.end();
  });
});

test('parse translations', function (t) {
  var testData = parseTranslation(true, path.join(__dirname, './fixtures/English'), dotaEnglish);
  console.log(testData.lang.Tokens);
  t.end();
});
