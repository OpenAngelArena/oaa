var test = require('tape');
var findTooltips = require('../find-tooltips');

test('can read in tooltip list', function (t) {
  var getTranslations = require('../parse-translation');
  t.ok(Object.keys(getTranslations().lang.Tokens.values).length, 'there are tokens');
  console.log(Object.keys(getTranslations().lang.Tokens.values).length);
  t.end();
});

test('can read list of items', function (t) {
  findTooltips.findAllItems(function (err, data) {
    t.notOk(err, 'no error');
    t.ok(data.length);
    console.log(data.length);
    t.end();
  });
});
var itemPaths = null;
test('lists item paths', function (t) {
  findTooltips.listAllItems(function (err, lines) {
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

  findTooltips.parseFile(path, function (err, data) {
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
