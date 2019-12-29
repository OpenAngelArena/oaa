var request = require('request');
var parseKV = require('parse-kv');
var fs = require('fs');
var path = require('path');
var after = require('after');

var gameDir = path.join(__dirname, '../game/');
var scriptDir = path.join(gameDir, 'scripts/');
var vscriptDir = path.join(scriptDir, 'vscripts');
var npcDir = path.join(scriptDir, 'npc');
var abilityDir = path.join(npcDir, 'abilities');
var itemDir = path.join(npcDir, 'items');
var heroDir = path.join(npcDir, 'heroes');

module.exports = {
  itemFiles: findAllItems,
  abilityFiles: findAllAbilities,
  items: allItems,
  abilities: allAbilities,
  heroes: allHeroes,
  all: getAll,

  gameDir: gameDir,
  scriptDir: scriptDir,
  vscriptDir: vscriptDir,
  npcDir: npcDir,
  abilityDir: abilityDir,
  itemDir: itemDir,
  heroDir: heroDir,
  dotaItems: dotaItems,
  dotaAbilities: dotaAbilities,
  dotaHeroes: dotaHeroes
};

function dotaAbilities (cb) {
  request.get({
    // url: 'https://raw.githubusercontent.com/SteamDatabase/GameTracking-Dota2/master/game/dota/scripts/npc/npc_abilities.txt'
    url: 'https://raw.githubusercontent.com/DarkoniusXNG/oaa_changelogs_github/master/npc_abilities.txt'
  }, function (err, result) {
    if (err) {
      return cb(err);
    }
    var data = parseKV(result.body.replace(/[^\\/]\/ Damage/ig, '// Damage'));
    cb(null, data.DOTAAbilities);
  });
}

function dotaItems (cb) {
  request.get({
    url: 'https://raw.githubusercontent.com/SteamDatabase/GameTracking-Dota2/master/game/dota/pak01_dir/scripts/npc/items.txt'
  }, function (err, result) {
    if (err) {
      return cb(err);
    }
    var data = parseKV(result.body);
    cb(null, data.DOTAAbilities);
  });
}

function dotaHeroes (cb) {
  request.get({
    url: 'https://raw.githubusercontent.com/SteamDatabase/GameTracking-Dota2/master/game/dota/scripts/npc/npc_heroes.txt'
  }, function (err, result) {
    if (err) {
      return cb(err);
    }
    var data = parseKV(result.body);
    cb(null, data.DOTAHeroes);
  });
}

function getAll (cb) {
  var list = [];
  var done = after(2, function (err) {
    if (err) {
      return cb(err);
    }
    parseAllKVs(list, cb);
  });
  findAllItems(gotKVS);
  findAllAbilities(gotKVS);

  function gotKVS (err, data) {
    if (err) {
      return done(err);
    }
    list = list.concat(data);
    done();
  }
}

function allItems (cb) {
  findAllItems(function (err, items) {
    if (err) {
      return cb(err);
    }
    parseAllKVs(items, cb);
  });
}

function allAbilities (cb) {
  findAllAbilities(function (err, items) {
    if (err) {
      return cb(err);
    }
    parseAllKVs(items, cb);
  });
}

function allHeroes (cb) {
  findAllHeroes(function (err, heroes) {
    if (err) {
      return cb(err);
    }
    parseAllKVs(heroes, cb);
  });
}

function parseAllKVs (list, cb) {
  var result = {};
  var done = after(list.length, function (err) {
    if (err) {
      return cb(err);
    }
    cb(null, result);
  });
  list.forEach(function (entry) {
    fs.readFile(entry, { encoding: 'utf8' }, function (err, data) {
      if (err) {
        return done(err);
      }
      try {
        result[entry] = parseKV(data);
      } catch (err) {
        console.log(entry, 'failed');
        return done(err);
      }
      done();
    });
  });
}

function findAllItems (cb) {
  findAllKVFiles(itemDir, cb);
}

function findAllAbilities (cb) {
  findAllKVFiles(abilityDir, cb);
}

function findAllHeroes (cb) {
  findAllKVFiles(heroDir, cb);
}

function findAllKVFiles (dir, cb) {
  fs.readdir(dir, function (err, data) {
    if (err) {
      return cb(err);
    }
    var result = [];
    var done = after(data.length, function (err) {
      cb(err, result);
    });
    data.forEach(function (file) {
      var filePath = path.join(dir, file);
      fs.stat(filePath, function (err, stat) {
        if (err) {
          return done(err);
        }
        if (stat.isDirectory()) {
          return findAllKVFiles(filePath, function (err, kvs) {
            if (!err) {
              result = result.concat(kvs);
            }
            done(err);
          });
        }
        result.push(filePath);
        done();
      });
    });
  });
}
