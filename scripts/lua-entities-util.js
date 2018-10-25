var parseKV = require('parse-kv');
var fs = require('fs');
var path = require('path');
var after = require('after');

var npcDir = path.join(__dirname, '../game/scripts/npc/');
var vscriptsDir = path.join(__dirname, '../game/scripts/vscripts/');

module.exports = {
  listAllItems: listAllItems,
  listAllUnits: listAllUnits,
  listAllAbilities: listAllAbilities,
  findAllItems: findAllItems,
  findAllUnits: findAllUnits,
  findAllAbilities: findAllAbilities,
  parseFile: parseFile,
  getItemsFromKV: getItemsFromKV,
  getLuaPathsFromKV: getLuaPathsFromKV,
  listAllLuaFiles: listAllLuaFiles,
  findLinkLuaModifiersInFile: findLinkLuaModifiersInFile
};

function listAllItems (cb) {
  fs.readFile(path.join(npcDir, 'npc_items_custom.txt'), {
    encoding: 'utf8'
  }, function (err, data) {
    if (err) {
      return cb(err);
    }

    var lines = data.split('\n')
      .filter(function (line) {
        return line.substr(0, 5) === '#base';
      })
      .map(function (line) {
        return line.split('"')[1];
      });

    cb(null, lines);
  });
}

function listAllUnits (cb) {
  fs.readFile(path.join(npcDir, '/npc_units_custom.txt'), {
    encoding: 'utf8'
  }, function (err, data) {
    if (err) {
      return cb(err);
    }

    var lines = data.split('\n')
      .filter(function (line) {
        return line.substr(0, 5) === '#base';
      })
      .map(function (line) {
        return line.split('"')[1];
      });

    cb(null, lines);
  });
}

function listAllAbilities (cb) {
  fs.readFile(path.join(npcDir, 'npc_abilities_custom.txt'), {
    encoding: 'utf8'
  }, function (err, data) {
    if (err) {
      return cb(err);
    }

    var lines = data.split('\n')
      .filter(function (line) {
        return line.substr(0, 5) === '#base';
      })
      .map(function (line) {
        return line.split('"')[1];
      });

    cb(null, lines);
  });
}

function listAllLuaFiles (cb) {
  var luaFileRegex = /\.lua$/;
  var luaFileFilter = function (fileName) {
    return luaFileRegex.test(fileName);
  };

  var luaScripts = getFilesFromDirectory(vscriptsDir);
  return luaScripts.filter(luaFileFilter);
}

function findAllAbilities (cb) {
  var result = [];
  listAllAbilities(function (err, lines) {
    if (err) {
      return cb(err);
    }
    var done = after(lines.length, function () {
      var foundList = {};
      result = result.sort().filter(function (n) {
        if (foundList[n]) {
          return false;
        }
        foundList[n] = true;
        return true;
      });
      cb(null, result);
    });

    lines.forEach(function (line) {
      parseFile(line, function (err, kvData) {
        if (err) {
          return done(err);
        }
        var unitList = getAbilitiesFromKV(kvData);
        result = result.concat(unitList);
        done();
      });
    });
  });
}

function findAllUnits (cb) {
  var result = [];
  listAllUnits(function (err, lines) {
    if (err) {
      return cb(err);
    }
    var done = after(lines.length, function () {
      var foundList = {};
      result = result.sort().filter(function (n) {
        if (foundList[n]) {
          return false;
        }
        foundList[n] = true;
        return true;
      });
      cb(null, result);
    });

    lines.forEach(function (line) {
      parseFile(line, function (err, kvData) {
        if (err) {
          return done(err);
        }
        var unitList = getUnitsFromKV(kvData);
        result = result.concat(unitList);
        done();
      });
    });
  });
}

function findAllItems (cb) {
  var result = [];
  listAllItems(function (err, lines) {
    if (err) {
      return cb(err);
    }
    var done = after(lines.length, function () {
      var foundList = {};
      result = result.sort().filter(function (n) {
        if (foundList[n]) {
          return false;
        }
        foundList[n] = true;
        return true;
      });
      cb(null, result);
    });

    lines.forEach(function (line) {
      parseFile(line, function (err, kvData) {
        if (err) {
          return done(err);
        }
        var itemList = getItemsFromKV(kvData);
        result = result.concat(itemList);
        var luaPathList = getLuaPathsFromKV(kvData);

        var luaPathDone = after(luaPathList.length, done);
        luaPathList.forEach(function (luaPath) {
          findLinkLuaModifiersInFile(luaPath, function (err, modifiers) {
            if (err) {
              return luaPathDone(err);
            }
            result = result.concat(modifiers);
            luaPathDone();
          });
        });
      });
    });
  });
}

