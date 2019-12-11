const test = require('tape');
var Lib = require('../kv-lib');

var heroes = null;
var dotaHeroes = null;
test('before', function (t) {
  t.plan(4);
  Lib.heroes(function (err, result) {
    t.notOk(err, 'should not error');
    t.ok(Object.keys(result).length, 'should get a list of heroes');
    heroes = result;
  });
  Lib.dotaHeroes(function (err, result) {
    t.notOk(err, 'should not error');
    t.ok(Object.keys(result).length, 'should get a list of heroes');
    dotaHeroes = result;
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
          var abilityMap = {};
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
          });
        });
      t.end();
    });
  });
});
