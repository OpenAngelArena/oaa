var test = require('tape');
var Lib = require('../kv-lib');
var path = require('path');
var fs = require('fs');
var after = require('after');
var spok = require('spok');
var extend = require('xtend');
var partial = require('ap').partial;

var dotaItems = null;
var dotaItemIDs = null;
var dotaAbilities = null;
var dotaItemList = null;
var dotaAbilityList = null;
var stupidItemNames = [
  'item_recipe',
  'item_halloween_candy_corn',
  'item_halloween_rapier',
  'item_firework_mine',
  'sylph_sprite_shield',
  'nothing'
];

var itemsFound = {};
var idsFound = {};
var itemFileMap = {};
var nextAvailableId = 8401;
var usedIDs = {};

test('KV Values', function (t) {
  t.test('before', function (t) {
    t.plan(4);
    Lib.dotaItems(function (err, data) {
      t.notOk(err, 'no err while reading dota items');
      dotaItems = data;
      dotaItemList = Object.keys(dotaItems).filter(a => a !== 'values');
      dotaItemIDs = dotaItemList
        .map(function (item) {
          // console.log(dotaItems[item]);
          usedIDs[dotaItems[item].values.ID] = item;
          return dotaItems[item].values.ID;
        })
        .filter(a => !!a);
      t.ok(Object.keys(data).length > 1, 'gets dota items from github');
    });
    Lib.dotaAbilities(function (err, data) {
      t.notOk(err, 'no err while reading dota abilities');
      dotaAbilities = data;
      dotaAbilityList = Object.keys(dotaAbilities).filter(a => a !== 'values');
      dotaAbilityList.forEach(function (item) {
        usedIDs[dotaAbilities[item].values.ID] = item;
      });

      t.ok(Object.keys(data).length > 1, 'gets dota abilities from github');
    });
  });
  t.test('Testing all item KV values', function (t) {
    dotaItems['item_lua'] = true;
    dotaAbilities['ability_lua'] = true;
    dotaItems['item_datadriven'] = true;
    dotaAbilities['ability_datadriven'] = true;
    Lib.items(function (err, data) {
      if (err) {
        t.notOk(err, 'no err while item reading kvs');
        itemsFound = {};
        return t.end();
      }

      var keys = Object.keys(data);
      var done = after(keys.length + 1, t.end);
      keys.forEach(function (name) {
        checkKVData(t, name, data[name], true, done);
      });
      buildItemTree(t, data, done);
    });
  });
  t.test('Testing all ability KV values', function (t) {
    Lib.abilities(function (err, data) {
      if (err) {
        t.notOk(err, 'no err while ability reading kvs');
        itemsFound = {};
        return t.end();
      }

      var keys = Object.keys(data);
      var done = after(keys.length, t.end);
      keys.forEach(function (name) {
        checkKVData(t, name, data[name], false, done);
      });
    });
  });
  t.test('next available ID', function (t) {
    while (usedIDs[nextAvailableId]) {
      nextAvailableId++;
    }
    t.ok(nextAvailableId, 'found an available id');
    console.log('Next available ID is', nextAvailableId);
    t.end();
  });
});

var specialValuesForItem = {};

function checkKVData (t, name, data, isItem, cb) {
  t.test(name, function (t) {
    var root = data;
    var foundRoot = false;
    if (root.DOTAItems) {
      root = root.DOTAItems;
      foundRoot = true;
    }
    if (root.DOTAAbilities) {
      root = root.DOTAAbilities;
      foundRoot = true;
    }
    if (!foundRoot) {
      console.log(root);
    }
    t.ok(foundRoot, 'Starts with either DOTAItems or DOTAAbilities');

    var keys = Object.keys(root).filter(a => a !== 'values');
    var done = after(keys.length, function (err) {
      t.notOk(err, 'no error at very end');
      t.end();
      cb(err);
    });
    keys.forEach(partial(testKVItem, t, root, isItem, name, done));
  });
}

