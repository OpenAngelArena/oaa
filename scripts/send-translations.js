const request = require('request');
const fs = require('fs');
const parseKV = require('parse-kv');
const parseTranslation = require('./parse-translation');
const { transifexApi } = require('@transifex/api');

// setTimeout(function () { var result = {body: fs.readFileSync('./scripts/dota_english.txt', {encoding: 'utf8'})};
request.get({
  // url: 'https://raw.githubusercontent.com/spirit-bear-productions/dota_vpk_updates/main/resource/localization/dota_english.txt'
  url: 'https://raw.githubusercontent.com/spirit-bear-productions/dota_vpk_updates/main/resource/localization/abilities_english.txt'
}, async function (err, result) {
  if (err) {
    throw err;
  }
  const dotaKVs = parseKV(result.body.replace(/" and turn rate reduced by %dMODIFIER_PROPERTY_TURN_RATE_PERCENTAGE%%%\./g, ' and turn rate reduced by %dMODIFIER_PROPERTY_TURN_RATE_PERCENTAGE%%%."'));

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

  transifexApi.setup({ auth: process.env.TRANSIFEX_TOKEN });

  const organization = await transifexApi.Organization.get({ slug: 'open-angel-arena' });
  const projects = await organization.fetch('projects');
  const project = await projects.get({ slug: 'open-angel-arena' });
  const resources = await project.fetch('resources');
  const resource = await resources.get({ slug: 'addon_english' });

  await transifexApi.ResourceStringsAsyncUpload.upload({
    resource: resource,
    content: JSON.stringify(englishStrings)
  });
});
