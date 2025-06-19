const test = require('tape');
const Lib = require('../kv-lib');
const path = require('path');
const fs = require('fs');
const after = require('after');
const spok = require('spok');
const extend = require('xtend');
const partial = require('ap').partial;

let dotaItems = null;
// let dotaItemIDs = null;
let dotaAbilities = null;
let dotaItemList = null;
let dotaAbilityList = null;
const allowedIconNames = [
  'item_recipe'
];
const ignoredBaseClasses = [
  'special_bonus_undefined',
  'special_bonus_base',
  'item_abyssal_blade',
  'item_armlet',
  'item_assault',
  'item_bfury',
  'item_bloodthorn',
  'item_crimson_guard',
  'item_disperser',
  'item_eternal_shroud',
  'item_ethereal_blade',
  'item_glimmer_cape',
  'item_greater_crit',
  'item_gungir',
  'item_harpoon',
  'item_heavens_halberd',
  'item_helm_of_the_overlord',
  'item_hurricane_pike',
  'item_kaya_and_sange',
  'item_lotus_orb',
  'item_manta',
  'item_mjollnir',
  'item_monkey_king_bar',
  'item_nullifier',
  'item_octarine_core',
  'item_pipe',
  'item_radiance',
  'item_revenants_brooch',
  'item_sange_and_yasha',
  'item_satanic',
  'item_sheepstick',
  'item_shivas_guard',
  'item_silver_edge',
  'item_skadi',
  'item_solar_crest',
  'item_sphere',
  'item_wind_waker',
  'item_yasha_and_kaya',
  'item_arcane_blink',
  'item_overwhelming_blink',
  'item_swift_blink',
  'item_blink',
  'item_devastator',
  'item_angels_demise'
];
let itemsFound = {};
// const idsFound = {};
const itemFileMap = {};
// let nextAvailableId = 3500;
// const usedIDs = {};
const specialValuesForItem = {};
const abilityValuesForItem = {};
const ignoreValuesFor = [
  'item_platemail',
  'item_ultimate_orb',
  'item_boots',
  'item_gem',
  'item_talisman_of_evasion',
  'item_clarity',
  'item_dust',
  'item_ward_observer',
  'item_ward_sentry',
  'item_tpscroll',
  'item_demon_edge',
  'item_eagle',
  'item_reaver',
  'item_relic',
  'item_hyperstone',
  'item_ring_of_health',
  'item_void_stone',
  'item_mystic_staff',
  'item_energy_booster',
  'item_point_booster',
  'item_vitality_booster',
  'item_enchanted_mango',
  'item_infused_raindrop',
  'item_nether_shawl',
  'item_aghanims_shard',
  'item_cornucopia',
  'item_ring_of_tarrasque',
  'item_tiara_of_selemene',
  'item_smoke_of_deceit',
  'centaur_stampede',
  'templar_assassin_psi_blades'
  // 'shredder_chakram',
  // 'shredder_chakram_2',
  // 'tiny_grow',
];

test('KV Values', function (t) {
  t.test('before', function (t) {
    t.plan(4);
    Lib.dotaItems(function (err, data) {
      t.notOk(err, 'no err while reading dota items');
      dotaItems = data;
      dotaItemList = Object.keys(dotaItems).filter(a => a !== 'values');
      /* dotaItemIDs = dotaItemList
        .map(function (item) {
          usedIDs[dotaItems[item].values.ID] = item;
          return dotaItems[item].values.ID;
        })
        .filter(a => !!a); */
      t.ok(Object.keys(data).length > 1, 'gets dota items from github');
    });
    Lib.dotaAbilities(function (err, data) {
      t.notOk(err, 'no err while reading dota abilities');
      dotaAbilities = data;
      dotaAbilityList = Object.keys(dotaAbilities).filter(a => a !== 'values');
      /* dotaAbilityList.forEach(function (item) {
        usedIDs[dotaAbilities[item].values.ID] = item;
      }); */

      t.ok(Object.keys(data).length > 1, 'gets dota abilities from github');
    });
  });
  t.test('Testing all item KV values', function (t) {
    dotaItems.item_lua = true;
    dotaItems.item_datadriven = true;
    Lib.items(function (err, data) {
      if (err) {
        t.notOk(err, 'no err while item reading kvs');
        itemsFound = {};
        return t.end();
      }

      const keys = Object.keys(data);
      const done = after(keys.length + 1, t.end);
      keys.forEach(function (name) {
        checkKVData(t, name, data[name], true, done);
      });
      buildItemTree(t, data, done);
    });
  });
  t.test('Testing all ability KV values', function (t) {
    dotaAbilities.ability_lua = true;
    dotaAbilities.ability_datadriven = true;
    dotaAbilities.special_bonus_base = true;
    Lib.abilities(function (err, data) {
      if (err) {
        t.notOk(err, 'no err while ability reading kvs');
        itemsFound = {};
        return t.end();
      }

      const keys = Object.keys(data);
      const done = after(keys.length, t.end);
      keys.forEach(function (name) {
        checkKVData(t, name, data[name], false, done);
      });
    });
  });
  /* t.test('next available ID', function (t) {
    while (usedIDs[nextAvailableId]) {
      nextAvailableId++;
    }
    t.ok(nextAvailableId, 'found an available id');
    console.log('Next available ID is', nextAvailableId);
    let iter = 0;
    let idToCheck = 0;
    let j = 0;
    for (iter = 1; iter < 65536; iter++) {
      if (idsFound[iter] !== undefined && usedIDs[iter] !== idsFound[iter] && usedIDs[iter] !== undefined) {
        console.log('same ID: ' + iter, idsFound[iter], usedIDs[iter]);
      }
    }
    // short unsigned (0, 65535) 65536 is equivalent to 0; 65537 is equivalent to 1 etc.
    console.log('items/abilities with potentially bad ID if unique ID is short unsigned type:');
    for (iter = 65535; iter < 9999999; iter++) {
      if (idsFound[iter] !== undefined) {
        for (j = 1; j < 153; j++) {
          idToCheck = iter - 65536 * j;
          if (idToCheck >= 0 && idsFound[idToCheck] !== undefined) {
            console.log('ID: ' + iter, idsFound[iter]);
            console.log('is in a potential conflict with: ' + idToCheck, idsFound[idToCheck]);
          }
        }
      }
    }
    t.end();
  }); */
});

