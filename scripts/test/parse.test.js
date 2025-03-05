const request = require('request');
const test = require('tape');
const parseKV = require('parse-kv');
const fs = require('fs');
const path = require('path');
const partial = require('ap').partial;
const parseTranslations = require('../parse-translation');

let dotaEnglish = null;

test('before', function (t) {
  request.get({
    // url: 'https://raw.githubusercontent.com/dotabuff/d2vpkr/refs/heads/master/dota/resource/localization/dota_english.txt'
    url: 'https://raw.githubusercontent.com/dotabuff/d2vpkr/refs/heads/master/dota/resource/localization/abilities_english.txt'
  }, function (err, result) {
    if (err) {
      t.fail(err);
    }
    dotaEnglish = parseKV(result.body.replace(/" and turn rate reduced by %dMODIFIER_PROPERTY_TURN_RATE_PERCENTAGE%%%\./g, ' and turn rate reduced by %dMODIFIER_PROPERTY_TURN_RATE_PERCENTAGE%%%."'));
    t.ok(dotaEnglish);
    t.end();
  });
});

test('can parse addon_english', function (t) {
  const fileData = fs.readFileSync(path.join(__dirname, '../../game/resource/addon_english.txt'), {
    encoding: 'ucs2'
  });
  t.doesNotThrow(function () { parseKV(fileData); }, 'can parse with kv');
  t.end();
});

test('can run parse script', function (t) {
  t.doesNotThrow(partial(parseTranslations, true, false, dotaEnglish));
  t.end();
});
