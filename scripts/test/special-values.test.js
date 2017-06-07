var test = require('tape');
var Lib = require('../kv-lib');
var path = require('path');
var fs = require('fs');
var after = require('after');
var spok = require('spok');
var partial = require('ap').partial;

var dotaItems = null;
var dotaAbilities = null;
var dotaItemList = null;
var dotaAbilityList = null;
var stupidItemNames = [
  'item_recipe',
  'item_halloween_candy_corn',
  'item_halloween_rapier',
  'item_firework_mine',
  'nothing'
];

var itemsFound = {};
var idsFound = {};
var nextAvailableId = 3000;

test('KV Values', function (t) {
  t.test('before', function (t) {
    t.plan(4);
    Lib.dotaItems(function (err, data) {
      t.notOk(err, 'no err while reading dota items');
      dotaItems = data;
      dotaItemList = Object.keys(dotaItems);
      t.ok(Object.keys(data).length > 1, 'gets dota items from github');
    });
    Lib.dotaAbilities(function (err, data) {
      t.notOk(err, 'no err while reading dota abilities');
      dotaAbilities = data;
      dotaAbilityList = Object.keys(dotaAbilities);
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
      var done = after(keys.length, t.end);
      keys.forEach(function (name) {
        checkKVData(t, name, data[name], true, done);
      });
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
    console.log('Next available ID is', nextAvailableId);
    t.end();
  });
});

var specialValuesForItem = {};

function checkKVData (t, name, data, isItem, cb) {
  t.test(name, function (t) {
    var root = data;
    if (root.DOTAItems) {
      root = root.DOTAItems;
    }
    if (root.DOTAAbilities) {
      root = root.DOTAAbilities;
    }
    var keys = Object.keys(root).filter(a => a !== 'values');
    var done = after(keys.length, function (err) {
      t.notOk(err, 'no error at very end');
      t.end();
      cb(err);
    });
    keys.forEach(partial(testKVItem, t, root, isItem, done));
  });
}

function testKVItem (t, root, isItem, cb, item) {
  var iconDirectory = isItem
    ? 'items'
    : 'spellicons';
  // t.test(item, function (t) {
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
    t.ok(isBuiltIn || values.ID, 'must have an item id');
    t.notOk(idsFound[values.ID], 'must have a unique ID');
  }

  itemsFound[item] = item;
  idsFound[values.ID] = item;

  while (idsFound['' + nextAvailableId]) {
    nextAvailableId += 1;
  }

  var icon = values.AbilityTextureName;
  if (icon && stupidItemNames.indexOf(icon) === -1 && dotaItemList.indexOf(icon) === -1 && dotaAbilityList.indexOf(icon) === -1) {
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
  if (values.BaseClass) {
    if (isItem) {
      t.ok(dotaItems[values.BaseClass], 'base class ' + values.BaseClass + ' must be item_datadriven, item_lua, or a built in item');
    } else {
      t.ok(dotaAbilities[values.BaseClass], 'base class ' + values.BaseClass + ' must be ability_datadriven, ability_lua, or a built in ability');
    }
  } else {
    if (isItem) {
      t.ok(dotaItems[item], 'missing baseclass only allowed when overriding built in items');
      if (dotaItems[item] && values.ID) {
        t.equals(values.ID, dotaItems[item].values.ID, 'ID must not be changed from base dota item');
      }
    } else {
      t.ok(dotaAbilities[item], 'missing baseclass only allowed when overriding built in abilities');
      if (dotaAbilities[item] && values.ID) {
        t.equals(values.ID, dotaAbilities[item].values.ID, 'ID must not be changed from base dota ability');
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
      testSpecialValues(t, specials);
      specialValuesForItem[rootItem] = specials;
    } else {
      spok(t, specials, specialValuesForItem[rootItem], 'special values are consistent');
    }
    done();
  } else {
    done();
  }
  // });
}

function testSpecialValues (t, specials) {
  var values = Object.keys(specials).filter(a => a !== 'values');
  var result = {};

  values.forEach(function (num) {
    var value = specials[num].values;
    t.ok(value.var_type, 'has a var_type ' + num);
    var hasLinkedSpecial = !!value.LinkedSpecialBonus;
    var hasLinkedSpecialOperation = !!value.LinkedSpecialBonusOperation;

    var hasSpellDamageTooltip = !!value.CalculateSpellDamageTooltip;
    var hasLevelkey = !!value.levelkey;
    var keyNames = Object.keys(value).filter(a => a !== 'var_type');

    if (hasLinkedSpecial) {
      keyNames = keyNames.filter(a => a !== 'LinkedSpecialBonus');
    }
    if (hasLinkedSpecialOperation) {
      keyNames = keyNames.filter(a => a !== 'LinkedSpecialBonusOperation');
    }
    if (hasSpellDamageTooltip) {
      keyNames = keyNames.filter(a => a !== 'CalculateSpellDamageTooltip');
    }
    if (hasLevelkey) {
      keyNames = keyNames.filter(a => a !== 'levelkey');
    }
    t.equal(keyNames.length, 1, 'gets keyname after filtering out extra values');

    var keyName = keyNames[0];

    if (result[keyName]) {
      t.fail('Special value found twice: ' + keyName);
    }
    result[keyName] = value[keyName];
  });

  return result;
}
