const parseKV = require('parse-kv');
const request = require('request');
const test = require('tape');
const path = require('path');
const parseTranslation = require('../parse-translation');

let dotaEnglish = null;

test('before', function (t) {
  request.get({
    url: 'https://raw.githubusercontent.com/spirit-bear-productions/dota_vpk_updates/main/resource/localization/dota_english.txt'
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
  const testData = parseTranslation(true, path.join(__dirname, './fixtures/English'), dotaEnglish);
  console.log(testData.lang.Tokens);
  t.end();
});
