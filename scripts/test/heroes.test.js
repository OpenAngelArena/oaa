const test = require('tape');
const Lib = require('../kv-lib');

let heroes = null;
let dotaHeroes = null;
let dotaAbilities = null;
const abilities = {};
test('before', function (t) {
  t.plan(8);
  Lib.heroes(function (err, result) {
    t.notOk(err, 'should not error');
    t.ok(Object.keys(result).length, 'should get a list of heroes');
    heroes = result;
  });
  Lib.dotaHeroes(function (err, result) {
    t.notOk(err, 'should not error');
    t.ok(Object.keys(result).length, 'should get a list of dota heroes');
    dotaHeroes = result;
  });
  Lib.dotaAbilities(function (err, result) {
    t.notOk(err, 'should not error');
    t.ok(Object.keys(result).length, 'should get a list of dota abilities');
    dotaAbilities = result;
  });

  Lib.abilities(function (err, result) {
    t.notOk(err, 'should not error');
    t.ok(Object.keys(result).length, 'should get a list of abilities');
    Object.keys(result).forEach((fileName) => {
      Object.keys(result[fileName].DOTAAbilities).filter((v) => v !== 'values').forEach((ability) => {
        abilities[ability] = result[fileName].DOTAAbilities[ability];
      });
    });
  });
});

test('test', function (t) {
  Object.keys(heroes).forEach(function (file) {
    const data = heroes[file];
    t.test(file, function (t) {
      Object.keys(data.DOTAHeroes || data.DOTAUnits)
        .filter(a => a !== 'values')
        .forEach(function (heroName) {
          const hero = (data.DOTAHeroes || data.DOTAUnits)[heroName];
          const abilityMap = {};
          if (dotaHeroes[heroName]) {
            Object.keys(dotaHeroes[heroName].values)
              .filter(a => a.startsWith('Ability'))
              .forEach(function (ability) {
                abilityMap[ability] = dotaHeroes[heroName].values[ability];
              });
            Object.keys(hero.values)
              .filter(a => a.startsWith('Ability'))
              .forEach(function (ability) {
                const abilityName = hero.values[ability];
                const abilityComment = hero.comments[ability];
                const dotaAbility = dotaHeroes[heroName].values[ability];
                if (abilityComment && abilityComment.indexOf(dotaAbility) > -1) {
                  t.pass(abilityName + ' is overwriting ' + dotaAbility);
                } else {
                  t.equal(abilityName, dotaAbility, abilityName + ' cannot overwrite ' + dotaAbility + ' without naming it in comment');
                }
                abilityMap[ability] = abilityName;
              });
          }
          Object.keys(abilityMap).forEach(function (ability) {
            const abilityName = abilityMap[ability];
            t.equal(abilityName.indexOf('bonus_gold'), -1, 'do not allow gold income talents, ' + ability + ': ' + abilityName);
            t.equal(abilityName.indexOf('bonus_exp'), -1, 'do not allow gold income talents, ' + ability + ': ' + abilityName);

            const abilityMaxLevel = abilities[abilityName]?.values.MaxLevel || dotaAbilities[abilityName]?.values.MaxLevel;
            const abilityDependentOnAbility = abilities[abilityName]?.values.DependentOnAbility || dotaAbilities[abilityName]?.values.DependentOnAbility;
            if (abilityDependentOnAbility) {
              const dependAbilityMaxLevel = abilities[abilityDependentOnAbility]?.values.MaxLevel || dotaAbilities[abilityDependentOnAbility]?.values.MaxLevel;
              // console.log(dependAbilityMaxLevel);
              const foundAbilitySlot = Object.values(abilityMap).find((v) => v === abilityDependentOnAbility);
              const closeAbilitySlot = Object.values(abilityMap).find((v) => v.indexOf(abilityDependentOnAbility) > -1);
              const tipLine = closeAbilitySlot ? `... Did you mean ${closeAbilitySlot}?` : '';
              t.ok(foundAbilitySlot, `${abilityName} depends on ${abilityDependentOnAbility} but ${heroName} doesn't have that ability ${tipLine}`);
              if (abilityMaxLevel && dependAbilityMaxLevel) {
                t.equal(Number(abilityMaxLevel), Number(dependAbilityMaxLevel) + 1, `${abilityName} has ${abilityMaxLevel} max level, expected ${Number(dependAbilityMaxLevel) + 1} because it depends on ${abilityDependentOnAbility} which has ${dependAbilityMaxLevel} max level`);
              }
            }
          });
        });
      t.end();
    });
  });
});
