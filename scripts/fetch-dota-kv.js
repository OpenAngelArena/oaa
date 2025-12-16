#!/usr/bin/env node
/*
 Downloads and caches base Dota KV files used by unit tests:
 - dota/scripts/npc/items.txt
 - dota/scripts/npc/npc_heroes.txt
 - dota/scripts/npc/heroes/*.txt

 Files are saved under scripts/cache/dota_kv/ and ignored by git.
*/

const fs = require('fs');
const path = require('path');
const request = require('request');

const repoRoot = path.join(__dirname, '..');
const cacheDir = path.join(__dirname, 'cache', 'dota_kv');

// Ensure target directory exists
fs.mkdirSync(cacheDir, { recursive: true });

function download (url, outPath) {
  return new Promise((resolve, reject) => {
    const stream = request.get({ url });
    stream.on('response', (res) => {
      if (res.statusCode !== 200) {
        reject(new Error(`HTTP ${res.statusCode} for ${url}`));
      }
    });
    stream.on('error', reject);
    const file = fs.createWriteStream(outPath);
    file.on('error', reject);
    file.on('finish', () => resolve(outPath));
    stream.pipe(file);
  });
}

function extractHeroUrlsFromKvLib () {
  const kvLibPath = path.join(__dirname, 'kv-lib.js');
  const src = fs.readFileSync(kvLibPath, 'utf8');
  // Grab the urls array inside function dotaAbilities
  const m = src.match(/function\s+dotaAbilities\s*\(cb\)\s*\{[\s\S]*?const\s+urls\s*=\s*\[([\s\S]*?)\];/);
  if (!m) return [];
  const inner = m[1];
  const urls = [];
  const re = /(https?:[^'"\s]+\.txt)/g;
  let match;
  while ((match = re.exec(inner)) !== null) {
    urls.push(match[1]);
  }
  return urls;
}

function extractSingleUrlFromFunction (src, funcName) {
  const safe = funcName.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
  // Search inside the function body for the first request.get({ url: '...' }) occurrence
  const re = new RegExp(`function\\s+${safe}\\s*\\(cb\\)\\s*\\{[\\s\\S]*?url:\\s*'([^']+)'`, 'm');
  const m = src.match(re);
  return m ? m[1] : null;
}

async function main () {
  console.log('Preparing to download base Dota KV files...');
  const kvLibPath = path.join(__dirname, 'kv-lib.js');
  const src = fs.readFileSync(kvLibPath, 'utf8');

  const itemsUrl = extractSingleUrlFromFunction(src, 'dotaItems');
  const heroesUrl = extractSingleUrlFromFunction(src, 'dotaHeroes');
  const heroUrls = extractHeroUrlsFromKvLib();

  if (!itemsUrl || !heroesUrl || heroUrls.length === 0) {
    console.error('Failed to parse URLs from scripts/kv-lib.js');
    process.exitCode = 1;
    return;
  }

  // Also fetch base localization used by tests
  const localizationUrls = [
    'https://raw.githubusercontent.com/dotabuff/d2vpkr/refs/heads/master/dota/resource/localization/dota_english.txt',
    'https://raw.githubusercontent.com/dotabuff/d2vpkr/refs/heads/master/dota/resource/localization/abilities_english.txt'
  ];

  const plan = [
    { url: itemsUrl, out: path.join(cacheDir, path.basename(itemsUrl)) },
    { url: heroesUrl, out: path.join(cacheDir, path.basename(heroesUrl)) },
    ...heroUrls.map((url) => ({ url, out: path.join(cacheDir, path.basename(url)) })),
    ...localizationUrls.map((url) => ({ url, out: path.join(cacheDir, path.basename(url)) }))
  ];

  console.log(`Found ${plan.length} files to download.`);

  let completed = 0;
  for (const { url, out } of plan) {
    try {
      await download(url, out);
      completed++;
      if (completed % 10 === 0 || completed === plan.length) {
        console.log(`Downloaded ${completed}/${plan.length}`);
      }
    } catch (err) {
      console.error(`Failed to download ${url}:`, err.message);
      process.exitCode = 1;
    }
  }

  if (process.exitCode) {
    console.error('Completed with errors. Some files may be missing.');
  } else {
    console.log('All base Dota KV files cached at:', path.relative(repoRoot, cacheDir));
  }
}

main().catch((err) => {
  console.error(err);
  process.exitCode = 1;
});
