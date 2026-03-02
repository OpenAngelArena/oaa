const parseKV = require('parse-kv');
const fs = require('fs');
const path = require('path');
const after = require('after');

const npcDir = path.join(__dirname, '../game/scripts/npc/');
const vscriptsDir = path.join(__dirname, '../game/scripts/vscripts/');

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

    const lines = data.split('\n')
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

    const lines = data.split('\n')
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

    const lines = data.split('\n')
      .filter(function (line) {
        return line.substr(0, 5) === '#base';
      })
      .map(function (line) {
        return line.split('"')[1];
      });

    cb(null, lines);
  });
}

function listAllLuaFiles () {
  const luaFileRegex = /\.lua$/;
  const luaFileFilter = function (fileName) {
    return luaFileRegex.test(fileName);
  };

  const luaScripts = getFilesFromDirectory(vscriptsDir);
  return luaScripts.filter(luaFileFilter);
}

function findAllAbilities (cb) {
  let result = [];
  listAllAbilities(function (err, lines) {
    if (err) {
      return cb(err);
    }
    const done = after(lines.length, function () {
      const foundList = {};
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
        const unitList = getAbilitiesFromKV(kvData);
        result = result.concat(unitList);
        done();
      });
    });
  });
}

function findAllUnits (cb) {
  let result = [];
  listAllUnits(function (err, lines) {
    if (err) {
      return cb(err);
    }
    const done = after(lines.length, function () {
      const foundList = {};
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
        const unitList = getUnitsFromKV(kvData);
        result = result.concat(unitList);
        done();
      });
    });
  });
}

function findAllItems (cb) {
  let result = [];
  listAllItems(function (err, lines) {
    if (err) {
      return cb(err);
    }
    const done = after(lines.length, function () {
      const foundList = {};
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
        const itemList = getItemsFromKV(kvData);
        result = result.concat(itemList);
        const luaPathList = getLuaPathsFromKV(kvData);

        const luaPathDone = after(luaPathList.length, done);
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
  if (!data.DOTAAbilities) {
    return [];
  }
  return Object.keys(data.DOTAAbilities).filter(function (name) {
    if (name === 'values') {
      return false;
    }
    return !(!data.DOTAAbilities[name].values.BaseClass || data.DOTAAbilities[name].values.BaseClass === name);
  });
}

function getAbilitiesFromKV (data) {
  return Object.keys(data.DOTAAbilities).filter(n => n !== 'values');
}

function getLuaPathsFromKV (data) {
  return getItemsFromKV(data).map(function (item) {
    switch (data.DOTAAbilities[item].values.BaseClass) {
      case 'item_datadriven':
        // probably nothing?
        // console.log(Object.keys(data.DOTAAbilities[item]));
        break;
      case 'item_lua':
        if (data.DOTAAbilities[item].values.ScriptFile.endsWith('.lua')) {
          return data.DOTAAbilities[item].values.ScriptFile;
        } else {
          return data.DOTAAbilities[item].values.ScriptFile + '.lua';
        }
    }
    return [];
  })
    .reduce(function (memo, val) {
      return memo.concat(val);
    }, []);
}

const hiddenModifiers = {};
function isModifierHidden (modPair, cb) {
  if (hiddenModifiers[modPair[0]] !== undefined) {
    return cb(null, hiddenModifiers[modPair[0]]);
  }
  const functionString = ['function ', modPair[0], ':IsHidden()'].join('');
  fs.readFile(path.join(vscriptsDir, modPair[1]), {
    encoding: 'utf8'
  }, function (err, data) {
    if (err) {
      return cb(err);
    }
    let foundLine = false;
    let result = false;
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
  const scriptPath = fullPathProvided ? script : path.join(vscriptsDir, script);
  const linkModifierRegex = /^\s*LinkLuaModifier.*/;
  fs.readFile(scriptPath, {
    encoding: 'utf8'
  }, function (err, data) {
    if (err) {
      return cb(err);
    }
    const result = [];
    const modifierList = data.split('\n')
      .filter(function (line) {
        return linkModifierRegex.test(line) && line.split(',').length === 3;
      })
      .map(function (link) {
        const modifierParts = link.split(',');
        let modifierPath = modifierParts[1].trim();
        let modifierName = modifierParts[0].trim().substr(16).trim();
        modifierName = modifierName.substr(1, modifierName.length - 2);
        modifierPath = modifierPath.substr(1, modifierPath.length - 2);

        return [modifierName, modifierPath];
      });
    const done = after(modifierList.length * 2, function () {
      cb(null, result);
    });

    modifierList.forEach(function (modifier) {
      let relativePath = modifier[1];
      if (!relativePath.endsWith('.lua')) {
        relativePath = relativePath + '.lua';
      }
      fs.access(path.join(vscriptsDir, relativePath), function (err, data) {
        if (err) {
          const missingFileMsg = 'LinkLuaModifier referenced non-existent file:' + modifier;
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

  const files = fs.readdirSync(dir);
  for (const i in files) {
    const name = dir + '/' + files[i];
    if (fs.statSync(name).isDirectory()) {
      getFilesFromDirectory(name, fileList);
    } else {
      fileList.push(name);
    }
  }
  return fileList;
}
