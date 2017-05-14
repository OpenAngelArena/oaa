require('game/scripts/vscripts/libraries/math')

TestMath = {}

function TestMath:setUp()
  print("Testing doLinesIntersect() from libraries/math.lua")
  self.P1 = { x = 0, y = 0 }
  self.P2 = { x = 1, y = 1 }
  self.P3 = { x = 0, y = 1 }
  self.P4 = { x = 1, y = 0 }
  self.P5 = { x = -1, y = 1 }
  self.P6 = { x = 1, y = -1 }
  self.P7 = { x = 0, y = -1 }
  self.P8 = { x = -1, y = 0 }
  self.P9 = { x = -1, y = -1 }
end

function TestMath:test1()
  print("with a simple intersection at (0,0)")
  local isIntersecting, intersection = math.doLinesIntersect(self.P5, self.P6, self.P9, self.P2)
  luaunit.assertTrue(isIntersecting)
  luaunit.assertEquals(intersection, self.P1)
end

function TestMath:test2()
  print("with parallel not touching lines")
  local isIntersecting, intersection = math.doLinesIntersect(self.P5, self.P2, self.P9, self.P6)
  luaunit.assertFalse(isIntersecting)
end

function TestMath:test3()
  print("with weird not touching lines")
  local isIntersecting, intersection = math.doLinesIntersect(self.P9, self.P1, self.P7, self.P6)
  luaunit.assertFalse(isIntersecting)
end

function TestMath:test4()
  print("with lines touching at the end")
  local isIntersecting, intersection = math.doLinesIntersect(self.P5, self.P3, self.P2, self.P3)
  luaunit.assertTrue(isIntersecting)
  luaunit.assertEquals(intersection, self.P3)
end

function TestMath:test5()
  print("with the same lines")
  local isIntersecting, intersection = math.doLinesIntersect(self.P1, self.P2, self.P1, self.P2)
  luaunit.assertTrue(isIntersecting)
  luaunit.assertEquals(intersection, self.P1)
end
