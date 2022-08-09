const parseKV = require('parse-kv');
const fs = require('fs');
const path = require('path');

const basePath = path.join(__dirname, '../');
let SPACE_PADDING = '                                                         ';
const filenameByKey = {};

function checkReplaceTokens (allTooltips, key, recursionCheck, source) {
  key = key.toLowerCase();
  recursionCheck = recursionCheck || {};
  if (recursionCheck[key]) {
    console.error(recursionCheck);
    throw new Error('Found recursive key: ' + key);
  }
  recursionCheck[key] = recursionCheck[key] || 0;

  let value = allTooltips[key];
  const tokens = value.match(/#{[_\- A-Za-z0-9]+}/g); // alphanumeric, _- and space
  if (!tokens) {
    return value;
  }
  recursionCheck[key]++;

  tokens.forEach(function (token) {
    const tokenKey = token.substr(2, token.length - 3).toLowerCase();
    if (!allTooltips[tokenKey]) {
      throw new Error([
        'References invalid token name, ',
        tokenKey,
        ', in ',
        source || '',
        ':',
        key
      ].join(''));
    }
    value = value.replace(token, checkReplaceTokens(allTooltips, tokenKey, recursionCheck));
  });
  recursionCheck[key]--;

  return value;
}

function generateTooltips (fileData, allTooltips) {
  return Object.keys(fileData).map(function (fileName) {
    const tooltipData = fileData[fileName];
    return [
      '//---------------------------------------------------------------------------',
      '//      Generated from ' + fileName,
      '//---------------------------------------------------------------------------',
      Object.keys(tooltipData)
        .map(function (key) {
          key = key.toLowerCase();
          while (key.length + 5 > SPACE_PADDING.length) {
            SPACE_PADDING += '             ';
          }
          return ('"' + key + '"' + SPACE_PADDING).substring(0, SPACE_PADDING.length) + JSON.stringify(allTooltips[key]);
        }).join('\n')
    ].join('\n');
  }).join('\n');
}

module.exports = function (shouldParse, languageFolder, dotaLanguage) {
  languageFolder = languageFolder || path.join(basePath, 'game/resource/English/');
  let fileData = readdir(languageFolder);

  const allTooltips = {};

  if (dotaLanguage) {
    Object.keys(dotaLanguage.lang.Tokens.values).forEach(function (key) {
      allTooltips[key.toLowerCase()] = dotaLanguage.lang.Tokens.values[key].replace(/\\n/g, '\n');
    });
  }

  // read EVERYTHING first so that order doesn't matter...
  Object.keys(fileData).forEach(function (fileName) {
    const tooltipData = fileData[fileName];
    Object.keys(tooltipData).forEach(function (key) {
      allTooltips[key.toLowerCase()] = tooltipData[key];
      filenameByKey[key.toLowerCase()] = fileName;
    });
  });
  // then populate tokens
  Object.keys(fileData).forEach(function (fileName) {
    const tooltipData = fileData[fileName];
    Object.keys(tooltipData).forEach(function (key) {
      key = key.toLowerCase();
      allTooltips[key] = checkReplaceTokens(allTooltips, key);
    });
  });

  fileData = [
    '"lang"',
    '{',
    '"Language"      "English"',
    '"Tokens"',
    '{',
    generateTooltips(fileData, allTooltips),
    '}',
    '}'
  ].join('\n');

  return shouldParse === false ? fileData : parseKV(fileData);

  function readdir (dir) {
    const fileList = fs.readdirSync(dir);
    const fileData = fileList.map(function (file) {
      try {
        const filePath = path.join(dir, file);
        const fileData = fs.readFileSync(filePath);
        if (fileData.toString().match(new RegExp('[^\x00-\x7F]'))) { // eslint-disable-line
          throw new Error(filePath.substr(basePath.length) + ' contains invalid text or bad formatting');
        }
        return [filePath, fileData];
      } catch (e) {
        if (e.code === 'EISDIR') {
          return readdir(path.join(dir, file));
        } else {
          throw e;
        }
      }
    })
      .reduce(function (memo, data) {
        if (Array.isArray(data)) {
          let [filePath, val] = data;
          if (filePath.startsWith(basePath)) {
            filePath = filePath.substr(basePath.length);
          }
          memo[filePath] = parseKV(val).values;
          Object.keys(memo[filePath]).forEach(function (key) {
            memo[filePath][key] = memo[filePath][key].replace(/\\n/g, '\n');
          });
        } else {
        // nested folder
          Object.keys(data).forEach(function (key) {
            memo[key] = data[key];
          });
        }
        return memo;
      }, {});

    return fileData;
  }
};

if (require.main === module) {
  console.log(module.exports());
}
