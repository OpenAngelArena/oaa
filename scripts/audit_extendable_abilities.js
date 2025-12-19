#!/usr/bin/env node
/*
  Finds hero abilities from vanilla cache that should be extended in OAA
  (i.e., abilities with levels > 1) but currently have no _oaa file,
  no override entry, and no hero-slot replacement to an _oaa ability.

  Output: newline-separated CSV
    hero,slot,ability,maxLevel,reason
*/
const fs = require('fs');
const path = require('path');

const ROOT = path.join(__dirname, '..');
const VAN_ABIL = path.join(ROOT, 'scripts', 'cache', 'dota_kv', 'npc_abilities.txt');
const VAN_HERO_DIR = path.join(ROOT, 'scripts', 'cache', 'dota_kv');
const OUR_ABIL_DIR = path.join(ROOT, 'game', 'scripts', 'npc', 'abilities');
const OUR_OVERRIDE = path.join(ROOT, 'game', 'scripts', 'npc', 'npc_abilities_override.txt');

function readFileSafe (p) { try { return fs.readFileSync(p, 'utf8'); } catch { return ''; } }

function parseKVTopBlocks (text, rootKey) {
  const blocks = {};
  const lines = text.split(/\r?\n/);
  let i = 0; let depth = 0; let inRoot = false; let current = null;
  while (i < lines.length) {
    let raw = lines[i++];
    raw = raw.replace(/\t/g, '  ');
    const line = raw.split('//')[0];
    if (!line.trim()) continue;
    if (!inRoot) {
      if (line.includes('"' + rootKey + '"')) { inRoot = true; continue; }
      continue;
    }
    // Track braces
    const opens = (line.match(/\{/g) || []).length;
    const closes = (line.match(/\}/g) || []).length;
    // If we're at depth 1 and see a quoted key with no trailing value, treat as new block key
    const keyMatch = line.match(/^\s*"([^"]+)"\s*$/);
    if (keyMatch && depth === 1) {
      current = keyMatch[1];
      blocks[current] = [];
    } else if (current && depth >= 2) {
      blocks[current].push(line.trim());
    }
    depth += opens - closes;
    if (depth === 0 && inRoot) { break; }
    // no-op
  }
  return blocks;
}

function parseAbilities (filePath) {
  const text = readFileSafe(filePath);
  const blocks = parseKVTopBlocks(text, 'DOTAAbilities');
  const map = {};
  for (const [name, lines] of Object.entries(blocks)) {
    if (name === 'Version') continue;
    let max = null;
    let hasMultiValues = false;
    let hasScaling = false;
    for (const l of lines) {
      const m = l.match(/"MaxLevel"\s*"(\d+)"/);
      if (m) max = parseInt(m[1], 10);
      const mv = l.match(/"((?:Ability[A-Za-z_]+)|value)"\s*"([^"]+)"/);
      if (mv) {
        const raw = mv[2].trim();
        const nums = raw.match(/-?\d+(?:\.\d+)?/g) || [];
        if (nums.length >= 2) {
          hasMultiValues = true;
          const first = nums[0];
          if (nums.some(n => n !== first)) hasScaling = true;
        }
      }
    }
    map[name] = { MaxLevel: max, HasLevels: max != null ? max > 1 : hasMultiValues, HasScaling: hasScaling };
  }
  return map;
}

// (parseHeroAbilities no longer needed in current audit)

