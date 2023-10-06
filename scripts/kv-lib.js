const request = require('request');
const parseKV = require('parse-kv');
const fs = require('fs');
const path = require('path');
const after = require('after');

const gameDir = path.join(__dirname, '../game/');
const scriptDir = path.join(gameDir, 'scripts/');
const vscriptDir = path.join(scriptDir, 'vscripts');
const npcDir = path.join(scriptDir, 'npc');
const abilityDir = path.join(npcDir, 'abilities');
const itemDir = path.join(npcDir, 'items');
const heroDir = path.join(npcDir, 'heroes');

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
    url: 'https://raw.githubusercontent.com/spirit-bear-productions/dota_vpk_updates/main/scripts/npc/npc_abilities.txt'
  }, function (err, result) {
    if (err) {
      return cb(err);
    }
    const data = parseKV(result.body.replace('"SPELL_IMMUNITY_ENEMIES_YES\\"', '"SPELL_IMMUNITY_ENEMIES_YES"'));
    cb(null, data.DOTAAbilities);
  });
}

function dotaItems (cb) {
  request.get({
    url: 'https://raw.githubusercontent.com/spirit-bear-productions/dota_vpk_updates/main/scripts/npc/items.txt'
  }, function (err, result) {
    if (err) {
      return cb(err);
    }
    const data = parseKV(result.body);
    cb(null, data.DOTAAbilities);
  });
}

function dotaHeroes (cb) {
  request.get({
    url: 'https://raw.githubusercontent.com/spirit-bear-productions/dota_vpk_updates/main/scripts/npc/npc_heroes.txt'
  }, function (err, result) {
    if (err) {
      return cb(err);
    }
    const data = parseKV(result.body);
    cb(null, data.DOTAHeroes);
  });
}

function getAll (cb) {
  let list = [];
  const done = after(2, function (err) {
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
  const result = {};
  const done = after(list.length, function (err) {
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
    let result = [];
    const done = after(data.length, function (err) {
      cb(err, result);
    });
    data.forEach(function (file) {
      const filePath = path.join(dir, file);
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
