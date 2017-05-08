
unpack = unpack or table.unpack
luaunit = require('contrib/luaunit')

require('contrib/test_math')
require('contrib/test_util')
require('contrib/test_functional')

local runner = luaunit.LuaUnit.new()
runner:setOutputType("tap")
os.exit( runner:runSuite() )
