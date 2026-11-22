// Checks game/scripts/npc/neutral_items.txt against vanilla Dota's neutral_items.txt.
// Added after 7.42 moved tiers to "item_pools" and OAA's flat "items" lists silently stopped working.
const test = require('tape');
const fs = require('fs');
const path = require('path');
const request = require('request');
const parseKV = require('parse-kv');
const Lib = require('../kv-lib');

const OAA_FILE = path.join(Lib.npcDir, 'neutral_items.txt');
const VANILLA_URL = 'https://raw.githubusercontent.com/dotabuff/d2vpkr/refs/heads/master/dota/scripts/npc/neutral_items.txt';

// Vanilla neutrals OAA leaves out on purpose (none right now). Anything else vanilla has must be in OAA's pools
// or be named in a replacement comment ("item_oaa_x" "1" // item_vanilla_x).
const EXCLUDED = {
  // item_example: 'reason it is left out'
};

let oaaText = null;
let oaa = null;
let vanilla = null;
let dotaItems = null;
const oaaItems = {}; // item name -> definition (or 'REMOVE')

function tierKeys (kv) {
  return Object.keys(kv.neutral_items.neutral_tiers).filter((k) => k !== 'values');
}

function blockKeys (block) {
  return Object.keys(block || {}).filter((k) => k !== 'values');
}

// item -> { tier, pool } for every item in item_pools
function pooledItems (kv) {
  const result = {};
  const tiers = kv.neutral_items.neutral_tiers;
  tierKeys(kv).forEach((tier) => {
    const pools = tiers[tier].item_pools;
    blockKeys(pools).forEach((pool) => {
      const items = pools[pool].items ? pools[pool].items.values : {};
      Object.keys(items).forEach((item) => { result[item] = { tier, pool }; });
    });
  });
  return result;
}

test('before', function (t) {
  t.plan(6);
  oaaText = fs.readFileSync(OAA_FILE, { encoding: 'utf8' });
  oaa = parseKV(oaaText);
  t.ok(oaa.neutral_items, 'OAA neutral_items.txt parses');
  request.get({ url: VANILLA_URL }, function (err, result) {
    t.notOk(err, 'should fetch vanilla neutral_items.txt');
    vanilla = parseKV(result.body);
    t.ok(vanilla.neutral_items, 'vanilla neutral_items.txt parses');
  });
  Lib.dotaItems(function (err, result) {
    t.notOk(err, 'should fetch vanilla items');
    dotaItems = result;
  });
  Lib.items(function (err, result) {
    t.notOk(err, 'should read OAA items');
    Object.keys(result).forEach((file) => {
      const root = result[file].DOTAAbilities;
      if (!root) return;
      Object.keys(root.values || {}).forEach((key) => { oaaItems[key] = root.values[key]; });
      blockKeys(root).forEach((key) => { oaaItems[key] = root[key]; });
    });
    t.ok(Object.keys(oaaItems).length, 'should get a list of OAA items');
  });
});

test('neutral tiers use the same layout as vanilla', function (t) {
  const vanillaTier = vanilla.neutral_items.neutral_tiers[tierKeys(vanilla)[0]];
  const vanillaPools = blockKeys(vanillaTier.item_pools);
  const vanillaPoolSize = vanillaPools.length ? Object.keys(vanillaTier.item_pools[vanillaPools[0]].items.values).length : 0;
  tierKeys(oaa).forEach((tier) => {
    const data = oaa.neutral_items.neutral_tiers[tier];
    if (vanillaPools.length) {
      t.notOk(data.items, `tier ${tier} has no flat "items" list (vanilla uses "item_pools")`);
      t.deepEqual(blockKeys(data.item_pools).sort(), vanillaPools.slice().sort(), `tier ${tier} has the same pools as vanilla`);
      blockKeys(data.item_pools).forEach((pool) => {
        const block = data.item_pools[pool];
        t.ok(block.values && block.values.options, `tier ${tier} ${pool} sets "options"`);
        // same number of items per pool as vanilla (3), so every pool offers a real choice
        const count = block.items ? Object.keys(block.items.values).length : 0;
        t.equal(count, vanillaPoolSize, `tier ${tier} ${pool} has ${vanillaPoolSize} items like vanilla pools`);
      });
    } else {
      t.ok(data.items, `tier ${tier} has an "items" list like vanilla`);
    }
  });
  t.end();
});

