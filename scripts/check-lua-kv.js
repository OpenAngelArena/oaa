const parseKV = require('parse-kv');
const chalk = require('chalk');
const path = require('path');
const fs = require('fs');
const readline = require('readline');

const walk = (directoryName, action) => {
  fs.readdir(directoryName, (err, files) => {
    if (err) {
      console.error(chalk.red(err));
      return;
    }
    files.forEach((file) => {
      const fullPath = path.join(directoryName, file);
      fs.stat(fullPath, (err, f) => {
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

function checkLuaItemFile (path) {
  // console.log(chalk.blue('Checking "' + path + '".'));
  const data = parseKV(fs.readFileSync(path)).DOTAItems;
  for (const item in data) {
    if (item === 'values') {
      continue;
    }

    if (data[item].values.BaseClass === undefined) {
      console.error(chalk.yellow('WARN') + ' Missing Key: "' + chalk.bold('BaseClass') + '"\n  in Item "' + chalk.bold(item) + '"\n    in Path "' + chalk.bold(path) + '"\n');
      continue;
    }

    if (data[item].values.BaseClass !== 'item_lua') {
      continue;
    }

    if (data[item].values.BaseClass === undefined) {
      console.error(chalk.red('ERR') + ' Missing Key: "' + chalk.bold('ScriptFile') + '"\n  in Item "' + chalk.bold(item) + '"\n    in Path "' + chalk.bold(path) + '"\n');
      continue;
    }

    if (data[item].AbilitySpecial === undefined) {
      console.error(chalk.yellow('WARN') + ' Missing Key: "' + chalk.bold('SpecialValues') + '"\n  in Item "' + chalk.bold(item) + '"\n    in Path "' + chalk.bold(path) + '"\n');
    }

    const ScriptFilePath = 'game/scripts/vscripts/' + data[item].values.ScriptFile;

    fs.stat(ScriptFilePath, (err, stat) => {
      if (err === null) {
        // console.log(chalk.blue('-> Checking "' + ScriptFilePath + '".'));

        const lineReader = readline.createInterface({
          input: fs.createReadStream(ScriptFilePath)
        });

        let lineNumber = 0;
        lineReader.on('line', (line) => {
          lineNumber++;
          const SpecialValueRegex = /GetSpecialValueFor\(\s*"[^"]+"\s*\)/;
          const SpecialValueMatches = line.match(SpecialValueRegex);

          if (SpecialValueMatches) {
            const start = SpecialValueMatches[0].indexOf('"') + 1;
            const SpecialValueKey = SpecialValueMatches[0].slice(start, SpecialValueMatches[0].indexOf('"', start));

            if (data[item].AbilitySpecial === undefined) {
              console.error(chalk.red('ERR') + ' Trying to access Value ' + chalk.bold(SpecialValueKey) + ' of non existing Key: "' + chalk.bold('SpecialValues') + '"\n  from ScriptFile "' + chalk.bold(ScriptFilePath) + '"\n    in Item "' + chalk.bold(item) + '"\n      in Path "' + chalk.bold(path) + '"\n');
            }

            let foundSpecialValue = false;
            for (const AbilitySpecialKey in data[item].AbilitySpecial) {
              if (AbilitySpecialKey === 'values') {
                continue;
              }
              if (Object.prototype.hasOwnProperty.call(data[item].AbilitySpecial, AbilitySpecialKey)) {
                for (const AbilitySpecialName in data[item].AbilitySpecial[AbilitySpecialKey].values) {
                  if (AbilitySpecialName === SpecialValueKey) {
                    foundSpecialValue = true;
                  }
                }
              }
            }

            if (!foundSpecialValue) {
              console.error(chalk.red('ERR') + ' Trying to access non exiting Value "' + chalk.bold(SpecialValueKey) + '" of Key: "' + chalk.bold('SpecialValues') + '"\n  from line ' + chalk.bold(lineNumber) + ' in ScriptFile "' + chalk.bold(ScriptFilePath) + '"\n    in Item "' + chalk.bold(item) + '"\n      in Path "' + chalk.bold(path) + '"\n');
              // console.error(chalk.red('ERR ScriptFile in path "' + ScriptFilePath + '" is trying to get the SpecialValue "' + SpecialValueKey + '" from the item "' + item + '" in path "' + path + '" but that Key does not exist.'));
            }
          }
        });

        lineReader.on('close', () => {});
      } else if (err.code === 'ENOENT') {
        console.error(chalk.red('ERR') + ' Key "' + chalk.bold('ScriptFile') + '" is pointing to a non exising file: "' + chalk.bold(ScriptFilePath) + '"\n  in Item "' + chalk.bold(item) + '"\n    in Path "' + chalk.bold(path) + '"\n');
      } else {
        console.error(chalk.red('ERR the "ScriptFile" Key of item "' + item + '" in path "' + path + '" is raising error ' + err.code + '\n'));
      }
    });
  }
}

function checkLuaAbilityFile (path) {
  // console.log(chalk.blue('Checking "' + path + '".'));
  const data = parseKV(fs.readFileSync(path)).DOTAAbilities;
  for (const item in data) {
    if (item === 'values') {
      continue;
    }

    if (data[item].values.BaseClass === undefined) {
      console.error(chalk.yellow('WARN') + ' Missing Key: "' + chalk.bold('BaseClass') + '"\n  in Ability "' + chalk.bold(item) + '"\n    in Path "' + chalk.bold(path) + '"\n');
      continue;
    }

    if (data[item].values.BaseClass !== 'ability_lua') {
      continue;
    }

    if (data[item].values.BaseClass === undefined) {
      console.error(chalk.red('ERR') + ' Missing Key: "' + chalk.bold('ScriptFile') + '"\n  in Ability "' + chalk.bold(item) + '"\n    in Path "' + chalk.bold(path) + '"\n');
      continue;
    }

    if (data[item].AbilitySpecial === undefined) {
      console.error(chalk.yellow('WARN') + ' Missing Key: "' + chalk.bold('SpecialValues') + '"\n  in Ability "' + chalk.bold(item) + '"\n    in Path "' + chalk.bold(path) + '"\n');
    }

    const ScriptFilePath = 'game/scripts/vscripts/' + data[item].values.ScriptFile;

    fs.stat(ScriptFilePath, (err, stat) => {
      if (err === null) {
        // console.log(chalk.blue('-> Checking "' + ScriptFilePath + '".'));

        const lineReader = readline.createInterface({
          input: fs.createReadStream(ScriptFilePath)
        });

        let lineNumber = 0;
        lineReader.on('line', (line) => {
          lineNumber++;
          const SpecialValueRegex = /GetSpecialValueFor\(\s*"[^"]+"\s*\)/;
          const SpecialValueMatches = line.match(SpecialValueRegex);

          if (SpecialValueMatches) {
            const start = SpecialValueMatches[0].indexOf('"') + 1;
            const SpecialValueKey = SpecialValueMatches[0].slice(start, SpecialValueMatches[0].indexOf('"', start));

            if (data[item].AbilitySpecial === undefined) {
              console.error(chalk.red('ERR') + ' Trying to access Value ' + chalk.bold(SpecialValueKey) + ' of non existing Key: "' + chalk.bold('SpecialValues') + '"\n  from ScriptFile "' + chalk.bold(ScriptFilePath) + '"\n    in Ability "' + chalk.bold(item) + '"\n      in Path "' + chalk.bold(path) + '"\n');
            }

            let foundSpecialValue = false;
            for (const AbilitySpecialKey in data[item].AbilitySpecial) {
              if (AbilitySpecialKey === 'values') {
                continue;
              }
              if (Object.prototype.hasOwnProperty.call(data[item].AbilitySpecial, AbilitySpecialKey)) {
                for (const AbilitySpecialName in data[item].AbilitySpecial[AbilitySpecialKey].values) {
                  if (AbilitySpecialName === SpecialValueKey) {
                    foundSpecialValue = true;
                  }
                }
              }
            }

            if (!foundSpecialValue) {
              console.error(chalk.red('ERR') + ' Trying to access non exiting Value "' + chalk.bold(SpecialValueKey) + '" of Key: "' + chalk.bold('SpecialValues') + '"\n  from line ' + chalk.bold(lineNumber) + ' in ScriptFile "' + chalk.bold(ScriptFilePath) + '"\n    in Ability "' + chalk.bold(item) + '"\n      in Path "' + chalk.bold(path) + '"\n');
              // console.error(chalk.red('ERR ScriptFile in path "' + ScriptFilePath + '" is trying to get the SpecialValue "' + SpecialValueKey + '" from the item "' + item + '" in path "' + path + '" but that Key does not exist.'));
            }
          }
        });

        lineReader.on('close', () => {});
      } else if (err.code === 'ENOENT') {
        console.error(chalk.red('ERR') + ' Key "' + chalk.bold('ScriptFile') + '" is pointing to a non exising file: "' + chalk.bold(ScriptFilePath) + '"\n  in Ability "' + chalk.bold(item) + '"\n    in Path "' + chalk.bold(path) + '"\n');
      } else {
        console.error(chalk.red('ERR the "ScriptFile" Key of Ability "' + item + '" in path "' + path + '" is raising error ' + err.code + '\n'));
      }
    });
  }
}
(() => {
  walk('game/scripts/npc/items', checkLuaItemFile);
  walk('game/scripts/npc/abilities', checkLuaAbilityFile);
})();
