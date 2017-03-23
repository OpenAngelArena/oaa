var parseKV = require('parse-kv');
var fs = require('fs');
var path = require('path');
var Transifex = require('transifex');
var request = require('request');

var fileData = fs.readFileSync(path.join(__dirname, '../game/resource/addon_english.txt'), {
  encoding: 'ucs2'
});
var data = parseKV(fileData);

var englishStrings = {};
var foundStrings = {};

Object.keys(data.lang.Tokens.values).forEach(function (key) {
  var str = data.lang.Tokens.values[key];
  if (foundStrings[str]) {
    console.log('Deduplicating', key);
    return;
  }

  foundStrings[str] = key;
  englishStrings[key] = str;
});

// fs.writeFileSync('./i18n.json', JSON.stringify(englishStrings, null, 2));
// curl -i -L --user username:password -F file=@path_to_the_file -X PUT http://www.transifex.com/api/2/project/documentation/resource/api_doc/content/
request.put({
  url: 'http://www.transifex.com/api/2/project/open-angel-arena/resource/addon_english/content/',
  auth: {
    user: process.env.TRANSIFEX_USER,
    pass: process.env.TRANSIFEX_PASSWORD
  },
  json: true,
  body: {
    content: JSON.stringify(englishStrings)
  }
}, function (err, data) {
  console.log(err, data.body);
});
