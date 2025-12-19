#!/usr/bin/env node
/*
  Scans hero KV files for abilities that are still using vanilla names (no _oaa),
  excluding talents and placeholders. Prints a newline-separated list of ability
  usages in the form: <hero_file>: <slot>=<ability>
*/
const fs = require('fs');
const path = require('path');

const ROOT = path.join(__dirname, '..');
const HEROES_DIR = path.join(ROOT, 'game', 'scripts', 'npc', 'heroes');
const VANILLA_ABILITIES_FILE = path.join(ROOT, 'scripts', 'cache', 'dota_kv', 'npc_abilities.txt');

function listHeroFiles (dir) {
  return fs.readdirSync(dir).filter(f => f.endsWith('.txt'));
}

const TALENT_PREFIX = 'special_bonus_';
const EXCLUDED = new Set(['', 'generic_hidden', 'attribute_bonus']);

function extractAbilities (filePath) {
  const text = fs.readFileSync(filePath, 'utf8');
  const lines = text.split(/\r?\n/);
  const abilities = [];
  for (const line of lines) {
    // Strip comments
    const noComment = line.split('//')[0];
    const m = noComment.match(/"(Ability\d+)"\s*"([^"]*)"/);
    if (m) {
      abilities.push({ slot: m[1], name: m[2] });
    }
  }
  return abilities;
}

function main () {
  // Build set of vanilla ability names from cache
  const vanilla = new Set();
  if (fs.existsSync(VANILLA_ABILITIES_FILE)) {
    const txt = fs.readFileSync(VANILLA_ABILITIES_FILE, 'utf8');
    // Very simple KV parse: look for top-level keys in the Abilities block
    // Assumes lines like: "antimage_blink"
    let inAbilities = false;
    for (const rawLine of txt.split(/\r?\n/)) {
      const line = rawLine.split('//')[0].trim();
      if (!line) continue;
      if (!inAbilities && line.startsWith('"DOTAAbilities"')) { inAbilities = true; continue; }
      if (inAbilities) {
        const m = line.match(/^"([^"]+)"\s*$/);
        if (m && !m[1].startsWith('Version')) {
          vanilla.add(m[1]);
        }
      }
    }
  }
  const files = listHeroFiles(HEROES_DIR);
  const results = [];
  for (const f of files) {
    const filePath = path.join(HEROES_DIR, f);
    const abs = extractAbilities(filePath);
    for (const a of abs) {
      const name = a.name.trim();
      if (EXCLUDED.has(name)) continue;
      if (!name) continue;
      if (name.includes('_oaa')) continue;
      if (name.startsWith(TALENT_PREFIX)) continue;
      // ignore plain placeholders
      if (name === 'empty' || name === 'attribute_bonus') continue;
      // Only consider vanilla dota abilities
      if (!vanilla.has(name)) continue;
      results.push({ file: f, slot: a.slot, ability: name });
    }
  }
  results.sort((x, y) => (x.file + x.slot).localeCompare(y.file + y.slot));
  for (const r of results) {
    process.stdout.write(`${r.file}: ${r.slot}=${r.ability}\n`);
  }
}

main();