function checkKVData (t, name, data, isItem, cb) {
  t.test(name, function (t) {
    let root = data;
    let foundRoot = false;
    if (root.DOTAAbilities) {
      root = root.DOTAAbilities;
      foundRoot = true;
    }
    if (!foundRoot) {
      console.log(root);
    }
    t.ok(foundRoot, 'Starts with DOTAAbilities');

    const keys = Object.keys(root).filter(a => a !== 'values');
    const done = after(keys.length, function (err) {
      t.notOk(err, 'no error at very end');
      t.end();
      cb(err);
    });
    keys.forEach(partial(testKVItem, t, root, isItem, name, done));
  });
}

// expects 1 item (with recipe) or 1 ability per file
function testKVItem (t, kvFileContent, isItem, fileName, cb, item) {
  const iconDirectory = isItem
    ? 'items'
    : 'spellicons';

  if (isItem) {
    itemFileMap[item] = fileName;
  }
  const done = after(3, function (err) {
    t.notOk(err, 'no error at very end');
    cb(err);
  });
  const values = kvFileContent[item].values;
  const isBuiltIn = isItem
    ? dotaItems[item] && dotaItems[item] !== true
    : dotaAbilities[item] && dotaAbilities[item] !== true;

  t.notOk(itemsFound[item], 'can only be defined once');
  // t.notOk(idsFound[values.ID], 'must have a unique ID');
  if (!isBuiltIn) {
    // t.ok(values.ID, 'must have an item id');
    t.ok(!isItem || values.ItemCost, 'non-built-in items must have prices');
    // t.ok(dotaItemIDs.indexOf(values.ID) === -1, 'cannot use an id used by dota ' + usedIDs[values.ID]);

    /* if (usedIDs[values.ID]) {
      t.fail('ID number is already in use by ' + usedIDs[values.ID]);
      usedIDs[values.ID] = item;
    } */
  }

  itemsFound[item] = item;
  // idsFound[values.ID] = item;

  /* while (usedIDs[nextAvailableId] || idsFound['' + nextAvailableId]) {
    nextAvailableId += 1;
  } */

  let icon = values.AbilityTextureName;

  if (icon) {
    t.equal(values.AbilityTextureName.toLowerCase(), values.AbilityTextureName, 'Icon names must be lowercase');

    if (allowedIconNames.indexOf(icon) === -1 && dotaItemList.indexOf(icon) === -1 && dotaAbilityList.indexOf(icon) === -1) {
      if (icon.substr(-4) === '.png') {
        t.fail('AbilityTextureName should not contain file extension');
      }
      const iconParts = icon.split('/');
      if (iconParts[0] === 'item_custom') {
        iconParts[0] = 'custom';
      }
      if (iconParts[iconParts.length - 1].substr(0, 5) === 'item_') {
        t.fail('AbilityTextureName should not start with item_');
      }
      icon = iconParts.join('/');
      icon += '.png';
      fs.access(path.join(Lib.gameDir, 'resource/flash3/images/', iconDirectory, icon), function (err, data) {
        t.notOk(err, 'icon ' + icon + ' exists for ' + item);
        done();
      });
    } else {
      done();
    }
  } else {
    done();
  }
  let parentKV = null;
  if (values.BaseClass) {
    if (isItem) {
      t.ok(dotaItems[values.BaseClass], 'base class ' + values.BaseClass + ' must be item_datadriven, item_lua, or a built-in item');
      if (dotaItems[values.BaseClass] && dotaItems[values.BaseClass].values && ignoredBaseClasses.indexOf(values.BaseClass) === -1) {
        parentKV = dotaItems[values.BaseClass];
      }
    } else {
      t.ok(dotaAbilities[values.BaseClass], 'base class ' + values.BaseClass + ' must be ability_datadriven, ability_lua, or a built-in ability');
      if (dotaAbilities[values.BaseClass] && dotaAbilities[values.BaseClass].values && ignoredBaseClasses.indexOf(values.BaseClass) === -1) {
        parentKV = dotaAbilities[values.BaseClass];
      }
    }
  } else {
    if (isItem) {
      t.ok(dotaItems[item], 'missing baseclass only allowed when overriding built-in items');
      parentKV = dotaItems[item];
    } else {
      t.ok(dotaAbilities[item], 'missing baseclass only allowed when overriding built-in abilities');
      parentKV = dotaAbilities[item];
    }
  }
  if (parentKV) {
    checkInheritedValues(t, isItem, values, kvFileContent[item].comments, parentKV.values);

    if (kvFileContent[item].ItemRequirements) {
      if (!kvFileContent[item].comments.ItemRequirements || !kvFileContent[item].comments.ItemRequirements.includes('OAA')) {
        t.deepEquals(kvFileContent[item].ItemRequirements, parentKV.ItemRequirements, 'has the same item buildup\n' + JSON.stringify(parentKV.ItemRequirements, null, 2) + '\n' + JSON.stringify(kvFileContent[item].ItemRequirements, null, 2));
      }
    }
  } else if (!values.BaseClass) {
    console.log('Couldnt find vanilla KVs for ' + item);
  }

  if (values.ScriptFile) {
    fs.access(path.join(Lib.vscriptDir, values.ScriptFile), function (err, data) {
      t.notOk(err, 'script file referenced from kv exists');
      done();
    });
  } else {
    done();
  }

  const specials = kvFileContent[item].AbilitySpecial;

  if (specials) {
    // check specials!
    if (ignoreValuesFor.indexOf(item) === -1) {
      let rootItem = item.match(/^(.*?)(_[0-9]+)?$/);
      if (isItem) {
        t.ok(rootItem, 'can parse basic item name out');
        rootItem = rootItem[1];
      } else {
        rootItem = item;
      }
      if (!specialValuesForItem[rootItem]) {
        testSpecialValues(t, isItem, specials, parentKV ? parentKV.AbilitySpecial : null);
        specialValuesForItem[rootItem] = specials;
      } else if (values.AbilityType !== 'ABILITY_TYPE_ATTRIBUTES' && isItem) {
        spok(t, specials, specialValuesForItem[rootItem], 'special values are not consistent across levels');
      }
    }
  } else {
    if ((parentKV ? parentKV.AbilitySpecial : false) && ignoreValuesFor.indexOf(item) === -1) {
      t.fail('This ability have no AbilitySpecials while it should!');
    }
  }

  const abilityValues = kvFileContent[item].AbilityValues;

  if (abilityValues) {
    if (ignoreValuesFor.indexOf(item) === -1) {
      let rootItem2 = item.match(/^(.*?)(_[0-9]+)?$/);
      if (isItem) {
        t.ok(rootItem2, 'can parse basic item name out');
        rootItem2 = rootItem2[1];
      } else {
        rootItem2 = item;
      }
      if (!abilityValuesForItem[rootItem2]) {
        testAbilityValues(t, isItem, abilityValues, parentKV ? parentKV.AbilityValues : null);
        abilityValuesForItem[rootItem2] = abilityValues;
      } else if (values.AbilityType !== 'ABILITY_TYPE_ATTRIBUTES' && isItem) {
        spok(t, abilityValues, abilityValuesForItem[rootItem2], 'ability values are not consistent across levels');
      }
    }
  } else {
    if ((parentKV ? parentKV.AbilityValues : false) && ignoreValuesFor.indexOf(item) === -1) {
      t.fail('This ability have no AbilityValues while it should!');
    }
  }
  done();
}

