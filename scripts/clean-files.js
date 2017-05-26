const fs = require('fs');
const path = require('path');
const chalk = require('chalk');
const readline = require('readline');

const tab = '  ';
const padLenght = 59;

function stringRepeat (string, num) {
  var result = '';
  for (var i = 0; i < num; i++) {
    result += string;
  }
  return result;
}

var walk = function (directoryName, action) {
  fs.readdir(directoryName, function (err, files) {
    if (err) {
      console.error(chalk.red(err));
      return;
    }
    files.forEach(function (file) {
      var fullPath = path.join(directoryName, file);
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
  console.log('Cleaning ' + chalk.green(file));

  fs.readFile(file, 'utf8', function (err, data) {
    if (err) {
      return console.error(chalk.red(err));
    }
    var result = data.replace(/^ +/gm, '').replace(/\t/g, tab).replace(/\r\n/g, '\n');

    fs.writeFile(file, result, 'utf8', function (err) {
      if (err) {
        return console.error(chalk.red(err));
      }
    });
  });
}

function cleanKVFile (file) {
  if (file.indexOf('.md') > -1) {
    return;
  }

  console.log('Cleaning ' + chalk.green(file));

  var lineReader = readline.createInterface({
    input: fs.createReadStream(file)
  });

  var indent = 0;
  var result = '';
  var error = false;
  var lineNumber = 0;
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

    var indices = [];
    for (var i = 0; i < line.length; i++) {
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
    if (!error) {
      fs.writeFile(file, result, 'utf8', function (err) {
        if (err) {
          return console.error(chalk.red(err));
        }
      });
    }
  });
}

walk('game/resource/English', cleanTooltipFile);
walk('game/scripts/npc', cleanKVFile);
walk('game/scripts/shops', cleanKVFile);