test('every OAA neutral item exists', function (t) {
  const items = pooledItems(oaa);
  Object.keys(items).forEach((item) => {
    const def = oaaItems[item];
    const exists = def ? def !== 'REMOVE' : !!dotaItems[item];
    t.ok(exists, `${item} (tier ${items[item].tier}) is defined by OAA or vanilla and not removed`);
  });
  t.end();
});

test('every vanilla neutral is in OAA, replaced, or excluded on purpose', function (t) {
  const have = pooledItems(oaa);
  const replaced = {};
  for (const m of oaaText.matchAll(/"(item_[a-z0-9_]+)"\s+"\d+"\s*\/\/\s*(item_[a-z0-9_]+)/g)) {
    replaced[m[2]] = m[1];
  }
  Object.keys(pooledItems(vanilla)).forEach((item) => {
    const ok = have[item] || replaced[item] || EXCLUDED[item];
    t.ok(ok, `${item} is in OAA's pools, replaced by an OAA item, or listed in EXCLUDED`);
  });
  t.end();
});

// item -> true for every enhancement in any tier/category
function enhancements (kv) {
  const result = {};
  const tiers = kv.neutral_items.neutral_tiers;
  tierKeys(kv).forEach((tier) => {
    const enh = tiers[tier].enhancements;
    blockKeys(enh).forEach((category) => {
      Object.keys(enh[category].values || {}).forEach((item) => { result[item] = true; });
    });
  });
  return result;
}

test('every vanilla enhancement is in OAA or replaced', function (t) {
  const have = enhancements(oaa);
  const replaced = {};
  for (const m of oaaText.matchAll(/"(item_[a-z0-9_]+)"\s+"\d+"\s*\/\/\s*(item_[a-z0-9_]+)/g)) {
    replaced[m[2]] = m[1];
  }
  Object.keys(enhancements(vanilla)).forEach((item) => {
    t.ok(have[item] || replaced[item] || EXCLUDED[item], `${item} is in OAA's enhancements or replaced by an OAA one`);
  });
  t.end();
});

// tier -> { start_time, enh: { item: level } }
function enhancementTiers (kv) {
  const result = {};
  const tiers = kv.neutral_items.neutral_tiers;
  tierKeys(kv).forEach((tier) => {
    const enh = {};
    blockKeys(tiers[tier].enhancements).forEach((category) => {
      const values = tiers[tier].enhancements[category].values || {};
      Object.keys(values).forEach((item) => { enh[item] = Number(values[item]); });
    });
    result[tier] = { start: tiers[tier].values.start_time, enh };
  });
  return result;
}

test('enhancement levels exist on the item', function (t) {
  const tiers = enhancementTiers(oaa);
  Object.keys(tiers).forEach((tier) => {
    Object.keys(tiers[tier].enh).forEach((item) => {
      const def = (oaaItems[item] && oaaItems[item] !== 'REMOVE') ? oaaItems[item] : dotaItems[item];
      const max = Number((def && def.values && def.values.MaxLevel) || 1);
      t.ok(tiers[tier].enh[item] <= max, `tier ${tier} ${item} level ${tiers[tier].enh[item]} <= MaxLevel ${max}`);
    });
  });
  t.end();
});

test('tiers that start with a vanilla tier offer the same enhancements', function (t) {
  const replacedBy = {};
  for (const m of oaaText.matchAll(/"(item_[a-z0-9_]+)"\s+"\d+"\s*\/\/\s*(item_[a-z0-9_]+)/g)) {
    replacedBy[m[2]] = m[1];
  }
  const vanillaTiers = enhancementTiers(vanilla);
  const oaaTiers = enhancementTiers(oaa);
  Object.keys(oaaTiers).forEach((tier) => {
    const match = Object.keys(vanillaTiers).find((v) => vanillaTiers[v].start === oaaTiers[tier].start);
    if (!match) return; // OAA-only tier (e.g. 5:00), nothing to compare
    Object.keys(vanillaTiers[match].enh).forEach((item) => {
      const oaaItem = replacedBy[item] || item;
      t.ok(oaaItem in oaaTiers[tier].enh, `tier ${tier} (${oaaTiers[tier].start}) has ${oaaItem} like vanilla tier ${match}`);
      if (!replacedBy[item]) {
        t.equal(oaaTiers[tier].enh[item], vanillaTiers[match].enh[item], `tier ${tier} ${item} level matches vanilla tier ${match}`);
      }
    });
  });
  t.end();
});