function checkInheritedValues (t, isItem, values, comments, parentValues) {
  if (parentValues.ID) {
    t.equals(values.ID, parentValues.ID, 'ID must not be changed from vanilla dota item or ability.');
  }
  const keys = [
    'AbilityBehavior',
    'AbilityCastPoint',
    'AbilityCastRange',
    'AbilityChannelTime',
    'AbilityChargeRestoreTime',
    'AbilityCharges',
    'AbilityCooldown',
    'AbilityDamage',
    'AbilityDuration',
    'AbilityManaCost',
    'AbilityType',
    'AbilityUnitDamageType',
    'AbilityUnitTargetFlags',
    'AbilityUnitTargetTeam',
    'AbilityUnitTargetType',
    'ItemCost',
    'ItemDisplayCharges',
    'ItemInitialCharges',
    'ItemRequiresCharges',
    'SpellDispellableType',
    'SpellImmunityType'
  ];

  if (values.AbilityBehavior && (!comments.AbilityBehavior || !comments.AbilityBehavior.includes('OAA'))) {
    t.equals(values.AbilityBehavior, parentValues.AbilityBehavior, 'AbilityBehavior must not be changed from base dota item');
  }
  keys.forEach(function (key) {
    if (values[key] && (!comments[key] || !comments[key].includes('OAA'))) {
      let baseValue = '';
      let parentValue = parentValues[key] || '';

      if (values[key].length < parentValue.length) {
        baseValue = parentValue.split(' ').map(function (entry) {
          return values[key];
        }).join(' ');
      } else {
        let size = values[key].split(' ').length - 2;
        if (isItem) {
          size = 1;
        }
        const parentArr = parentValue.split(' ');
        if (parentArr.length === 1) {
          while (parentArr.length < size) {
            parentArr.push(parentArr[0]);
          }
        }
        parentValue = parentArr.join(' ');

        baseValue = values[key].substr(0, Math.max(1, parentValue.length, values[key].split(' ')[0].length));
      }
      t.deepEqual(baseValue, parentValue, key + ' should inherit basic dota values (' + parentValue + ' vs ' + baseValue + ')');
      // t.equals(values[key], parentValues[key], key + ' must not be changed from base dota item (' + parentValues[key] + ' vs ' + values[key] + ')');
    }
  });
}

