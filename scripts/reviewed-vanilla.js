// Snapshot of the vanilla values behind every `// OAA` comment.
//
// Values with an OAA comment are skipped by special-values.test.js, so when Valve
// changes the vanilla value underneath them nothing goes red (7.42: Queen of Pain
// Sonic Wave, Kez Raptor Dance, Pudge Dismember, Pugna mana costs).
// oaa-vanilla-drift.test.js compares live vanilla with this snapshot instead.
//
// After reviewing a drift (re-apply vanilla's change on top of the OAA value, or keep it):
//   node scripts/reviewed-vanilla.js --accept queenofpain_sonic_wave   (entries or single keys "entry|path", comma separated)
//   node scripts/reviewed-vanilla.js --accept-all                       (everything, after a full port review)
// Build from an older vanilla (needs a local d2vpkr clone):
//   node scripts/reviewed-vanilla.js --accept-all --d2vpkr <dir> --ref <sha>
const fs = require('fs');
const path = require('path');
const childProcess = require('child_process');
const parseKV = require('parse-kv');
const Lib = require('./kv-lib');

const SNAPSHOT = path.join(__dirname, 'test/fixtures/oaa-reviewed-vanilla.json');
const SKIP = ['values', 'comments'];

function isProtected (comment) {
  return typeof comment === 'string' && comment.includes('OAA');
}

// vanilla value as a stable string: leaf -> value, block -> sorted JSON, missing -> null
function norm (node) {
  if (node === undefined || node === null) return null;
  if (typeof node === 'string') return node;
  if (node.values) {
    const out = {};
    Object.keys(node.values).sort().forEach(k => { out[k] = node.values[k]; });
    return JSON.stringify(out);
  }
  return null;
}

function childOf (block, key) {
  if (!block) return undefined;
  if (block.values && block.values[key] !== undefined) return block.values[key];
  if (block[key] && !SKIP.includes(key)) return block[key];
  return undefined;
}

function vanillaParent (name, entry, vanilla) {
  if (vanilla[name] && typeof vanilla[name] === 'object') return vanilla[name];
  const base = entry.values && entry.values.BaseClass;
  if (base && vanilla[base] && typeof vanilla[base] === 'object') return vanilla[base];
  return null;
}

// Returns { "<entry>|<path>": { file, vanilla } } for every OAA-commented key that has a vanilla parent.
function collect (oaaFiles, vanilla) {
  const result = {};
  Object.keys(oaaFiles).forEach(function (file) {
    const root = oaaFiles[file] && oaaFiles[file].DOTAAbilities;
    if (!root) return;
    const rel = path.relative(Lib.npcDir, file).split(path.sep).join('/');
    Object.keys(root).filter(k => !SKIP.includes(k)).forEach(function (name) {
      const entry = root[name];
      const parent = vanillaParent(name, entry, vanilla);
      if (!parent) return;
      walk(entry, parent, name, []);
    });
    function walk (node, parent, name, trail) {
      const comments = node.comments || {};
      const keys = Object.keys(node.values || {}).concat(Object.keys(node).filter(k => !SKIP.includes(k)));
      keys.forEach(function (key) {
        const here = trail.concat(key);
        const own = childOf(node, key);
        const theirs = childOf(parent, key);
        if (isProtected(comments[key])) {
          result[name + '|' + here.join('/')] = { file: rel, vanilla: norm(theirs) };
        } else if (own && typeof own === 'object' && theirs && typeof theirs === 'object') {
          walk(own, theirs, name, here);
        }
      });
    }
  });
  return result;
}

function load () {
  try {
    return JSON.parse(fs.readFileSync(SNAPSHOT, 'utf8'));
  } catch (e) {
    return {};
  }
}

function save (snapshot) {
  const out = {};
  Object.keys(snapshot).sort().forEach(k => { out[k] = snapshot[k]; });
  fs.writeFileSync(SNAPSHOT, JSON.stringify(out, null, 2) + '\n');
}

function oaaFiles (cb) {
  Lib.items(function (err, items) {
    if (err) return cb(err);
    Lib.abilities(function (err, abilities) {
      if (err) return cb(err);
      cb(null, Object.assign({}, items, abilities));
    });
  });
}

function liveVanilla (cb) {
  Lib.dotaItems(function (err, items) {
    if (err) return cb(err);
    Lib.dotaAbilities(function (err, abilities) {
      if (err) return cb(err);
      cb(null, Object.assign({}, abilities, items));
    });
  });
}

function vanillaAtRef (dir, ref) {
  const git = args => childProcess.execFileSync('git', ['-C', dir].concat(args), { encoding: 'utf8', maxBuffer: 1 << 28 });
  const parse = body => parseKV(body.replace('}\t\t}', '}\n\t\t}'));
  let out = {};
  out = Object.assign(out, parse(git(['show', ref + ':dota/scripts/npc/npc_abilities.txt'])).DOTAAbilities);
  git(['ls-tree', '--name-only', ref, 'dota/scripts/npc/heroes/']).split('\n').filter(f => /npc_dota_hero_.*\.txt$/.test(f)).forEach(function (f) {
    const hero = path.basename(f, '.txt');
    const data = parse(git(['show', ref + ':' + f]));
    if (data.DOTAHeroes && data.DOTAHeroes[hero]) out = Object.assign(out, data.DOTAHeroes[hero].AbilityDefinitions);
  });
  return Object.assign(out, parse(git(['show', ref + ':dota/scripts/npc/items.txt'])).DOTAAbilities);
}

module.exports = { SNAPSHOT, collect, load, save, oaaFiles, liveVanilla };

if (require.main === module) {
  const argv = process.argv.slice(2);
  const opt = name => { const i = argv.indexOf(name); return i === -1 ? undefined : argv[i + 1]; };
  const acceptAll = argv.includes('--accept-all');
  const accept = (opt('--accept') || '').split(',').filter(Boolean);
  if (!acceptAll && !accept.length) {
    console.log('usage: node scripts/reviewed-vanilla.js --accept <entry[,entry]> | --accept-all [--d2vpkr <dir> --ref <sha>]');
    process.exit(1);
  }
  const withVanilla = function (cb) {
    if (opt('--d2vpkr')) return cb(null, vanillaAtRef(opt('--d2vpkr'), opt('--ref') || 'HEAD'));
    liveVanilla(cb);
  };
  oaaFiles(function (err, files) {
    if (err) throw err;
    withVanilla(function (err, vanilla) {
      if (err) throw err;
      const current = collect(files, vanilla);
      const snapshot = acceptAll ? {} : load();
      let n = 0;
      Object.keys(current).forEach(function (key) {
        // --accept takes entry names (all OAA-commented keys of that entry) or single keys "entry|path"
        if (acceptAll || accept.includes(key) || accept.includes(key.split('|')[0])) {
          snapshot[key] = current[key];
          n++;
        }
      });
      save(snapshot);
      console.log('OK: ' + n + ' entries written to ' + path.relative(process.cwd(), SNAPSHOT));
    });
  });
}