function testKVItem (t, root, isItem, fileName, cb, item) {
  var iconDirectory = isItem
    ? 'items'
    : 'spellicons';
  // t.test(item, function (t) {

  itemFileMap[item] = fileName;
  var done = after(3, function (err) {
    t.notOk(err, 'no error at very end');
    // t.end();
    cb(err);
  });
  var values = root[item].values;
  var isBuiltIn = isItem
    ? dotaItems[item] && dotaItems[item] !== true
    : dotaAbilities[item] && dotaAbilities[item] !== true;

  t.notOk(itemsFound[item], 'can only be defined once');
  if (item !== 'ability_base_datadriven') {
    t.notOk(idsFound[values.ID], 'must have a unique ID');
    if (!isBuiltIn && item !== 'item_dummy_datadriven') {
      t.ok(values.ID, 'must have an item id');
      t.ok(!isItem || values.ItemCost, 'non-built-in items must have prices');
      t.ok(dotaItemIDs.indexOf(values.ID) === -1, 'cannot use an id used by dota ' + usedIDs[values.ID]);

      if (usedIDs[values.ID]) {
        t.fail('ID number is already in use by ' + usedIDs[values.ID]);
        usedIDs[values.ID] = item;
      }
    }
  }

  itemsFound[item] = item;
  idsFound[values.ID] = item;

  while (usedIDs[nextAvailableId] || idsFound['' + nextAvailableId]) {
    nextAvailableId += 1;
  }

  var icon = values.AbilityTextureName;

  if (icon) {
    t.equal(values.AbilityTextureName.toLowerCase(), values.AbilityTextureName, 'Icon names must be lowercase');

    if (stupidItemNames.indexOf(icon) === -1 && dotaItemList.indexOf(icon) === -1 && dotaAbilityList.indexOf(icon) === -1) {
      if (icon.substr(-4) === '.png') {
        t.fail('AbilityTextureName should not contain file extension');
      }
      var iconParts = icon.split('/');
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
  var parentKV = null;
  if (values.BaseClass) {
    if (isItem) {
      t.ok(dotaItems[values.BaseClass], 'base class ' + values.BaseClass + ' must be item_datadriven, item_lua, or a built in item');
      if (dotaItems[values.BaseClass] && dotaItems[values.BaseClass].values && dotaItems[values.BaseClass].values.ID === values.ID) {
        parentKV = dotaItems[values.BaseClass];
      }
    } else {
      t.ok(dotaAbilities[values.BaseClass], 'base class ' + values.BaseClass + ' must be ability_datadriven, ability_lua, or a built in ability');
      if (dotaAbilities[values.BaseClass] && dotaAbilities[values.BaseClass].values && dotaAbilities[values.BaseClass].values.ID === values.ID) {
        parentKV = dotaAbilities[values.BaseClass];
      }
    }
  } else {
    if (isItem) {
      t.ok(dotaItems[item], 'missing baseclass only allowed when overriding built in items');
      parentKV = dotaItems[item];
    } else {
      t.ok(dotaAbilities[item], 'missing baseclass only allowed when overriding built in abilities');
      parentKV = dotaAbilities[item];
    }
  }
  if (parentKV && values.ID) {
    checkInheritedValues(t, isItem, values, root[item].comments, parentKV.values);

    if (root[item].ItemRequirements) {
      if (!root[item].comments.ItemRequirements || !root[item].comments.ItemRequirements.includes('OAA')) {
        t.deepEquals(root[item].ItemRequirements, parentKV.ItemRequirements, 'has the same item buildup\n' + JSON.stringify(parentKV.ItemRequirements, null, 2) + '\n' + JSON.stringify(root[item].ItemRequirements, null, 2));
      }
    }
  }

  if (values.ScriptFile) {
    fs.access(path.join(Lib.vscriptDir, values.ScriptFile), function (err, data) {
      t.notOk(err, 'script file referenced from kv exists');
      done();
    });
  } else {
    done();
  }
  var specials = root[item].AbilitySpecial;

  if (specials) {
    // check specials!
    var rootItem = item.match(/^(.*?)(_[0-9]+)?$/);
    t.ok(rootItem, 'can parse basic item name out');
    // var version = rootItem[2];
    rootItem = rootItem[1];
    if (!specialValuesForItem[rootItem]) {
      testSpecialValues(t, isItem, specials, parentKV ? parentKV.AbilitySpecial : null);
      specialValuesForItem[rootItem] = specials;
    } else if (values.AbilityType !== 'DOTA_ABILITY_TYPE_ATTRIBUTES') {
      spok(t, specials, specialValuesForItem[rootItem], 'special values are consistent');
    }
    done();
  } else {
    done();
  }
  // });
}

function checkInheritedValues (t, isItem, values, comments, parentValues) {
  if (values.ID) {
    t.equals(values.ID, parentValues.ID, 'ID must not be changed from base dota item');
  }
  var keys = [
    'AbilityBehavior',
    'ItemCost',
    'AbilityCastRange',
    'AbilityCastPoint',
    'AbilityChannelTime',
    'AbilityCooldown',
    'AbilityDuration',
    'AbilityManaCost',
    'AbilityUnitTargetType',
    'AbilityUnitDamageType',
    'SpellImmunityType',
    'SpellDispellableType',
    'ItemInitialCharges',
    'ItemRequiresCharges',
    'ItemDisplayCharges'
  ];

  if (values.AbilityBehavior && (!comments.AbilityBehavior || !comments.AbilityBehavior.includes('OAA'))) {
    t.equals(values.AbilityBehavior, parentValues.AbilityBehavior, 'AbilityBehavior must not be changed from base dota item');
  }
  keys.forEach(function (key) {
    if (values[key] && (!comments[key] || !comments[key].includes('OAA'))) {
      var baseValue = '';
      var parentValue = parentValues[key] || '';

      if (values[key].length < parentValue.length) {
        baseValue = parentValue.split(' ').map(function (entry) {
          return values[key];
        }).join(' ');
      } else {
        var size = values[key].split(' ').length - 2;
        if (isItem) {
          size = 1;
        }
        var parentArr = parentValue.split(' ');
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
  var values = Object.keys(specials).filter(a => a !== 'values');
  var result = {};
  var parentData = {};

  var stupidSpecialValueNames = [
    'abilitycastrange',
    'abilitycastpoint',
    'abilitychanneltime',
    'abilityduration',
    'AbilityCharges',
    'AbilityChargeRestoreTime'
  ];

  if (parentSpecials) {
    var parentValues = Object.keys(parentSpecials).filter(a => a !== 'values');
    parentValues.forEach(function (num) {
      var value = parentSpecials[num].values;
      var keyNames = filterExtraKeysFromSpecialValue(Object.keys(value));

      parentData[keyNames[0]] = value;
    });
  }

  values.forEach(function (num) {
    var value = specials[num].values;
    t.ok(value.var_type, 'has a var_type ' + num);

    var keyNames = filterExtraKeysFromSpecialValue(Object.keys(value));
    t.equal(keyNames.length, 1, 'gets keyname after filtering out extra values');

    var keyName = keyNames[0];

    if (parentSpecials && (!parentSpecials[num] || !parentSpecials[num].values[keyName])) {
      if (specials.comments && specials.comments[num] && specials.comments[num].indexOf('OAA') !== -1) {
        // do nothing
      } else if (!parentData[keyName]) {
        t.fail('Extra keyname found in special values: ' + keyName);
      } else if (!parentSpecials[num]) {
        t.fail('Unexpected special value: ' + keyName);
      } else {
        var expectedName = filterExtraKeysFromSpecialValue(Object.keys(parentSpecials[num].values))[0];
        if (stupidSpecialValueNames.indexOf(expectedName) === -1) {
          t.fail('special value in wrong order: ' + keyName + ' should be ' + expectedName);
        }
      }
    }
    if (parentData[keyName]) {
      // console.log(parentData[keyName], value);
      var compareValue = extend(value);
      compareValue[keyName] = parentData[keyName][keyName];
      compareValue.var_type = parentData[keyName].var_type;
      spok(t, compareValue, parentData[keyName], keyName + ' has all the special values from parent ');

      if (value[keyName].match(/\.0*[1-9]/)) {
        t.notEqual(value.var_type, 'FIELD_INTEGER', 'cannot use FIELD_INTEGER with decimal values in ' + keyName);
      }

      if (!specials[num].comments[keyName] || !specials[num].comments[keyName].includes('OAA')) {
        // test base dota values
        var baseValue = '';
        var parentValue = parentData[keyName][keyName];

        if (value[keyName].length < parentValue.length) {
          baseValue = parentValue.split(' ').map(function (entry) {
            return value[keyName];
          }).join(' ');
        } else {
          var size = value[keyName].split(' ').length - 2;
          if (isItem) {
            size = 1;
          }
          var parentArr = parentValue.split(' ');
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

var keyWhiteList = [
  'var_type',
  'LinkedSpecialBonus',
  'LinkedSpecialBonusField',
  'LinkedSpecialBonusOperation',
  'CalculateSpellDamageTooltip',
  'levelkey',
  'RequiresScepter'
];
function filterExtraKeysFromSpecialValue (keyNames) {
  return keyNames.filter(a => keyWhiteList.indexOf(a) === -1);
}

// check upgrade paths and costs
function buildItemTree (t, data, cb) {
  var items = {};
  var recipes = {};
  var recipesByResult = {};
  var allItemNames = [];
  var allRecipeNames = [];
  t.test('item upgrade paths', function (t) {
    Object.keys(data).forEach(function (fileName) {
      var entry = data[fileName].DOTAItems;
      if (!entry) {
        t.fail('Could not find the DOTAItems entry for ' + fileName);
        return;
      }
      var itemNames = Object.keys(entry).filter(a => a !== 'values');
      itemNames.forEach(function (item) {
        var itemData = entry[item];
        var purchasable = itemData.values.ItemPurchasable !== '0';
        var itemCost = itemData.values.ItemCost;

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
      var itemData = items[item];
      var itemNameParts = item.split('_');
      var itemRecipeParts = itemNameParts.concat();
      itemRecipeParts.splice(1, 0, 'recipe');
      var probableRecipeName = itemRecipeParts.join('_');

      var recipe = recipesByResult[item];
      var recipeData = recipe
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
      var requirements = recipeData.ItemRequirements.values;
      var numIndex = 1;
      requirements = Object.keys(requirements)
        .sort(function (a, b) { return Number(a) - Number(b); })
        .map(function (index) {
          t.equal(Number(index), numIndex++, 'requirements indexes are in oreder for ' + item);
          return requirements[index].split(';').filter(a => !!a);
        });

      itemData.cost = Number.MAX_VALUE;
      itemData.totalCost = Number.MAX_VALUE;
      itemData.recipes = requirements;
      itemData.recipe = recipeData;
      itemData.purchasable = false;

      calculateCost(item);

      var upgradeCores = [];
      var firstReq = null;
      var firstCore = null;
      requirements.forEach(function (reqList) {
        var coreTier = null;
        reqList.forEach(function (reqItem) {
          var match = reqItem.match(/item_upgrade_core_?([0-9])?/);
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
             FightRecapLevel: '1',
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
      t.equal(items[item].baseCost, items[item].cost, 'cost is set correctly in kv for ' + item);

      // this chunk of code will write the item costs in the file for you
      // useful...
      if (items[item].baseCost !== items[item].cost) {
        var fileName = itemFileMap[item];
        var foundIt = false;
        var lines = fs.readFileSync(fileName, { encoding: 'utf8' })
          .split('\n')
          .map(function (line) {
            var parts = line.split(/[\s ]+/).filter(a => a && a.length);
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
    var itemData = items[item];
    var requirements = itemData.recipes;

    requirements.forEach(function (reqList) {
      var cost = Number(itemData.recipe.values.ItemCost);
      var totalCost = Number(itemData.recipe.values.ItemCost);
      reqList.forEach(function (reqItem) {
        if (item === reqItem) {
          // this item builds into itself
          // probably charge refreshing by rebuying recipe
          console.log(item, 'builds into itself');
          cost = Number.MAX_VALUE;
          totalCost = Number.MAX_VALUE;
          return;
        }
        var parentItem = items[reqItem];
        if (!parentItem) {
          if (!dotaItems[reqItem] && !recipes[reqItem]) {
            t.fail('Item ' + item + ' is made out of an unknown item ' + reqItem);
            return;
          }
          var baseItem = recipes[reqItem] || dotaItems[reqItem];
          var baseItemCost = Number(baseItem.values.ItemCost);
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
  var nameParts = name.split('_');
  if (Number.isFinite(Number(nameParts.pop()))) {
    return nameParts.join('_');
  }
  return name;
}