function testSpecialValues (t, isItem, specials, parentSpecials) {
  const values = Object.keys(specials).filter(a => a !== 'values');
  const result = {};
  const parentData = {};

  const stupidSpecialValueNames = [
    // 'AbilityChargeRestoreTime',
    'AbilityCharges',
    // 'abilitycastpoint',
    'abilitycastrange'
    // 'abilitychanneltime',
    // 'abilityduration',
  ];

  if (parentSpecials) {
    const parentValues = Object.keys(parentSpecials).filter(a => a !== 'values');
    parentValues.forEach(function (num) {
      const value = parentSpecials[num].values;
      const keyNames = filterExtraKeysFromSpecialValue(Object.keys(value));

      parentData[keyNames[0]] = value;
    });
  }

  values.forEach(function (num) {
    const value = specials[num].values;
    t.ok(value.var_type, 'has a var_type ' + num);

    const keyNames = filterExtraKeysFromSpecialValue(Object.keys(value));
    t.equal(keyNames.length, 1, 'gets keyname after filtering out extra values');

    const keyName = keyNames[0];

    if (parentSpecials && (!parentSpecials[num] || !parentSpecials[num].values[keyName])) {
      if (specials.comments && specials.comments[num] && specials.comments[num].indexOf('OAA') !== -1) {
        // do nothing
      } else if (!parentData[keyName]) {
        t.fail('Extra keyname found in special values: ' + keyName);
      } else if (!parentSpecials[num]) {
        t.fail('Unexpected special value: ' + keyName);
      } else {
        const expectedName = filterExtraKeysFromSpecialValue(Object.keys(parentSpecials[num].values))[0];
        if (stupidSpecialValueNames.indexOf(expectedName) === -1) {
          t.fail('special value in wrong order: ' + keyName + ' should be ' + expectedName);
        }
      }
    }
    if (parentData[keyName]) {
      // console.log(parentData[keyName], value);
      const compareValue = extend(value);
      compareValue[keyName] = parentData[keyName][keyName];
      compareValue.var_type = parentData[keyName].var_type;
      spok(t, compareValue, parentData[keyName], keyName + ' has all the special values from parent ');

      if (value[keyName].match(/\.0*[1-9]/)) {
        t.notEqual(value.var_type, 'FIELD_INTEGER', 'cannot use FIELD_INTEGER with decimal values in ' + keyName);
      }

      if (!specials[num].comments[keyName] || !specials[num].comments[keyName].includes('OAA')) {
        // test base dota values
        let baseValue = '';
        let parentValue = parentData[keyName][keyName];

        if (value[keyName].length < parentValue.length) {
          baseValue = parentValue.split(' ').map(function (entry) {
            return value[keyName];
          }).join(' ');
        } else {
          let size = value[keyName].split(' ').length - 2;
          if (isItem) {
            size = 1;
          }
          const parentArr = parentValue.split(' ');
          if (parentArr.length === 1) {
            while (parentArr.length < size) {
              parentArr.push(parentArr[0]);
            }
          }
          parentValue = parentArr.join(' ');

          baseValue = value[keyName].substr(0, parentValue.length);
        }
        t.equal(parentValue, baseValue, keyName + ' should inherit basic dota values (' + parentValue + ' vs ' + baseValue + ')');
      }
    }

    if (result[keyName]) {
      t.fail('Special value found twice: ' + keyName);
    }
    result[keyName] = value[keyName];
  });

  Object.keys(parentData).forEach(function (name) {
    if (stupidSpecialValueNames.indexOf(name) === -1) {
      t.ok(result[name], 'has value for ' + name + ' (' + parentData[name][name] + ', ' + parentData[name].var_type + ')');
    }
  });

  return result;
}