function main () {
  // Build ability metadata from the monolithic abilities file
  const abilMeta = parseAbilities(VAN_ABIL);
  const ourOverrideTxt = readFileSafe(OUR_OVERRIDE);
  // Consider ability overridden if override includes its file via #base or defines a nearby inline block
  const overrideHas = (name) => {
    const inc = `#base "abilities/${name}.txt"`;
    if (ourOverrideTxt.includes(inc)) return true;
    const pos = ourOverrideTxt.indexOf(`"${name}"`);
    if (pos === -1) return false;
    const brace = ourOverrideTxt.indexOf('{', pos);
    return brace !== -1 && brace - pos < 200; // heuristic: inline block soon after name
  };

  // Vanilla hero ability definitions from cache: gather ability names per hero
  const heroFiles = fs.readdirSync(VAN_HERO_DIR).filter(f => f.startsWith('npc_dota_hero_') && f.endsWith('.txt'));
  const heroAbilities = {};
  for (const f of heroFiles) {
    const p = path.join(VAN_HERO_DIR, f);
    const txt = readFileSafe(p);
    const blocks = parseKVTopBlocks(txt, 'DOTAAbilities');
    const hero = Object.keys(blocks).length ? f.replace(/\.txt$/, '') : null;
    if (!hero) continue;
    heroAbilities[hero] = Object.keys(blocks).filter(name => name !== 'Version');
    // Merge per-hero ability metadata (for games where monolithic file lacks entries)
    for (const [name, lines] of Object.entries(blocks)) {
      if (name === 'Version') continue;
      if (!abilMeta[name]) {
        let max = null; let hasMultiValues = false; let hasScaling = false;
        for (const l of lines) {
          const m = l.match(/"MaxLevel"\s*"(\d+)"/);
          if (m) max = parseInt(m[1], 10);
          const mv = l.match(/"((?:Ability[A-Za-z_]+)|value)"\s*"([^"]+)"/);
          if (mv) {
            const raw = mv[2].trim();
            const nums = raw.match(/-?\d+(?:\.\d+)?/g) || [];
            if (nums.length >= 2) {
              hasMultiValues = true;
              const first = nums[0];
              if (nums.some(n => n !== first)) hasScaling = true;
            }
          }
        }
        abilMeta[name] = { MaxLevel: max, HasLevels: max != null ? max > 1 : hasMultiValues, HasScaling: hasScaling };
      }
    }
  }
  // Our hero overrides not needed for current checks

  const EXCLUDED = new Set(['', 'generic_hidden', 'attribute_bonus', 'empty']);
  const TAL = 'special_bonus_';
  const rows = [];
  const rowsNoLocalFile = [];

  for (const [hero, abilities] of Object.entries(heroAbilities)) {
    for (const ability of abilities) {
      if (!ability || EXCLUDED.has(ability)) continue;
      if (ability.startsWith(TAL)) continue;
      const meta = abilMeta[ability] || {};
      const hasLevels = !!meta.HasLevels;
      const hasScaling = !!meta.HasScaling;
      if (!hasLevels || !hasScaling) continue;
      const oaaPath = path.join(OUR_ABIL_DIR, `${ability}_oaa.txt`);
      const hasOaa = fs.existsSync(oaaPath);
      const hasOverride = overrideHas(ability);
      const basePath = path.join(OUR_ABIL_DIR, `${ability}.txt`);
      const hasBase = fs.existsSync(basePath);
      // If we have a base file, see if it already has OAA levels (MaxLevel>=5 or multi-values length>4)
      let baseExtended = false;
      if (hasBase) {
        const baseBlocks = parseKVTopBlocks(readFileSafe(basePath), 'DOTAAbilities');
        const lines = baseBlocks[ability] || [];
        let baseMax = null; let baseHasLongArray = false;
        for (const l of lines) {
          const m = l.match(/"MaxLevel"\s*"(\d+)"/);
          if (m) baseMax = parseInt(m[1], 10);
          const mv = l.match(/"(AbilityManaCost|AbilityCooldown|AbilityCastRange|value)"\s*"([^"]+)"/);
          if (mv) {
            const arr = mv[2].trim().split(/\s+/);
            if (arr.length > 4) baseHasLongArray = true;
          }
        }
        baseExtended = (baseMax != null && baseMax >= 5) || baseHasLongArray;
      }
      if (!hasOaa && !hasOverride && !baseExtended) {
        const kind = hasBase ? 'missing_oaa' : 'missing_file';
        (hasBase ? rows : rowsNoLocalFile).push([hero, '', ability, String(meta.MaxLevel ?? ''), kind]);
      }
    }
  }
  rows.sort((a, b) => (a[2] + a[0]).localeCompare(b[2] + b[0]));
  rowsNoLocalFile.sort((a, b) => (a[2] + a[0]).localeCompare(b[2] + b[0]));
  // Print rows with no local file first, then the rest
  for (const r of rowsNoLocalFile) console.log(r.join(','));
  for (const r of rows) console.log(r.join(','));
  if (rows.length + rowsNoLocalFile.length === 0) console.error('No missing extensions detected.');
}

main();
