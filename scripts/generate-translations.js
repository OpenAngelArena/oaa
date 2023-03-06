const request = require('request');
const parseTranslation = require('./parse-translation');
const fs = require('fs');
const path = require('path');
const parseKV = require('parse-kv');

const languageShortNames = {
  german: 'de',
  russian: 'ru',
  chinese: 'zh',
  portuguese: 'pt',
  spanish: 'es',
  czech: 'cs',
  polish: 'pl',
  dutch: 'nl',
  hungarian: 'hu'
};

let englishData = null;
const transByValue = {};
let dotaEnglish = {};
const unchagedKeys = {};

function cleanLanguageFile (contents) {
  contents = contents
    .replace('%dMODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE%%%" and turn rate reduced by %dMODIFIER_PROPERTY_TURN_RATE_PERCENTAGE%%%.', '%dMODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE%%%\\" and turn rate reduced by %dMODIFIER_PROPERTY_TURN_RATE_PERCENTAGE%%%."')
    .replace('." and turn rate reduced by %dMODIFIER_PROPERTY_TURN_RATE_PERCENTAGE%%%.', '.\\" and turn rate reduced by %dMODIFIER_PROPERTY_TURN_RATE_PERCENTAGE%%%."')
    .replace('\t\tand turn rate reduced by %dMODIFIER_PROPERTY_TURN_RATE_PERCENTAGE%%%.', '');
  return contents;
}

request.get({
  // url: 'https://raw.githubusercontent.com/dotabuff/d2vpkr/master/dota/resource/localization/dota_english.txt'
  url: 'https://raw.githubusercontent.com/dotabuff/d2vpkr/master/dota/resource/localization/abilities_english.txt'
}, function (err, result) {
  if (err) {
    throw err;
  }
  dotaEnglish = parseKV(cleanLanguageFile(result.body));

  let englishFileString = parseTranslation(false, null, dotaEnglish);
  englishData = parseKV(englishFileString);

  getDuplicateStrings();

  Object.keys(dotaEnglish.lang.Tokens.values).forEach(function (key) {
    if (!transByValue[dotaEnglish.lang.Tokens.values[key]]) {
      transByValue[dotaEnglish.lang.Tokens.values[key]] = key.toLowerCase();
    }
  });
  Object.keys(englishData.lang.Tokens.values).forEach(function (key) {
    if (!unchagedKeys[key.toLowerCase()] && transByValue[englishData.lang.Tokens.values[key]]) {
      unchagedKeys[key.toLowerCase()] = transByValue[englishData.lang.Tokens.values[key]];
      console.log(key, 'is unchanged from', unchagedKeys[key]);
    }
  });

  englishFileString = [
    '//---------------------------------------------------------------------------',
    '// This file is generated from a script. Do not edit it directly other than for testing. Your edits will be deleted.',
    '//---------------------------------------------------------------------------',
    '',
    englishFileString
  ].join('\n');

  fs.writeFileSync(path.join(__dirname, '../game/resource/addon_english.txt'), '\ufeff' + englishFileString, {
    encoding: 'ucs2'
  });

  if (process.argv[2] || !process.env.TRANSIFEX_USER || !process.env.TRANSIFEX_PASSWORD) {
    console.log('No TRANSIFEX_USER or TRANSIFEX_PASSWORD, not generating translations (english only)');
    process.exit(0);
  } else {
    Object.keys(languageShortNames).map(generateTranslations);
  }
});

// functions

function getDuplicateStrings () {
  const foundStrings = {};
  const duplicateStrings = {};

  Object.keys(englishData.lang.Tokens.values).forEach(function (key) {
    const str = englishData.lang.Tokens.values[key];
    if (foundStrings[str]) {
      if (!duplicateStrings[foundStrings[str]]) {
        duplicateStrings[foundStrings[str]] = {
          string: str,
          keys: [key]
        };
      } else {
        duplicateStrings[foundStrings[str]].keys.push(key);
      }
      return;
    }

    foundStrings[str] = key;
  });

  return duplicateStrings;
}