function getUnitsFromKV (data) {
  return Object.keys(data.DOTAUnits).filter(n => n !== 'values');
}

function getItemsFromKV (data) {
  if (!data.DOTAItems) {
    return [];
  }
  return Object.keys(data.DOTAItems).filter(function (name) {
    if (name === 'values') {
      return false;
    }
    return !(!data.DOTAItems[name].values.BaseClass || data.DOTAItems[name].values.BaseClass === name);
  });
}

function getAbilitiesFromKV (data) {
  return Object.keys(data.DOTAAbilities).filter(n => n !== 'values');
}

function getLuaPathsFromKV (data) {
  return getItemsFromKV(data).map(function (item) {
    switch (data.DOTAItems[item].values.BaseClass) {
      case 'item_datadriven':
        // probably nothing?
        // console.log(Object.keys(data.DOTAItems[item]));
        break;
      case 'item_lua':
        if (data.DOTAItems[item].values.ScriptFile.endsWith('.lua')) {
          return data.DOTAItems[item].values.ScriptFile;
        } else {
          return data.DOTAItems[item].values.ScriptFile + '.lua';
        }
    }
    return [];
  })
    .reduce(function (memo, val) {
      return memo.concat(val);
    }, []);
}

var hiddenModifiers = {};
function isModifierHidden (modPair, cb) {
  if (hiddenModifiers[modPair[0]] !== undefined) {
    return cb(null, hiddenModifiers[modPair[0]]);
  }
  var functionString = ['function ', modPair[0], ':IsHidden()'].join('');
  fs.readFile(path.join(vscriptsDir, modPair[1]), {
    encoding: 'utf8'
  }, function (err, data) {
    if (err) {
      return cb(err);
    }
    var foundLine = false;
    var result = false;
    data.split('\n')
      .forEach(function (line) {
        line = line.trim();
        if (foundLine) {
          result = (line === 'return true');
          foundLine = false;
          return;
        }
        if (line.replace(' ()', '()') === functionString) {
          foundLine = true;
        }
      });
    // store result
    hiddenModifiers[modPair[0]] = result;

    cb(null, result);
  });
}

function findLinkLuaModifiersInFile (script, cb, fullPathProvided = false, failOnNonExistentPath = false) {
  var scriptPath = fullPathProvided ? script : path.join(vscriptsDir, script);
  var linkModifierRegex = /^\s*LinkLuaModifier.*/;
  fs.readFile(scriptPath, {
    encoding: 'utf8'
  }, function (err, data) {
    if (err) {
      return cb(err);
    }
    var result = [];
    var modifierList = data.split('\n')
      .filter(function (line) {
        return linkModifierRegex.test(line) && line.split(',').length === 3;
      })
      .map(function (link) {
        var modifierParts = link.split(',');
        var modifierPath = modifierParts[1].trim();
        var modifierName = modifierParts[0].trim().substr(16).trim();
        modifierName = modifierName.substr(1, modifierName.length - 2);
        modifierPath = modifierPath.substr(1, modifierPath.length - 2);

        return [modifierName, modifierPath];
      });
    var done = after(modifierList.length * 2, function () {
      cb(null, result);
    });

    modifierList.forEach(function (modifier) {
      var relativePath = modifier[1];
      if (!relativePath.endsWith('.lua')) {
        relativePath = relativePath + '.lua';
      }
      fs.access(path.join(vscriptsDir, relativePath), function (err, data) {
        if (err) {
          var missingFileMsg = 'LinkLuaModifier referenced non-existent file:' + modifier;
          console.error(missingFileMsg);
          if (failOnNonExistentPath) {
            cb(missingFileMsg);
          }
        }
        return done(err);
      });
    });
    modifierList.forEach(function (modifier) {
      isModifierHidden(modifier, function (err, hidden) {
        if (!err && !hidden) {
          result.push(modifier[0]);
        }
        done(err);
      });
    });
  });
}

function parseFile (file, cb) {
  fs.readFile(path.join(npcDir, file), {
    encoding: 'utf8'
  }, function (err, data) {
    if (err) {
      return cb(err);
    }
    try {
      data = parseKV(data);
    } catch (e) {
      console.error('Failed to parse', file, e);
      throw e;
    }
    cb(null, data);
  });
}

// src: http://resolvethis.com/how-to-get-all-files-in-a-folder-in-javascript/
function getFilesFromDirectory (dir, fileList) {
  fileList = fileList || [];

  var files = fs.readdirSync(dir);
  for (var i in files) {
    var name = dir + '/' + files[i];
    if (fs.statSync(name).isDirectory()) {
      getFilesFromDirectory(name, fileList);
    } else {
      fileList.push(name);
    }
  }
  return fileList;
}
