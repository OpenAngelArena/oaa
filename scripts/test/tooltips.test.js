var test = require('tape');
var findTooltips = require('../find-tooltips');
var luaEntitiesUtil = require('../lua-entities-util');

test('can read in tooltip list', function (t) {
  var getTranslations = require('../parse-translation');
  t.ok(Object.keys(getTranslations().lang.Tokens.values).length, 'there are tokens');
  t.end();
});

test('can read list of items', function (t) {
  luaEntitiesUtil.findAllItems(function (err, data) {
    t.notOk(err, 'no error');
    t.ok(data.length);
    t.end();
  });
});
var itemPaths = null;
test('lists item paths', function (t) {
  luaEntitiesUtil.listAllItems(function (err, lines) {
    t.notOk(err);
    t.ok(lines.length);
    itemPaths = lines;
    t.end();
  });
});

test('can parse item', function (t) {
  var index = ~~(Math.random() * itemPaths.length);
  var path = itemPaths[index];
  console.log('Running tests with', path);
  t.ok(path);

  luaEntitiesUtil.parseFile(path, function (err, data) {
    t.notOk(err);
    t.ok(data);
    t.end();
  });
});

test('there are no missing tooltips', function (t) {
  findTooltips.findMissingTooltips(function (err, data) {
    if (err) {
      t.fail(err);
      t.end();
      return;
    }
    t.equal(data.length, 0);
    t.end();
  });
});
