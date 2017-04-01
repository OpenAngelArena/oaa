require('game/scripts/vscripts/libraries/functional')

TestPartial = {}

function TestPartial:setUp ()
  print("Testing partial() from function.lua")
end

function add (a, b)
  return a + b
end

function TestPartial:test1 ()
  print("simple test")
  local addToFive = partial(add, 5)
  assertEquals(addToFive(5), 10)
  assertEquals(addToFive(-5), 0)
  assertEquals(addToFive(-10), -5)
end

function TestPartial:test2 ()
  print("same as before but now with recursion")
  local addToFive = partial(add, 5)
  local addToMinusFive = partial(addToFive, -10)
  assertEquals(addToMinusFive(5), 0)
  assertEquals(addToMinusFive(-5), -10)
  assertEquals(addToMinusFive(10), 5)
end
