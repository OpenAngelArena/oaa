var fs = require('fs');
var path = require('path');
var chalk = require('chalk');

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
  console.log('Cleaning ' + chalk.green(file));

  fs.readFile(file, 'utf8', function (err, data) {
    if (err) {
      return console.log(chalk.red(err));
    }
    var result = data.replace(/\t/g, '  ').replace(/\r\n/g, '\n');

    fs.writeFile(file, result, 'utf8', function (err) {
      if (err) {
        return console.log(chalk.red(err));
      }
    });
  });
}

walk('game/resource/English', cleanTooltipFile);
walk('game/scripts/npc', cleanKVFile);