function testAbilityValues (t, isItem, abvalues, parentAbvalues) {
  const normalKeys = Object.keys(abvalues.values);
  const normalValues = Object.values(abvalues.values);
  const complexKeys = Object.keys(abvalues).filter(a => a !== 'values');
  const parentData = {};
  const actualData = {};

  if (parentAbvalues) {
    const parentKeys = Object.keys(parentAbvalues.values);
    const parentValues = Object.values(parentAbvalues.values);
    const complexParentKeys = Object.keys(parentAbvalues).filter(a => a !== 'values');

    let i = 0;
    parentKeys.forEach(function (num) {
      const value = parentValues[i];
      parentData[num] = value;
      i++;
    });

    complexParentKeys.forEach(function (num) {
      const value = parentAbvalues[num].values;
      parentData[num] = value;
    });
  }

  let i = 0;
  normalKeys.forEach(function (num) {
    const value = normalValues[i];
    actualData[num] = value;
    i++;
  });

  complexKeys.forEach(function (num) {
    const value = abvalues[num].values;
    actualData[num] = value;
  });

  normalKeys.forEach(function (keyName) {
    const actualValue = actualData[keyName];
    let expectedValue = parentData[keyName];
    if (!abvalues.comments[keyName] || !abvalues.comments[keyName].includes('OAA')) {
      if (expectedValue && typeof expectedValue !== 'object') {
        if (actualValue !== expectedValue) {
          if (actualValue.length !== expectedValue.length) {
            const actualValueToken = actualValue.split(' ');
            const expectedValueToken = expectedValue.split(' ');
            if (actualValueToken.length < expectedValueToken.length) {
              if (actualValueToken.length === 1) {
                if ((expectedValueToken[0] !== expectedValueToken[1]) || (actualValueToken[0] !== expectedValueToken[0])) {
                  t.equal(actualValue, expectedValue, keyName + ' should inherit vanilla dota values (' + expectedValue + ' vs ' + actualValue + ')');
                }
              } else {
                t.equal(actualValue, expectedValue, keyName + ' should inherit vanilla dota values (' + expectedValue + ' vs ' + actualValue + ')');
              }
            } else {
              if (actualValueToken.length !== expectedValueToken.length) {
                let size = actualValueToken.length - 2;
                if (isItem) {
                  size = 1;
                }

                if (expectedValueToken.length === 1) {
                  while (expectedValueToken.length < size) {
                    expectedValueToken.push(expectedValueToken[0]);
                  }
                }
                expectedValue = expectedValueToken.join(' ');

                const valueToCheck = actualValue.substr(0, expectedValue.length);
                if (valueToCheck !== expectedValue) {
                  t.equal(valueToCheck, expectedValue, keyName + ' should inherit vanilla dota values (' + expectedValue + ' vs ' + valueToCheck + ')');
                }
              } else {
                t.equal(actualValue, expectedValue, keyName + ' should inherit vanilla dota values (' + expectedValue + ' vs ' + actualValue + ')'); // probably not needed
              }
            }
          } else {
            t.equal(actualValue, expectedValue, keyName + ' should inherit vanilla dota values (' + expectedValue + ' vs ' + actualValue + ')');
          }
        }
      } else if (parentAbvalues) {
        t.fail('Extra keyname found in our AbilityValues: ' + keyName + '. Maybe in vanilla it is changed to a kv block.');
      }
    }
  });

  complexKeys.forEach(function (keyName) {
    if (parentAbvalues && (!parentAbvalues[keyName] || !parentAbvalues[keyName].values)) {
      if (abvalues.comments && abvalues.comments[keyName] && abvalues.comments[keyName].includes('OAA')) {
        // do nothing
      } else if (!parentData[keyName]) {
        t.fail('Extra {keyname} found in our AbilityValues: ' + keyName);
      } else if (!parentAbvalues[keyName]) {
        t.fail('Unexpected block AbilityValue: ' + keyName);
      }
    }
    if (parentData[keyName]) {
      const actualValues = Object.values(actualData[keyName]);
      const expectedValues = Object.values(parentData[keyName]);
      actualValues.forEach(function (v, i) {
        let expectedValue = expectedValues[i];
        const actualValue = v;
        const actualKey = Object.keys(actualData[keyName]).find(key => actualData[keyName][key] === actualValue);
        // if (actualKey === 'value') {
        // actualKey = keyName;
        // }
        const parentKey = Object.keys(parentData[keyName]).find(key => parentData[keyName][key] === expectedValue);
        if (actualValue && expectedValue && actualValue !== expectedValue) {
          if (!abvalues.comments[keyName] || !abvalues.comments[keyName].includes('OAA')) {
            if (actualValue.length !== expectedValue.length) {
              const actualValueToken = actualValue.split(' ');
              const expectedValueToken = expectedValue.split(' ');
              if (actualValueToken.length < expectedValueToken.length) {
                if (actualValueToken.length === 1) {
                  if ((expectedValueToken[0] !== expectedValueToken[1]) || (actualValueToken[0] !== expectedValueToken[0])) {
                    t.equal(actualValue, expectedValue, actualKey + ' in {' + keyName + '} should inherit vanilla dota values (' + expectedValue + ' vs ' + actualValue + ')');
                  }
                } else {
                  t.equal(actualValue, expectedValue, actualKey + ' in {' + keyName + '} should inherit vanilla dota values (' + expectedValue + ' vs ' + actualValue + ')');
                }
              } else {
                if (actualValueToken.length !== expectedValueToken.length) {
                  let size = actualValueToken.length - 2;
                  if (isItem) {
                    size = 1;
                  }

                  if (expectedValueToken.length === 1) {
                    while (expectedValueToken.length < size) {
                      expectedValueToken.push(expectedValueToken[0]);
                    }
                  }
                  expectedValue = expectedValueToken.join(' ');

                  const valueToCheck = actualValue.substr(0, expectedValue.length);
                  if (valueToCheck !== expectedValue) {
                    t.equal(valueToCheck, expectedValue, actualKey + ' in {' + keyName + '} should inherit vanilla dota values (' + expectedValue + ' vs ' + valueToCheck + ')');
                  }
                } else {
                  t.equal(actualValue, expectedValue, actualKey + ' in {' + keyName + '} should have values: (' + expectedValue + ' vs ' + actualValue + ')');
                }
              }
            } else {
              t.equal(actualKey, parentKey, 'keyname: ' + actualKey + ' in {' + keyName + '} should be: ' + parentKey);
              if (actualKey === parentKey) {
                t.equal(actualValue, expectedValue, actualKey + ' in {' + keyName + '} should inherit vanilla dota values (' + expectedValue + ' vs ' + actualValue + ')');
              }
            }
          }
        }
        if (actualKey !== parentKey && (!abvalues.comments[keyName] || !abvalues.comments[keyName].includes('OAA'))) {
          if (parentKey === keyName) {
            t.fail('keyname: ' + actualKey + ' in {' + keyName + '} should be: value');
          } else if (actualKey === keyName) {
            t.fail('keyname: value in {' + keyName + '} should be: ' + parentKey);
          } else {
            t.fail('keyname: ' + actualKey + ' in {' + keyName + '} should be: ' + parentKey);
          }
        }
      });
    }
  });

  if (parentAbvalues) {
    Object.keys(parentData).forEach(function (name) {
      const actualValue = actualData[name];
      const actualKey = Object.keys(actualData).find(key => actualData[key] === actualValue);

      if (!actualValue && !actualKey && name !== actualKey) {
        t.fail('Vanilla ability has a key: ' + name + ' with a value: ' + parentData[name]);
      }
      if (actualValue && typeof actualValue === 'object' && typeof parentData[name] === 'object' && name === actualKey) {
        Object.keys(parentData[name]).forEach(function (keyname) {
          if (actualValue[keyname] === undefined) {
            if (!abvalues.comments[name] || !abvalues.comments[name].includes('OAA')) {
              t.fail('Vanilla ability has a key: ' + keyname + ' inside {' + name + '}');
            }
          }
        });
      }
    });
  }
}

