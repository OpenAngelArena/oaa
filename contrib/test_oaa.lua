luaunit = require('contrib/luaunit')
require('contrib/test_math')
require('contrib/test_util')

local runner = luaunit.LuaUnit.new()
runner:setOutputType("tap")
os.exit( runner:runSuite() )
