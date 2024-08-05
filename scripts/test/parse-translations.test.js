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
  t.same(testData.lang.Tokens.values, {
    tooltip_subsubfolder_key: 'a thing # asdf }This is a value{... also This is a value',
    case_insensitivity: 'should work',
    so_insensitive: 'should work',
    less_insensitive: 'should work',
    less_insensitive_reverse: 'should work',
    so_insensitive_reverse: 'should work',
    tooltip_subfolder_key: 'a thing # asdf }This is a value{... also This is a value',
    key_in_different_file: 'a thing # asdf }This is a value{... also This is a value',
    some_key_name: 'This is a value',
    some_other_key_name: 'also This is a value',
    some_complex_key: 'a thing # asdf }This is a value{... also This is a value',
    dota_value: 'The Radiant'
  }, 'tooltips can parse from fixture data');
  t.end();
});