function getTranslationsForLanguage (lang, cb) {
  request.get({
    url: 'http://www.transifex.com/api/2/project/open-angel-arena/resource/addon_english/translation/' + lang + '?mode=onlytranslated',
    auth: {
      user: process.env.TRANSIFEX_USER,
      pass: process.env.TRANSIFEX_PASSWORD
    },
    json: true
  }, function (err, data) {
    if (typeof data.body !== 'object') {
      console.error('Unexpected output: ', data.body);
      return cb(new Error('Unexpected output from transifex server. Check user / password'));
    }
    try {
      data = JSON.parse(data.body.content.replace('"fading if it sustains too much damage"', '\\"fading if it sustains too much damage\\"'));
    } catch (err) {
      console.error('Error parsing return value:');
      console.error('http://www.transifex.com/api/2/project/open-angel-arena/resource/addon_english/translation/' + lang + '?mode=onlytranslated');
    }
    cb(err, data);
  });
}

function getUnchangedStrings (languageName, cb) {
  if (languageName === 'chinese') {
    languageName = 'schinese';
  }
  request.get({
    // url: 'https://raw.githubusercontent.com/dotabuff/d2vpkr/master/dota/resource/localization/dota_' + languageName + '.txt'
    url: 'https://raw.githubusercontent.com/dotabuff/d2vpkr/master/dota/resource/localization/abilities_' + languageName + '.txt'
  }, function (err, result) {
    if (err) {
      console.error(languageName);
      throw err;
    }

    console.log('Parsing valves', languageName, 'translations');
    const dotaKVs = parseKV(cleanLanguageFile(result.body));

    const translatedKeys = {};
    Object.keys(dotaKVs.lang.Tokens.values).forEach(function (key) {
      dotaKVs.lang.Tokens.values[key.toLowerCase()] = dotaKVs.lang.Tokens.values[key];
    });
    Object.keys(unchagedKeys).forEach(function (key) {
      if (dotaKVs.lang.Tokens.values[unchagedKeys[key]]) {
        translatedKeys[key] = dotaKVs.lang.Tokens.values[unchagedKeys[key]];
      } else {
        console.log(languageName, 'No unchaged value for', key, unchagedKeys[key]);
      }
    });
    cb(translatedKeys);
  });
}

function generateFileForTranslations (languageName, translations, cb) {
  const duplicateStrings = getDuplicateStrings();
  getUnchangedStrings(languageName, function (translatedKeys) {
    const lines = [];
    lines.push('"lang"');
    lines.push('{');
    lines.push('  "Language"      "' + languageName + '"');
    lines.push('  "Tokens"');
    lines.push('  {');
    lines.push('    //==================================================================================');
    lines.push('    // This file is auto-generated, do not edit it directly. Your changes will be lost.');
    lines.push('    //==================================================================================');
    lines.push();

    Object.keys(translatedKeys).map(function (key) {
      const indent = (new Array(100 - key.length)).join(' ');
      lines.push('    ' + JSON.stringify(key) + indent + JSON.stringify(translatedKeys[key]));
      return key;
    });

    Object.keys(translations).forEach(function (key) {
      if (!translations[key].length) {
        return;
      }
      if (duplicateStrings[key]) {
        lines.push();
      }
      const indent = (new Array(100 - key.length)).join(' ');
      lines.push('    ' + JSON.stringify(key) + indent + JSON.stringify(translations[key]));

      if (duplicateStrings[key]) {
        duplicateStrings[key].keys.forEach(function (dupKey) {
          const indent = (new Array(100 - dupKey.length)).join(' ');
          lines.push('    ' + JSON.stringify(dupKey) + indent + JSON.stringify(translations[key]));
        });
      }
    });
    // done
    lines.push('  }');
    lines.push('}');
    lines.push('');

    cb(lines);
  });
}

function generateTranslations (lang) {
  getTranslationsForLanguage(languageShortNames[lang], function (err, data) {
    if (err) {
      throw err;
    }

    if (data.workshop_description) {
      fs.writeFileSync(path.join(__dirname, '../workshop/', lang + '.txt'), data.workshop_description, {
        encoding: 'utf8'
      });
      delete data.workshop_description;
    }

    // translations
    generateFileForTranslations(lang, data, function (lines) {
      fs.writeFileSync(path.join(__dirname, '../game/resource/addon_' + lang + '.txt'), '\ufeff' + lines.join('\n'), {
        encoding: 'ucs2'
      });
    });
  });
}
