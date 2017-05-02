var fs = require('fs');
var path = require('path');
var chalk = require('chalk');

var walk = function (directoryName) {
  fs.readdir(directoryName, function (e, files) {
    if (e) {
      console.log('Error: ', e);
      return;
    }
    files.forEach(function (file) {
      var fullPath = path.join(directoryName, file);
      fs.stat(fullPath, function (e, f) {
        if (e) {
          console.log('Error: ', e);
          return;
        }
        if (f.isDirectory()) {
          walk(fullPath);
        } else {
          cleanFile(fullPath);
        }
      });
    });
  });
};

function cleanFile (file) {
  console.log('Cleaning ' + chalk.red(file));

  fs.readFile(file, 'utf8', function (err, data) {
    if (err) {
      return console.log(err);
    }
    var result = data.replace(/^ +/gm, '').replace(/\t/g, '  ').replace(/\r\n/g, '\n');

    fs.writeFile(file, result, 'utf8', function (err) {
      if (err) {
        return console.log(err);
      }
    });
  });
}

walk('game/resource/English');
