var parseKV = require('parse-kv');
var fs = require('fs');
var path = require('path');
var after = require('after');
var getTranslations = require('./parse-translation');

var npcDir = path.join(__dirname, '../game/scripts/npc/');
var vscriptsDir = path.join(__dirname, '../game/scripts/vscripts/');

module.exports = {
  listAllItems: listAllItems,
  listAllUnits: listAllUnits,
  findAllItems: findAllItems,
  parseFile: parseFile,
  getItemsFromKV: getItemsFromKV,
  getLuaPathsFromKV: getLuaPathsFromKV,
  findMissingTooltips: findMissingTooltips
};

if (require.main === module) {
  findMissingTooltips(function (err, result) {
    console.log();
    if (err) {
      console.error(err);
      return;
    }
    if (result.length === 0) {
      console.log('Everything looks good!');
    }
  });
}

function findMissingTooltips (cb) {
  var translations = getTranslations(true);
  translations = Object.keys(translations.lang.Tokens.values).map(function (name) {
    return name.toLowerCase();
  });
  var result = [];

  var done = after(3, function (err) {
    cb(err, result);
  });

  findAllUnits(function (err, data) {
    if (err) {
      console.log(err);
      return done(err);
    }
    data.map(function (name) {
      if (translations.indexOf(name) === -1) {
        console.log(name, 'is missing a title', Array(45 - name.length).join(' '), '- Add the key: "' + name + '"');
        result.push([name, name]);
      }
    });
    done();
  });

  findAllAbilities(function (err, data) {
    if (err) {
      console.log(err);
      return done(err);
    }
    data.map(function (name) {
      var prefix = 'DOTA_Tooltip_Ability_';
      var title = prefix + name;
      var description = prefix + name + '_description';

      title = title.toLowerCase();
      description = description.toLowerCase();

      if (translations.indexOf(title) === -1) {
        console.log(name, 'is missing a title', Array(45 - name.length).join(' '), '- Add the key: "' + title + '"');
        result.push([name, title]);
      } else {
        // console.log(translations.lang.Tokens.values[title]);
      }
      if (translations.indexOf(description) === -1) {
        console.log(name, 'is missing a description', Array(39 - name.length).join(' '), '- Add the key: "' + description + '"');
        result.push([name, description]);
      }
    });
    done();
  });

  findAllItems(function (err, data) {
    if (err) {
      console.log(err);
      return done(err);
    }
    data.map(function (name) {
      var prefix = 'DOTA_Tooltip_';
      var requiredTitle = !name.startsWith('item_recipe');
      var requiredDescription = (name.startsWith('item_') && !name.startsWith('item_recipe'));

      if (name.startsWith('item_')) {
        prefix = prefix + 'Ability_';
      }
      var title = prefix + name;
      var description = prefix + name + '_description';

      title = title.toLowerCase();
      description = description.toLowerCase();

      if (translations.indexOf(title) === -1 && requiredTitle) {
        console.log(name, 'is missing a title', Array(45 - name.length).join(' '), '- Add the key: "' + title + '"');
        result.push([name, title]);
      } else {
        // console.log(translations.lang.Tokens.values[title]);
      }
      if (translations.indexOf(description) === -1 && requiredDescription) {
        console.log(name, 'is missing a description', Array(39 - name.length).join(' '), '- Add the key: "' + description + '"');
        result.push([name, description]);
      }
    });
    done();
  });
}

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
        if (line === functionString) {
          foundLine = true;
          return;
        }
      });
    // store result
    hiddenModifiers[modPair[0]] = result;

    cb(null, result);
  });
}

function findLinkLuaModifiersInFile (script, cb) {
  fs.readFile(path.join(vscriptsDir, script), {
    encoding: 'utf8'
  }, function (err, data) {
    if (err) {
      return cb(err);
    }
    var result = [];
    var modifierList = data.split('\n')
      .filter(function (line) {
        return line.startsWith('LinkLuaModifier') && line.split(',').length === 3;
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
      fs.access(path.join(vscriptsDir, modifier[1]), function (err, data) {
        if (err) {
          console.error('LinkLuaModifier referenced non-existent file:', modifier);
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
