const request = require('request');
const fs = require('fs');
const parseKV = require('parse-kv');
const parseTranslation = require('./parse-translation');

// setTimeout(function () { var result = {body: fs.readFileSync('./scripts/dota_english.txt', {encoding: 'utf8'})};
request.get({
  // url: 'https://raw.githubusercontent.com/SteamDatabase/GameTracking-Dota2/master/game/dota/resource/dota_english.txt'
  url: 'https://raw.githubusercontent.com/SteamDatabase/GameTracking-Dota2/master/game/dota/pak01_dir/resource/localization/abilities_english.txt'
}, function (err, result) {
  if (err) {
    throw err;
  }
  const dotaKVs = parseKV(result.body);

  const data = parseTranslation(true, null, dotaKVs);

  const englishStrings = {};
  const foundStrings = {};

  Object.keys(data.lang.Tokens.values).forEach(function (key) {
    const str = data.lang.Tokens.values[key];
    if (foundStrings[str]) {
      console.log('Deduplicating', key);
      return;
    }

    foundStrings[str] = key;
    englishStrings[key.toLowerCase()] = str;
  });

  const transByValue = {};
  Object.keys(dotaKVs.lang.Tokens.values).forEach(function (key) {
    if (!transByValue[dotaKVs.lang.Tokens.values[key]]) {
      transByValue[dotaKVs.lang.Tokens.values[key]] = key;
    }
  });
  Object.keys(englishStrings).forEach(function (key) {
    if (transByValue[englishStrings[key]]) {
      console.log(key, 'is unchanged from', transByValue[englishStrings[key]]);
      delete englishStrings[key];
    }
  });

  englishStrings.workshop_description = fs.readFileSync('./workshop/english.txt', {
    encoding: 'utf8'
  });

  // fs.writeFileSync('./i18n.json', JSON.stringify(englishStrings, null, 2));
  // curl -i -L --user username:password -F file=@path_to_the_file -X PUT http://www.transifex.com/api/2/project/documentation/resource/api_doc/content/
  request.put({
    url: 'https://www.transifex.com/api/2/project/open-angel-arena/resource/addon_english/content/',
    auth: {
      user: process.env.TRANSIFEX_USER,
      pass: process.env.TRANSIFEX_PASSWORD
    },
    json: true,
    body: {
      content: JSON.stringify(englishStrings)
    }
  }, function (err, data) {
    if (err) {
      console.log(englishStrings);
      throw err;
    }
    console.log(data.body);
  });
});
