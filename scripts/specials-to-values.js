const fs = require('fs');
const path = require('path');
const chalk = require('chalk');
const readline = require('readline');

const walk = function (directoryName, action) {
  fs.readdir(directoryName, function (err, files) {
    if (err) {
      console.error(chalk.red(err));
      return;
    }
    files.forEach(function (file) {
      const fullPath = path.join(directoryName, file);
      fs.stat(fullPath, function (err, f) {
        if (err) {
          console.error(chalk.red(err));
          return;
        }
        if (f.isDirectory()) {
          walk(fullPath, action);
        } else {
          action(fullPath);
        }
      });
    });
  });
};

function specialsToValues (file) {
  if (file.indexOf('.md') > -1) {
    return;
  }

  // console.log('Doing ' + chalk.green(file));

  const lineReader = readline.createInterface({
    input: fs.createReadStream(file)
  });

  let result = '';
  let before = '';
  lineReader.on('line', (line) => {
    before += line + '\r\n';

    line = line.replace(/.*"var_type".*/, '');

    line = line.replace('AbilitySpecial', 'AbilityValues');

    result += line + '\r\n';
    result = result.replace(/^(\s*\r\n){2,}/, '');
  });

  lineReader.on('close', () => {
    if (!checkEqual(before, result)) {
      fs.writeFile(file, result, { encoding: 'utf8' }, function (err) {
        if (err) {
          return console.error(chalk.red(err));
        }
        console.log('Done ' + chalk.green(file));
      });
    }
  });
}

function checkEqual (s1, s2) {
  if (s1 === s2) {
    return true;
  } else {
    return s1.replace(/[^a-zA-Z0-9 "{}]/g, '') === s2.replace(/[^a-zA-Z0-9 "{}]/g, '');
  }
}

walk('game/scripts/npc', specialsToValues);
