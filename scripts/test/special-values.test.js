var test = require('tape');
var Lib = require('../kv-lib');
var path = require('path');
var fs = require('fs');
var after = require('after');
var spok = require('spok');
var partial = require('ap').partial;

test('kv files dont repeat special values', function (t) {
  Lib.all(function (err, data) {
    if (err) {
      t.notOk(err, 'no err while reading kvs');
      return t.end();
    }

    Object.keys(data).forEach(function (name) {
      checkKVData(t, name, data[name]);
    });
  });
});

var specialValuesForItem = {};

function checkKVData (test, name, data) {
  test.test(name, function (t) {
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
    });
    keys.forEach(partial(testKVItem, t, root, done));
  });
}

function testKVItem (t, root, cb, item) {
  t.test(item, function (t) {
    var done = after(2, function (err) {
      t.notOk(err, 'no error at very end');
      t.end();
      cb(err);
    });
    var values = root[item].values;
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
  });
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
