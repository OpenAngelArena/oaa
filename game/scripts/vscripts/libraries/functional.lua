--[[

Functional programming library

Created by chrisinajar

]]


--[[
partial (fn, ...)

fn - any function reference
... - parameters for partial application

Returns a version of fn which when executed will have `...` parameters passed in to it first

```
function add (a, b)
  return a + b
end

local addToFive = partial(add, 5)

print(addToFive(3)) -- prints 8
```

]]
function partial (fn, ...)
  local arg = {...}
  local partialArguments = arg
  local partialArgumentsLength = #arg

  local function executeMethod (...)
    local arg = {...}
    local argLength = #arg
    local totalLength = argLength + partialArgumentsLength
    local fnArgs = {}

    for i,v in ipairs(partialArguments) do
      fnArgs[i] = v
    end
    for i,v in ipairs(arg) do
      fnArgs[partialArgumentsLength + i] = v
    end

    return fn(unpack(fnArgs))
  end

  return executeMethod
end

--[[

forEach(myArray, function (value)
  print(value)
end)

]]
-- function forEach (ar, fn)
--   for i,v in ipairs(ar) do
--     fn(v, i)
--   end
--   return ar
-- end


--[[

myArray = map(myArray, function (value)
  return value .. 'boo'
end)

]]
-- function map (ar, fn)
--   local newAr = {}
--   for i,v in ipairs(ar) do
--     newAr[i] = fn(v, i)
--   end
--   return newAr
-- end

function after (count, callback)
  local result = {}
  local function done(...)
    table.insert(result, {...})
    count = count - 1
    if count == 0 then
      callback(result)
    end
  end
  return done
end

-- Returns a function that calls methodName on any given object, passing the object
-- as the first argument along with any additional arguments given to CallMethod
function CallMethod(methodName, ...)
  local caller
  -- Since this is meant to call C++, it has to be very specific about the number of arguments.
  -- Using unpack(args) unconditionally would result in an extra nil argument
  -- if no argument was given to CallMethod
  if select('#', ...) > 0 then
    local args = {...}
    caller = function (object)
      return object[methodName](object, unpack(args))
    end
  else
    caller = function (object)
      return object[methodName](object)
    end
  end
  return caller
end