const keyWhiteList = [
  'var_type',
  'levelkey',
  'LinkedSpecialBonus',
  'LinkedSpecialBonusField',
  'LinkedSpecialBonusOperation',
  'CalculateSpellDamageTooltip',
  'RequiresShard',
  'ad_linked_abilities',
  'ad_linked_ability',
  'linked_ad_abilities',
  'DamageTypeTooltip'
];
function filterExtraKeysFromSpecialValue (keyNames) {
  return keyNames.filter(a => keyWhiteList.indexOf(a) === -1);
}

// check upgrade paths and costs
function buildItemTree (t, data, cb) {
  const items = {};
  const recipes = {};
  const recipesByResult = {};
  const allItemNames = [];
  const allRecipeNames = [];
  t.test('item upgrade paths', function (t) {
    Object.keys(data).forEach(function (fileName) {
      const entry = data[fileName].DOTAAbilities;
      if (!entry) {
        t.fail('Could not find the DOTAAbilities entry for ' + fileName);
        return;
      }
      const itemNames = Object.keys(entry).filter(a => a !== 'values');
      itemNames.forEach(function (item) {
        const itemData = entry[item];
        const purchasable = itemData.values.ItemPurchasable !== '0';
        let itemCost = itemData.values.ItemCost;

        if (!itemCost && dotaItems[item]) {
          itemCost = dotaItems[item].values.ItemCost;
        }

        if (items[item]) {
          t.fail(item + ' was defined twice, not bothering with tree');
          return;
        }

        if (itemData.values.ItemRecipe === '1') {
          allRecipeNames.push(item);
          recipes[item] = itemData;
          t.notOk(recipesByResult[itemData.values.ItemResult], 'only 1 recipe per result');

          recipesByResult[itemData.values.ItemResult] = item;
        } else {
          allItemNames.push(item);
          items[item] = {
            baseCost: purchasable
              ? Number(itemCost)
              : 0,
            cost: purchasable
              ? Number(itemCost)
              : 0,
            // cost: Number(itemCost),
            totalCost: Number(itemCost),
            purchasable: purchasable,
            children: [], // array of string names of items that can be created with this item in only 1 jump
            recipes: [], // array of recipe objects that can create this item
            item: itemData
          };
        }
        // console.log(item, itemData);
        /*
        item_recipe_preemptive_3a { values:
         { ID: '3807',
           BaseClass: 'item_datadriven',
           ItemCost: '20000',
           ItemShopTags: '',
           ItemRecipe: '1',
           ItemResult: 'item_preemptive_3a',
           AbilityTextureName: 'item_recipe' },
        ItemRequirements:
         { values:
            { '01': 'item_preemptive_2a;item_upgrade_core_4',
              '02': 'item_preemptive_2b;item_upgrade_core_4' } } }
        */
      });
    });
    allItemNames.forEach(function (item) {
      const itemData = items[item];
      const itemNameParts = item.split('_');
      const itemRecipeParts = itemNameParts.concat();
      itemRecipeParts.splice(1, 0, 'recipe');
      const probableRecipeName = itemRecipeParts.join('_');

      let recipe = recipesByResult[item];
      let recipeData = recipe
        ? recipes[recipe]
        : null;

      if (!recipe || !recipeData.values.ItemCost) {
        recipe = recipe || probableRecipeName;
        if (dotaItems[recipe]) {
          recipeData = dotaItems[recipe];
        } else {
          // this is a base item, either from dota (gloves, etc..) or mod (upgrade_core, etc...)
          return;
        }
      }
      let requirements = recipeData.ItemRequirements.values; // some neutral items have a recipe without ItemRequirements, because of that an error will appear saying it's 'undefined'
      let numIndex = 1;
      requirements = Object.keys(requirements)
        .sort(function (a, b) { return Number(a) - Number(b); })
        .map(function (index) {
          t.equal(Number(index), numIndex++, 'requirements indexes are in order for ' + item);
          return requirements[index].split(';').filter(a => !!a);
        });

      itemData.cost = Number.MAX_VALUE;
      itemData.totalCost = Number.MAX_VALUE;
      itemData.recipes = requirements;
      itemData.recipe = recipeData;
      itemData.purchasable = false;

      calculateCost(item);

      const upgradeCores = [];
      let firstReq = null;
      let firstCore = null;
      requirements.forEach(function (reqList) {
        let coreTier = null;
        reqList.forEach(function (reqItem) {
          const match = reqItem.match(/item_upgrade_core_?([0-9])?/);
          if (!match) {
            if (!firstReq) {
              firstReq = reqItem;
            } else {
              if (baseItemName(reqItem) === baseItemName(item) && reqItem !== item) {
                t.equals(baseItemName(firstReq), baseItemName(item), item + ' builds out of itself, so it needs to build out of itself first.');
              }
            }
            return;
          }
          coreTier = Number(match[1] || 1);
          if (!firstCore) {
            firstCore = coreTier;
          } else {
            t.ok(firstCore <= coreTier, item + ' cores should prefer lower tier over higher tier');
          }
        });
        if (coreTier) {
          upgradeCores.push(coreTier);
        }
      });

      // if (upgradeCores.length && !recipeData.comments.ItemRequirements.includes('OAA')) {
      // var minCore = upgradeCores.reduce((a, b) => Math.min(a, b), 5);
      // console.log(item, 'is made with tier', minCore, 'items');
      // for (var i = minCore; i < 5; ++i) {
      // t.notEqual(upgradeCores.indexOf(i), -1, item + ' has reverse compatible upgrade core ' + i);
      // }
      // }

      /*
        item_preemptive_3a { values:
           { ID: '3808',
             BaseClass: 'item_lua',
             AbilityBehavior: 'DOTA_ABILITY_BEHAVIOR_IMMEDIATE | DOTA_ABILITY_BEHAVIOR_NO_TARGET | DOTA_ABILITY_BEHAVIOR_IGNORE_CHANNEL',
             AbilityTextureName: 'custom/preemptive_3a',
             ScriptFile: 'items/reflex/preemptive_purge.lua',
             MaxUpgradeLevel: '3',
             ItemBaseLevel: '3',
             AbilityManaCost: '0',
             AbilityCooldown: '20',
             AbilitySharedCooldown: 'reflex',
             AbilityCastPoint: '0.0',
             ItemCost: '13900',
             ItemShopTags: 'defense;support;mobility;hard_to_tag',
             ItemQuality: 'epic',
             ItemAliases: 'reflex;preemptive_3a;purge',
             ItemDisassembleRule: 'DOTA_ITEM_DISASSEMBLE_ALWAYS',
             ItemDeclarations: 'DECLARE_PURCHASES_TO_TEAMMATES | DECLARE_PURCHASES_IN_SPEECH | DECLARE_PURCHASES_TO_SPECTATORS' },
          AbilitySpecial:
           { values: {},
             '01': { values: [Object] },
             '02': { values: [Object] },
             '03': { values: [Object] },
             '04': { values: [Object] },
             '05': { values: [Object] } } }
      */
    });

    allItemNames.forEach(function (item) {
      if (!items[item]) {
        t.fail('missing item in items list ' + item);
        return;
      }
      const purchasable = items[item].item.values.ItemPurchasable !== '0';
      if (purchasable) {
        t.equal(items[item].baseCost, items[item].cost, 'cost is set correctly in kv for ' + item);
      }

      // this chunk of code will write the item costs in the file for you
      // useful...
      if (items[item].baseCost !== items[item].cost) {
        const fileName = itemFileMap[item];
        let foundIt = false;
        const lines = fs.readFileSync(fileName, { encoding: 'utf8' })
          .split('\n')
          .map(function (line) {
            const parts = line.split(/[\s ]+/).filter(a => a && a.length);
            if (parts[0] === '"' + item + '"') {
              foundIt = true;
            }
            if (foundIt && parts[0] === '"ItemCost"') {
              // console.log(parts);
              line = line.replace('' + items[item].baseCost, items[item].cost);
              foundIt = false;
            }
            return line;
          })
          .join('\n');

        fs.writeFileSync(fileName, lines, { encoding: 'utf8' });
      }
    });

    // output item costs in csv format (for haga usually)
    // allItemNames.forEach(function (item) {
    //   console.log([item, items[item].totalCost, items[item].cost].join(','));
    // });

    t.end();
    cb();
    // end of test
  });

  function calculateCost (item, skipChildren) {
    // console.log('Calculating the cost for', item);
    const itemData = items[item];
    const requirements = itemData.recipes;
    if (itemData.item.values.ItemPurchasable === '0') {
      itemData.cost = 0;
      itemData.totalCost = 0;
      return;
    }

    requirements.forEach(function (reqList) {
      let cost = Number(itemData.recipe.values.ItemCost);
      let totalCost = Number(itemData.recipe.values.ItemCost);
      reqList.forEach(function (reqItem) {
        if (item === reqItem) {
          // this item builds into itself
          // probably charge refreshing by rebuying recipe
          console.log(item, 'builds into itself');
          cost = Number.MAX_VALUE;
          totalCost = Number.MAX_VALUE;
          return;
        }
        let parentItem = items[reqItem];
        if (!parentItem) {
          if (!dotaItems[reqItem] && !recipes[reqItem]) {
            t.fail('Item ' + item + ' is made out of an unknown item ' + reqItem);
            return;
          }
          const baseItem = recipes[reqItem] || dotaItems[reqItem];
          const baseItemCost = Number(baseItem.values.ItemCost);
          parentItem = {
            baseCost: baseItemCost,
            cost: baseItemCost,
            totalCost: baseItemCost,
            item: baseItem,
            children: []
          };
          // console.log(item, 'is made with', parentItem);
        }
        if (parentItem.totalCost < parentItem.cost) {
          calculateCost(reqItem, true);
          if (parentItem.totalCost < parentItem.cost) {
            t.fail(reqItem + ' has invalid cost data');
          }
        }
        // if (item === 'item_sphere') {
        //   console.log('adding', parentItem);
        //   console.log('to', cost, totalCost);
        // }
        cost = cost + parentItem.cost;
        totalCost = totalCost + parentItem.totalCost;

        if (parentItem.children.indexOf(item) === -1) {
          parentItem.children.push(item);
        }
        if (cost > totalCost) {
          console.log('Bad cost data', reqItem, cost, totalCost, item, parentItem);
        }
      });
      if (cost > totalCost) {
        t.fail(['Bad cost data', cost, totalCost, item].join(' '));
      }
      if (cost < itemData.cost) {
        itemData.cost = cost;
      }
      if (totalCost < itemData.totalCost) {
        itemData.totalCost = totalCost;
      }
    });
    if (!skipChildren && itemData.children.length) {
      itemData.children.forEach(calculateCost);
    }
  }
}

function baseItemName (name) {
  const nameParts = name.split('_');
  if (Number.isFinite(Number(nameParts.pop()))) {
    return nameParts.join('_');
  }
  return name;
}
