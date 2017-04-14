/**
 * This script checks for diff on abilitiy stats between OAA and original dota.
 * 
 * Requirements: `deep-diff` from npm
 *
 * Usage: node diff-abilities.js
 *
 * Currently this uses a local copy of the KV file from here:
 * https://raw.githubusercontent.com/dotabuff/d2vpkr/master/dota/scripts/npc/npc_abilities.txt
 *
 * This file is not well-formatted!
 * There are two lines which should be a comment, but they are only containing 
 * one slash.
 * Use: `ag '\t\/ Damage.' npc_abilities.txt`
 * To find this lines. (5565, 5623)
 *
 * TODO; get files from url above instead of manual download
 * TODO: automatic fix of ill-formatted lines using a regex
 * TODO: update files in OAA directory
 *
 */
var parseKV = require('parse-kv');
var fs = require('fs');
var path = require('path');
var diff = require('deep-diff').diff;

// root dir of OAA.
const basePath = path.join(__dirname, '../');
// path in the OAA repo, relative to the root.
const abilitiesPath = path.join(basePath, 'game', 'scripts', 'npc', 'abilities');
// regex for removing file extension of KV files.
const fileExtRegex = /.txt/g;

const filteredElements = ['MaxLevel', 'RequiredLevel', 'LevelsBetweenUpgrades'];

/**
 * Check, of this diff-element should be ignored, since OAA is not using this
 * property.
 */
function isOriginalDotaOnly(element) {

  if(element[path]) {

    return !filteredElements.includes(element['path'][1]);
  }
  return true;
}

/**
 * Print the diff for one abilitiy.
 * This method should write the changes to OAA files.
 */
function printDifferences(diff, abilityName) {

  diff = diff.filter(isOriginalDotaOnly);

  // rename keys to be more readable
  // TODO remove this, if we have have a good way to replace values
  // and generate a valid (merged) KV
  diff = JSON.parse(JSON.stringify(diff).split('rhs').join('dotaStats'));
  diff = JSON.parse(JSON.stringify(diff).split('lhs').join('oaaStats'));

  console.log('=====================');
  console.log(' Diff for: ' + abilityName);
  console.log('=====================');
  console.log(JSON.stringify(diff));
  console.log();
}

/**
 * Parse the original dota file.
 */
function parseOriginal(err, origContent) {

  if (err) {
    throw err;
  }

  // Parsed KV data from original dota
  var origKVData = parseKV(origContent);

  var abilityList = Object.keys(origKVData['DOTAAbilities']);

  // Walk the directory with files for all abilities in OAA
  fs.readdir(abilitiesPath, 'utf8', (err, files) => {

    files.forEach((file) => {

      // Absolute path of the current KV file
      var absoluteKVFilePath = path.join(abilitiesPath, file);
      // Name of the current abilitiy
      var abilityName = file.replace(fileExtRegex, '');

      // If the current file has no corresponding section in the original dota
      // KV file, skip
      if(!abilityList.includes(abilityName)) {
        return;
      }

      // Read one file in the OAA directory.
      fs.readFile(absoluteKVFilePath, (err, oaaContent) => {

        var oaaKVData = parseKV(oaaContent);

        var oaaAbil = oaaKVData['DOTAAbilities'][abilityName];
        var origAbil = origKVData['DOTAAbilities'][abilityName];

        // do a diff on the two abilities.
        var differences = diff(oaaAbil, origAbil);

        // If there are differences, print them
        if(differences) {
          printDifferences(differences, abilityName);
        }
      });
    });
  });
}

fs.readFile(path.join('npc_abilities.txt'), 'utf8', parseOriginal);
