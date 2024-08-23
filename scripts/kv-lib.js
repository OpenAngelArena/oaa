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
  const urls = [
    'https://raw.githubusercontent.com/spirit-bear-productions/dota_vpk_updates/main/scripts/npc/heroes/npc_dota_hero_abaddon.txt',
    'https://raw.githubusercontent.com/spirit-bear-productions/dota_vpk_updates/main/scripts/npc/heroes/npc_dota_hero_abyssal_underlord.txt',
    'https://raw.githubusercontent.com/spirit-bear-productions/dota_vpk_updates/main/scripts/npc/heroes/npc_dota_hero_alchemist.txt',
    'https://raw.githubusercontent.com/spirit-bear-productions/dota_vpk_updates/main/scripts/npc/heroes/npc_dota_hero_ancient_apparition.txt',
    'https://raw.githubusercontent.com/spirit-bear-productions/dota_vpk_updates/main/scripts/npc/heroes/npc_dota_hero_antimage.txt',
    'https://raw.githubusercontent.com/spirit-bear-productions/dota_vpk_updates/main/scripts/npc/heroes/npc_dota_hero_arc_warden.txt',
    'https://raw.githubusercontent.com/spirit-bear-productions/dota_vpk_updates/main/scripts/npc/heroes/npc_dota_hero_axe.txt',
    'https://raw.githubusercontent.com/spirit-bear-productions/dota_vpk_updates/main/scripts/npc/heroes/npc_dota_hero_bane.txt',
    'https://raw.githubusercontent.com/spirit-bear-productions/dota_vpk_updates/main/scripts/npc/heroes/npc_dota_hero_batrider.txt',
    'https://raw.githubusercontent.com/spirit-bear-productions/dota_vpk_updates/main/scripts/npc/heroes/npc_dota_hero_beastmaster.txt',
    'https://raw.githubusercontent.com/spirit-bear-productions/dota_vpk_updates/main/scripts/npc/heroes/npc_dota_hero_bloodseeker.txt',
    'https://raw.githubusercontent.com/spirit-bear-productions/dota_vpk_updates/main/scripts/npc/heroes/npc_dota_hero_bounty_hunter.txt',
    'https://raw.githubusercontent.com/spirit-bear-productions/dota_vpk_updates/main/scripts/npc/heroes/npc_dota_hero_brewmaster.txt',
    'https://raw.githubusercontent.com/spirit-bear-productions/dota_vpk_updates/main/scripts/npc/heroes/npc_dota_hero_bristleback.txt',
    'https://raw.githubusercontent.com/spirit-bear-productions/dota_vpk_updates/main/scripts/npc/heroes/npc_dota_hero_broodmother.txt',
    'https://raw.githubusercontent.com/spirit-bear-productions/dota_vpk_updates/main/scripts/npc/heroes/npc_dota_hero_centaur.txt',
    'https://raw.githubusercontent.com/spirit-bear-productions/dota_vpk_updates/main/scripts/npc/heroes/npc_dota_hero_chaos_knight.txt',
    'https://raw.githubusercontent.com/spirit-bear-productions/dota_vpk_updates/main/scripts/npc/heroes/npc_dota_hero_chen.txt',
    'https://raw.githubusercontent.com/spirit-bear-productions/dota_vpk_updates/main/scripts/npc/heroes/npc_dota_hero_clinkz.txt',
    'https://raw.githubusercontent.com/spirit-bear-productions/dota_vpk_updates/main/scripts/npc/heroes/npc_dota_hero_crystal_maiden.txt',
    'https://raw.githubusercontent.com/spirit-bear-productions/dota_vpk_updates/main/scripts/npc/heroes/npc_dota_hero_dark_seer.txt',
    'https://raw.githubusercontent.com/spirit-bear-productions/dota_vpk_updates/main/scripts/npc/heroes/npc_dota_hero_dark_willow.txt',
    'https://raw.githubusercontent.com/spirit-bear-productions/dota_vpk_updates/main/scripts/npc/heroes/npc_dota_hero_dawnbreaker.txt',
    'https://raw.githubusercontent.com/spirit-bear-productions/dota_vpk_updates/main/scripts/npc/heroes/npc_dota_hero_dazzle.txt',
    'https://raw.githubusercontent.com/spirit-bear-productions/dota_vpk_updates/main/scripts/npc/heroes/npc_dota_hero_death_prophet.txt',
    'https://raw.githubusercontent.com/spirit-bear-productions/dota_vpk_updates/main/scripts/npc/heroes/npc_dota_hero_disruptor.txt',
    'https://raw.githubusercontent.com/spirit-bear-productions/dota_vpk_updates/main/scripts/npc/heroes/npc_dota_hero_doom_bringer.txt',
    'https://raw.githubusercontent.com/spirit-bear-productions/dota_vpk_updates/main/scripts/npc/heroes/npc_dota_hero_dragon_knight.txt',
    'https://raw.githubusercontent.com/spirit-bear-productions/dota_vpk_updates/main/scripts/npc/heroes/npc_dota_hero_drow_ranger.txt',
    'https://raw.githubusercontent.com/spirit-bear-productions/dota_vpk_updates/main/scripts/npc/heroes/npc_dota_hero_earth_spirit.txt',
    'https://raw.githubusercontent.com/spirit-bear-productions/dota_vpk_updates/main/scripts/npc/heroes/npc_dota_hero_earthshaker.txt',
    'https://raw.githubusercontent.com/spirit-bear-productions/dota_vpk_updates/main/scripts/npc/heroes/npc_dota_hero_elder_titan.txt',
    'https://raw.githubusercontent.com/spirit-bear-productions/dota_vpk_updates/main/scripts/npc/heroes/npc_dota_hero_ember_spirit.txt',
    'https://raw.githubusercontent.com/spirit-bear-productions/dota_vpk_updates/main/scripts/npc/heroes/npc_dota_hero_enchantress.txt',
    'https://raw.githubusercontent.com/spirit-bear-productions/dota_vpk_updates/main/scripts/npc/heroes/npc_dota_hero_enigma.txt',
    'https://raw.githubusercontent.com/spirit-bear-productions/dota_vpk_updates/main/scripts/npc/heroes/npc_dota_hero_faceless_void.txt',
    'https://raw.githubusercontent.com/spirit-bear-productions/dota_vpk_updates/main/scripts/npc/heroes/npc_dota_hero_furion.txt',
    'https://raw.githubusercontent.com/spirit-bear-productions/dota_vpk_updates/main/scripts/npc/heroes/npc_dota_hero_grimstroke.txt',
    'https://raw.githubusercontent.com/spirit-bear-productions/dota_vpk_updates/main/scripts/npc/heroes/npc_dota_hero_gyrocopter.txt',
    'https://raw.githubusercontent.com/spirit-bear-productions/dota_vpk_updates/main/scripts/npc/heroes/npc_dota_hero_hoodwink.txt',
    'https://raw.githubusercontent.com/spirit-bear-productions/dota_vpk_updates/main/scripts/npc/heroes/npc_dota_hero_huskar.txt',
    'https://raw.githubusercontent.com/spirit-bear-productions/dota_vpk_updates/main/scripts/npc/heroes/npc_dota_hero_invoker.txt',
    'https://raw.githubusercontent.com/spirit-bear-productions/dota_vpk_updates/main/scripts/npc/heroes/npc_dota_hero_jakiro.txt',
    'https://raw.githubusercontent.com/spirit-bear-productions/dota_vpk_updates/main/scripts/npc/heroes/npc_dota_hero_juggernaut.txt',
    'https://raw.githubusercontent.com/spirit-bear-productions/dota_vpk_updates/main/scripts/npc/heroes/npc_dota_hero_keeper_of_the_light.txt',
    'https://raw.githubusercontent.com/spirit-bear-productions/dota_vpk_updates/main/scripts/npc/heroes/npc_dota_hero_kunkka.txt',
    'https://raw.githubusercontent.com/spirit-bear-productions/dota_vpk_updates/main/scripts/npc/heroes/npc_dota_hero_legion_commander.txt',
    'https://raw.githubusercontent.com/spirit-bear-productions/dota_vpk_updates/main/scripts/npc/heroes/npc_dota_hero_leshrac.txt',
    'https://raw.githubusercontent.com/spirit-bear-productions/dota_vpk_updates/main/scripts/npc/heroes/npc_dota_hero_lich.txt',
    'https://raw.githubusercontent.com/spirit-bear-productions/dota_vpk_updates/main/scripts/npc/heroes/npc_dota_hero_life_stealer.txt',
    'https://raw.githubusercontent.com/spirit-bear-productions/dota_vpk_updates/main/scripts/npc/heroes/npc_dota_hero_lina.txt',
    'https://raw.githubusercontent.com/spirit-bear-productions/dota_vpk_updates/main/scripts/npc/heroes/npc_dota_hero_lion.txt',
    'https://raw.githubusercontent.com/spirit-bear-productions/dota_vpk_updates/main/scripts/npc/heroes/npc_dota_hero_lone_druid.txt',
    'https://raw.githubusercontent.com/spirit-bear-productions/dota_vpk_updates/main/scripts/npc/heroes/npc_dota_hero_luna.txt',
    'https://raw.githubusercontent.com/spirit-bear-productions/dota_vpk_updates/main/scripts/npc/heroes/npc_dota_hero_lycan.txt',
    'https://raw.githubusercontent.com/spirit-bear-productions/dota_vpk_updates/main/scripts/npc/heroes/npc_dota_hero_magnataur.txt',
    'https://raw.githubusercontent.com/spirit-bear-productions/dota_vpk_updates/main/scripts/npc/heroes/npc_dota_hero_marci.txt',
    'https://raw.githubusercontent.com/spirit-bear-productions/dota_vpk_updates/main/scripts/npc/heroes/npc_dota_hero_mars.txt',
    'https://raw.githubusercontent.com/spirit-bear-productions/dota_vpk_updates/main/scripts/npc/heroes/npc_dota_hero_medusa.txt',
    'https://raw.githubusercontent.com/spirit-bear-productions/dota_vpk_updates/main/scripts/npc/heroes/npc_dota_hero_meepo.txt',
    'https://raw.githubusercontent.com/spirit-bear-productions/dota_vpk_updates/main/scripts/npc/heroes/npc_dota_hero_mirana.txt',
    'https://raw.githubusercontent.com/spirit-bear-productions/dota_vpk_updates/main/scripts/npc/heroes/npc_dota_hero_monkey_king.txt',
    'https://raw.githubusercontent.com/spirit-bear-productions/dota_vpk_updates/main/scripts/npc/heroes/npc_dota_hero_morphling.txt',
    'https://raw.githubusercontent.com/spirit-bear-productions/dota_vpk_updates/main/scripts/npc/heroes/npc_dota_hero_muerta.txt',
    'https://raw.githubusercontent.com/spirit-bear-productions/dota_vpk_updates/main/scripts/npc/heroes/npc_dota_hero_naga_siren.txt',
    'https://raw.githubusercontent.com/spirit-bear-productions/dota_vpk_updates/main/scripts/npc/heroes/npc_dota_hero_necrolyte.txt',
    'https://raw.githubusercontent.com/spirit-bear-productions/dota_vpk_updates/main/scripts/npc/heroes/npc_dota_hero_nevermore.txt',
    'https://raw.githubusercontent.com/spirit-bear-productions/dota_vpk_updates/main/scripts/npc/heroes/npc_dota_hero_night_stalker.txt',
    'https://raw.githubusercontent.com/spirit-bear-productions/dota_vpk_updates/main/scripts/npc/heroes/npc_dota_hero_nyx_assassin.txt',
    'https://raw.githubusercontent.com/spirit-bear-productions/dota_vpk_updates/main/scripts/npc/heroes/npc_dota_hero_obsidian_destroyer.txt',
    'https://raw.githubusercontent.com/spirit-bear-productions/dota_vpk_updates/main/scripts/npc/heroes/npc_dota_hero_ogre_magi.txt',
    'https://raw.githubusercontent.com/spirit-bear-productions/dota_vpk_updates/main/scripts/npc/heroes/npc_dota_hero_omniknight.txt',
    'https://raw.githubusercontent.com/spirit-bear-productions/dota_vpk_updates/main/scripts/npc/heroes/npc_dota_hero_oracle.txt',
    'https://raw.githubusercontent.com/spirit-bear-productions/dota_vpk_updates/main/scripts/npc/heroes/npc_dota_hero_pangolier.txt',
    'https://raw.githubusercontent.com/spirit-bear-productions/dota_vpk_updates/main/scripts/npc/heroes/npc_dota_hero_phantom_assassin.txt',
    'https://raw.githubusercontent.com/spirit-bear-productions/dota_vpk_updates/main/scripts/npc/heroes/npc_dota_hero_phantom_lancer.txt',
    'https://raw.githubusercontent.com/spirit-bear-productions/dota_vpk_updates/main/scripts/npc/heroes/npc_dota_hero_phoenix.txt',
    'https://raw.githubusercontent.com/spirit-bear-productions/dota_vpk_updates/main/scripts/npc/heroes/npc_dota_hero_primal_beast.txt',
    'https://raw.githubusercontent.com/spirit-bear-productions/dota_vpk_updates/main/scripts/npc/heroes/npc_dota_hero_puck.txt',
    'https://raw.githubusercontent.com/spirit-bear-productions/dota_vpk_updates/main/scripts/npc/heroes/npc_dota_hero_pudge.txt',
    'https://raw.githubusercontent.com/spirit-bear-productions/dota_vpk_updates/main/scripts/npc/heroes/npc_dota_hero_pugna.txt',
    'https://raw.githubusercontent.com/spirit-bear-productions/dota_vpk_updates/main/scripts/npc/heroes/npc_dota_hero_queenofpain.txt',
    'https://raw.githubusercontent.com/spirit-bear-productions/dota_vpk_updates/main/scripts/npc/heroes/npc_dota_hero_rattletrap.txt',
    'https://raw.githubusercontent.com/spirit-bear-productions/dota_vpk_updates/main/scripts/npc/heroes/npc_dota_hero_razor.txt',
    'https://raw.githubusercontent.com/spirit-bear-productions/dota_vpk_updates/main/scripts/npc/heroes/npc_dota_hero_riki.txt',
    'https://raw.githubusercontent.com/spirit-bear-productions/dota_vpk_updates/main/scripts/npc/heroes/npc_dota_hero_rubick.txt',
    'https://raw.githubusercontent.com/spirit-bear-productions/dota_vpk_updates/main/scripts/npc/heroes/npc_dota_hero_sand_king.txt',
    'https://raw.githubusercontent.com/spirit-bear-productions/dota_vpk_updates/main/scripts/npc/heroes/npc_dota_hero_shadow_demon.txt',
    'https://raw.githubusercontent.com/spirit-bear-productions/dota_vpk_updates/main/scripts/npc/heroes/npc_dota_hero_shadow_shaman.txt',
    'https://raw.githubusercontent.com/spirit-bear-productions/dota_vpk_updates/main/scripts/npc/heroes/npc_dota_hero_shredder.txt',
    'https://raw.githubusercontent.com/spirit-bear-productions/dota_vpk_updates/main/scripts/npc/heroes/npc_dota_hero_silencer.txt',
    'https://raw.githubusercontent.com/spirit-bear-productions/dota_vpk_updates/main/scripts/npc/heroes/npc_dota_hero_skeleton_king.txt',
    'https://raw.githubusercontent.com/spirit-bear-productions/dota_vpk_updates/main/scripts/npc/heroes/npc_dota_hero_skywrath_mage.txt',
    'https://raw.githubusercontent.com/spirit-bear-productions/dota_vpk_updates/main/scripts/npc/heroes/npc_dota_hero_slardar.txt',
    'https://raw.githubusercontent.com/spirit-bear-productions/dota_vpk_updates/main/scripts/npc/heroes/npc_dota_hero_slark.txt',
    'https://raw.githubusercontent.com/spirit-bear-productions/dota_vpk_updates/main/scripts/npc/heroes/npc_dota_hero_snapfire.txt',
    'https://raw.githubusercontent.com/spirit-bear-productions/dota_vpk_updates/main/scripts/npc/heroes/npc_dota_hero_sniper.txt',
    'https://raw.githubusercontent.com/spirit-bear-productions/dota_vpk_updates/main/scripts/npc/heroes/npc_dota_hero_spectre.txt',
    'https://raw.githubusercontent.com/spirit-bear-productions/dota_vpk_updates/main/scripts/npc/heroes/npc_dota_hero_spirit_breaker.txt',
    'https://raw.githubusercontent.com/spirit-bear-productions/dota_vpk_updates/main/scripts/npc/heroes/npc_dota_hero_storm_spirit.txt',
    'https://raw.githubusercontent.com/spirit-bear-productions/dota_vpk_updates/main/scripts/npc/heroes/npc_dota_hero_sven.txt',
    'https://raw.githubusercontent.com/spirit-bear-productions/dota_vpk_updates/main/scripts/npc/heroes/npc_dota_hero_techies.txt',
    'https://raw.githubusercontent.com/spirit-bear-productions/dota_vpk_updates/main/scripts/npc/heroes/npc_dota_hero_templar_assassin.txt',
    'https://raw.githubusercontent.com/spirit-bear-productions/dota_vpk_updates/main/scripts/npc/heroes/npc_dota_hero_terrorblade.txt',
    'https://raw.githubusercontent.com/spirit-bear-productions/dota_vpk_updates/main/scripts/npc/heroes/npc_dota_hero_tidehunter.txt',
    'https://raw.githubusercontent.com/spirit-bear-productions/dota_vpk_updates/main/scripts/npc/heroes/npc_dota_hero_tinker.txt',
    'https://raw.githubusercontent.com/spirit-bear-productions/dota_vpk_updates/main/scripts/npc/heroes/npc_dota_hero_tiny.txt',
    'https://raw.githubusercontent.com/spirit-bear-productions/dota_vpk_updates/main/scripts/npc/heroes/npc_dota_hero_treant.txt',
    'https://raw.githubusercontent.com/spirit-bear-productions/dota_vpk_updates/main/scripts/npc/heroes/npc_dota_hero_troll_warlord.txt',
    'https://raw.githubusercontent.com/spirit-bear-productions/dota_vpk_updates/main/scripts/npc/heroes/npc_dota_hero_tusk.txt',
    'https://raw.githubusercontent.com/spirit-bear-productions/dota_vpk_updates/main/scripts/npc/heroes/npc_dota_hero_undying.txt',
    'https://raw.githubusercontent.com/spirit-bear-productions/dota_vpk_updates/main/scripts/npc/heroes/npc_dota_hero_ursa.txt',
    'https://raw.githubusercontent.com/spirit-bear-productions/dota_vpk_updates/main/scripts/npc/heroes/npc_dota_hero_vengefulspirit.txt',
    'https://raw.githubusercontent.com/spirit-bear-productions/dota_vpk_updates/main/scripts/npc/heroes/npc_dota_hero_venomancer.txt',
    'https://raw.githubusercontent.com/spirit-bear-productions/dota_vpk_updates/main/scripts/npc/heroes/npc_dota_hero_viper.txt',
    'https://raw.githubusercontent.com/spirit-bear-productions/dota_vpk_updates/main/scripts/npc/heroes/npc_dota_hero_visage.txt',
    'https://raw.githubusercontent.com/spirit-bear-productions/dota_vpk_updates/main/scripts/npc/heroes/npc_dota_hero_void_spirit.txt',
    'https://raw.githubusercontent.com/spirit-bear-productions/dota_vpk_updates/main/scripts/npc/heroes/npc_dota_hero_warlock.txt',
    'https://raw.githubusercontent.com/spirit-bear-productions/dota_vpk_updates/main/scripts/npc/heroes/npc_dota_hero_weaver.txt',
    'https://raw.githubusercontent.com/spirit-bear-productions/dota_vpk_updates/main/scripts/npc/heroes/npc_dota_hero_windrunner.txt',
    'https://raw.githubusercontent.com/spirit-bear-productions/dota_vpk_updates/main/scripts/npc/heroes/npc_dota_hero_winter_wyvern.txt',
    'https://raw.githubusercontent.com/spirit-bear-productions/dota_vpk_updates/main/scripts/npc/heroes/npc_dota_hero_wisp.txt',
    'https://raw.githubusercontent.com/spirit-bear-productions/dota_vpk_updates/main/scripts/npc/heroes/npc_dota_hero_witch_doctor.txt',
    'https://raw.githubusercontent.com/spirit-bear-productions/dota_vpk_updates/main/scripts/npc/heroes/npc_dota_hero_zuus.txt',
    'https://raw.githubusercontent.com/spirit-bear-productions/dota_vpk_updates/main/scripts/npc/heroes/npc_dota_hero_ringmaster.txt',
    'https://raw.githubusercontent.com/spirit-bear-productions/dota_vpk_updates/main/scripts/npc/npc_abilities.txt'
  ];
  let finalResult = {};
  let counter = 0;
  for (let i = 0; i < urls.length; i++) {
    request.get({
      url: urls[i]
    }, function (err, response, body) {
      if (err) {
        cb(err);
      }
      const data = parseKV(body);
      finalResult = { ...finalResult, ...data.DOTAAbilities };
      counter++;
      if (counter === urls.length) {
        cb(null, finalResult);
      }
    });
  }
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
    const data = parseKV(result.body.replace('}\t\t}', '}\n\t\t}'));
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
