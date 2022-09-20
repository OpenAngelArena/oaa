const fs = require('fs');
const path = require('path');
const chalk = require('chalk');
const readline = require('readline');

const tab = '  ';
const padLenght = 59;

function stringRepeat (string, num) {
  let result = '';
  for (let i = 0; i < num; i++) {
    result += string;
  }
  return result;
}

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

function cleanTooltipFile (file) {
  // console.log('Cleaning ' + chalk.green(file));

  fs.readFile(file, { encoding: 'utf8' }, function (err, data) {
    if (err) {
      return console.error(chalk.red(err));
    }
    const result = data.replace(/^ +/gm, '').replace(/\t/g, tab).replace(/\r\n/g, '\n');

    if (!deepEqual(result, data)) {
      fs.writeFile(file, result, { encoding: 'utf8' }, function (err) {
        if (err) {
          return console.error(chalk.red(err));
        }
      });
    }
  });
}

function cleanKVFile (file) {
  if (file.indexOf('.md') > -1) {
    return;
  }

  // console.log('Cleaning ' + chalk.green(file));
  let before = '';
  fs.readFile(file, { encoding: 'utf8' }, function (err, data) {
    if (err) {
      return console.error(chalk.red(err));
    }
    before = data;
  });

  const lineReader = readline.createInterface({
    input: fs.createReadStream(file)
  });

  let indent = 0;
  let result = '';
  let error = false;
  let lineNumber = 0;
  lineReader.on('line', (line) => {
    lineNumber++;
    // replace tabs
    line = line.replace(/\t/g, tab);

    // fix indent
    if (line.indexOf('}') > -1) {
      // decrease indent on }
      indent--;
    }
    line = line.replace(/^ +/g, stringRepeat(tab, indent)); // set indent
    if (line.indexOf('{') > -1) {
      // increase indent on {
      indent++;
    }

    // fix padding
    line = line.replace(/" +"/g, '"  "'); // remove spaces between "'s

    const indices = [];
    for (let i = 0; i < line.length; i++) {
      if (line[i] === '"') indices.push(i);
    }

    if (Object.keys(indices).length % 2 === 1) {
      console.error(chalk.red('ERR File "' + file + '" has an uneven number of " at line ' + lineNumber + '.'));
      error = true;
      return;
    }

    if (Object.keys(indices).length > 2 && indices[2] < padLenght) {
      line = line.slice(0, indices[1] + 1) + stringRepeat(' ', padLenght - indices[1] - 2) + line.slice(indices[2]);
    }

    result += line + '\n';
  });

  lineReader.on('close', () => {
    if (indent > 0) {
      error = true;
      console.error(chalk.red('ERR File "' + file + '" is missing a closing bracket \'}\'.'));
    }
    if (indent < 0) {
      error = true;
      console.error(chalk.red('ERR File "' + file + '" is missing an opening bracket \'{\'.'));
    }
    if (!error && !deepEqual(result, before)) {
      fs.writeFile(file, result, { encoding: 'utf8' }, function (err) {
        if (err) {
          return console.error(chalk.red(err));
        }
      });
    }
  });
}

function deepEqual (obj1, obj2) {
  if (obj1 === obj2) {
    return true;
  } else if ((typeof obj1 === 'object' && obj1 != null) && (typeof obj2 === 'object' && obj2 != null)) {
    if (Object.keys(obj1).length !== Object.keys(obj2).length) return false;
    for (const key in obj1) {
      if (!(key in obj2)) return false;
      if (!deepEqual(obj1[key], obj2[key])) return false;
    }
    return true;
  } else {
    return JSON.stringify(obj1) === JSON.stringify(obj2);
  }
}

walk('game/resource/English', cleanTooltipFile);
walk('game/scripts/npc', cleanKVFile);
walk('game/scripts/shops', cleanKVFile);
