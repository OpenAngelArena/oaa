var test = require('tape');
var luaEntitiesUtil = require('../lua-entities-util');

test('all LinkLuaModifiers point to existing files', function (t) {
  var luaFiles = luaEntitiesUtil.listAllLuaFiles();
  var callback = function (err, _modifiers) {
    t.notOk(err);
  };

  for (var index in luaFiles) {
    luaEntitiesUtil.findLinkLuaModifiersInFile(luaFiles[index], callback, true, true);
  }

  t.end();
});
