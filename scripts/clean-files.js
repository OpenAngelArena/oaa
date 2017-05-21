const fs = require('fs');
const path = require('path');
const chalk = require('chalk');
const readline = require('readline');

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
      console.log(chalk.red(err));
      return;
    }
    files.forEach(function (file) {
      var fullPath = path.join(directoryName, file);
      fs.stat(fullPath, function (err, f) {
        if (err) {
          console.log(chalk.red(err));
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
      return console.log(chalk.red(err));
    }
    var result = data.replace(/^ +/gm, '').replace(/\t/g, '  ').replace(/\r\n/g, '\n');

    fs.writeFile(file, result, 'utf8', function (err) {
      if (err) {
        return console.log(chalk.red(err));
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
  lineReader.on('line', (line) => {
    line = line.replace(/\t/g, '  '); // replace tabs
    if (line.indexOf('}') > -1) {
      indent--;
    }
    line = line.replace(/^ +/g, stringRepeat('  ', indent)); // fix indent
    if (line.indexOf('{') > -1) {
      indent++;
    }
    result += line + '\n';
    // lineReader.write(line);
  });
  lineReader.on('close', () => {
    fs.writeFile(file, result, 'utf8', function (err) {
      if (err) {
        return console.log(chalk.red(err));
      }
    });
  });
}

walk('game/resource/English', cleanTooltipFile);
walk('game/scripts/npc', cleanKVFile);
