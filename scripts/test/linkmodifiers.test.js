const test = require('tape');
const luaEntitiesUtil = require('../lua-entities-util');

test('all LinkLuaModifiers point to existing files', function (t) {
  const luaFiles = luaEntitiesUtil.listAllLuaFiles();
  const callback = function (err, _modifiers) {
    t.notOk(err);
  };

  for (const index in luaFiles) {
    luaEntitiesUtil.findLinkLuaModifiersInFile(luaFiles[index], callback, true, true);
  }

  t.end();
});
