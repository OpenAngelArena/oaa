const request = require('request');
const parseTranslation = require('./parse-translation');
const fs = require('fs');
const path = require('path');
const parseKV = require('parse-kv');
const { transifexApi } = require('@transifex/api');

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
  // url: 'https://raw.githubusercontent.com/dotabuff/d2vpkr/refs/heads/master/dota/resource/localization/dota_english.txt'
  url: 'https://raw.githubusercontent.com/dotabuff/d2vpkr/refs/heads/master/dota/resource/localization/abilities_english.txt'
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

  if (process.argv[2] || !process.env.TRANSIFEX_TOKEN) {
    console.log('No TRANSIFEX_TOKEN, not generating translations (english only)');
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

async function getTranslationsForLanguage (lang, cb) {
  transifexApi.setup({ auth: process.env.TRANSIFEX_TOKEN });

  const organization = await transifexApi.Organization.get({ slug: 'open-angel-arena' });
  const projects = await organization.fetch('projects');
  const project = await projects.get({ slug: 'open-angel-arena' });
  const language = await transifexApi.Language.get({ code: lang });
  const resources = await project.fetch('resources');
  const resource = await resources.get({ slug: 'addon_english' });
  const url = await transifexApi.ResourceTranslationsAsyncDownload.download({
    resource,
    language
  });

  console.log('Fetching translation data for', lang);
  request.get({
    url,
    json: true
  }, function (err, data) {
    if (err) {
      return cb(err);
    }
    data = data.body;
    console.log('Done translation data for', lang);
    cb(err, data);
  });
}

function getUnchangedStrings (languageName, cb) {
  if (languageName === 'chinese') {
    languageName = 'schinese';
  }
  console.log('Fetching dota tooltips for', languageName);
  request.get({
    // url: 'https://raw.githubusercontent.com/dotabuff/d2vpkr/refs/heads/master/dota/resource/localization/dota_' + languageName + '.txt'
    url: 'https://raw.githubusercontent.com/dotabuff/d2vpkr/refs/heads/master/dota/resource/localization/abilities_' + languageName + '.txt'
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
    console.log('Done fetching dota tooltips for', languageName);

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
    console.log('Generating ', lang);
    generateFileForTranslations(lang, data, function (lines) {
      console.log('Writing ', lang);
      fs.writeFileSync(path.join(__dirname, '../game/resource/addon_' + lang + '.txt'), '\ufeff' + lines.join('\n'), {
        encoding: 'ucs2'
      });
      console.log('Finished with ', lang);
    });
  });
}
