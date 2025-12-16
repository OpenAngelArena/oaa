TIMERS_VERSION = "1.06"

--[[

  -- A timer running every second that starts immediately on the next frame, respects pauses
  Timers:CreateTimer(function()
      print ("Hello. I'm running immediately and then every second thereafter.")
      return 1.0
    end
  )

  -- The same timer as above with a shorthand call
  Timers(function()
    print ("Hello. I'm running immediately and then every second thereafter.")
    return 1.0
  end)


  -- A timer which calls a function with a table context
  Timers:CreateTimer(GameMode.someFunction, GameMode)

  -- A timer running every second that starts 5 seconds in the future, respects pauses
  Timers:CreateTimer(5, function()
      print ("Hello. I'm running 5 seconds after you called me and then every second thereafter.")
      return 1.0
    end
  )

  -- 10 second delayed, run once using gametime (respect pauses)
  Timers:CreateTimer({
    endTime = 10, -- when this timer should first execute, you can omit this if you want it to run first on the next frame
    callback = function()
      print ("Hello. I'm running 10 seconds after when I was started.")
    end
  })

  -- 10 second delayed, run once regardless of pauses
  Timers:CreateTimer({
    useGameTime = false,
    endTime = 10, -- when this timer should first execute, you can omit this if you want it to run first on the next frame
    callback = function()
      print ("Hello. I'm running 10 seconds after I was started even if someone paused the game.")
    end
  })


  -- A timer running every second that starts after 2 minutes regardless of pauses
  Timers:CreateTimer("uniqueTimerString3", {
    useGameTime = false,
    endTime = 120,
    callback = function()
      print ("Hello. I'm running after 2 minutes and then every second thereafter.")
      return 1
    end
  })


  -- A timer using the old style to repeat every second starting 5 seconds ahead
  Timers:CreateTimer("uniqueTimerString3", {
    useOldStyle = true,
    endTime = GameRules:GetGameTime() + 5,
    callback = function()
      print ("Hello. I'm running after 5 seconds and then every second thereafter.")
      return GameRules:GetGameTime() + 1
    end
  })

]]



TIMERS_THINK = 0.01

if Timers == nil then
  print ( '[Timers] creating Timers' )
  Timers = {}
  setmetatable(Timers, {
    __call = function(t, ...)
      return t:CreateTimer(...)
    end
  })
  --Timers.__index = Timers
end

-- lightweight binary min-heap for timers by endTime
local function heap_new()
  return { items = {}, size = 0 }
end

local function heap_swap(h, i, j)
  local a, b = h.items[i], h.items[j]
  h.items[i], h.items[j] = b, a
  if a then a._heapIndex = j end
  if b then b._heapIndex = i end
end

local function heap_sift_up(h, i)
  while i > 1 do
    local parent = math.floor(i / 2)
    if h.items[parent].endTime <= h.items[i].endTime then break end
    heap_swap(h, parent, i)
    i = parent
  end
end

local function heap_sift_down(h, i)
  local size = h.size
  while true do
    local left = i * 2
    if left > size then break end
    local right = left + 1
    local smallest = left
    if right <= size and h.items[right].endTime < h.items[left].endTime then
      smallest = right
    end
    if h.items[i].endTime <= h.items[smallest].endTime then break end
    heap_swap(h, i, smallest)
    i = smallest
  end
end

local function heap_push(h, item)
  h.size = h.size + 1
  h.items[h.size] = item
  item._heapIndex = h.size
  heap_sift_up(h, h.size)
end

local function heap_peek(h)
  if h.size == 0 then return nil end
  return h.items[1]
end

local function heap_pop(h)
  local top = heap_peek(h)
  if not top then return nil end
  local last = h.items[h.size]
  h.items[1] = last
  h.items[h.size] = nil
  h.size = h.size - 1
  if last then last._heapIndex = 1 end
  if h.size > 0 then
    heap_sift_down(h, 1)
  end
  if top then top._heapIndex = nil end
  return top
end

local function heap_remove(h, item)
  local idx = item and item._heapIndex
  if not idx or idx < 1 or idx > h.size then return end
  if idx == h.size then
    h.items[idx] = nil
    h.size = h.size - 1
    item._heapIndex = nil
    return
  end
  local last = h.items[h.size]
  h.items[idx] = last
  h.items[h.size] = nil
  h.size = h.size - 1
  last._heapIndex = idx
  item._heapIndex = nil
  -- decide direction
  if last.endTime < (h.items[math.floor(idx/2)] and h.items[math.floor(idx/2)].endTime or last.endTime) then
    heap_sift_up(h, idx)
  else
    heap_sift_down(h, idx)
  end
end

local function heap_update(h, item)
  local idx = item and item._heapIndex
  if not idx or idx < 1 or idx > h.size then return end
  -- try both ways cheaply
  local parent = math.floor(idx/2)
  if parent >= 1 and h.items[parent].endTime > item.endTime then
    heap_sift_up(h, idx)
  else
    heap_sift_down(h, idx)
  end
end

function Timers:start()
  Timers = self
  self.timers = {}
  -- two heaps: game time and real time
  self._gameHeap = heap_new()
  self._realHeap = heap_new()

  --local ent = Entities:CreateByClassname("info_target") -- Entities:FindByClassname(nil, 'CWorld')
  local ent = SpawnEntityFromTableSynchronous("info_target", {targetname="timers_lua_thinker"})
  ent:SetThink("Think", self, "timers", TIMERS_THINK)
end

function Timers:_ProcessTimer(name, v, now)
  Timers.runningTimer = name
  Timers.removeSelf = false

  local status, nextCall
  if v.context then
    status, nextCall = xpcall(function() return v.callback(v.context, v) end, function (msg)
      return msg..'\n'..debug.traceback()..'\n'
    end)
  else
    status, nextCall = xpcall(function() return v.callback(v) end, function (msg)
      return msg..'\n'..debug.traceback()..'\n'
    end)
  end

  Timers.runningTimer = nil

  if status then
    if nextCall and not Timers.removeSelf then
      local bOldStyle = v.useOldStyle ~= nil and v.useOldStyle == true
      if bOldStyle then
        v.endTime = v.endTime + nextCall - now
      else
        v.endTime = v.endTime + nextCall
      end
      if v._heapType == 'game' then
        if v._heapIndex then
          heap_update(Timers._gameHeap, v)
        else
          heap_push(Timers._gameHeap, v)
        end
        Timers.timers[name] = v
      else
        if v._heapIndex then
          heap_update(Timers._realHeap, v)
        else
          heap_push(Timers._realHeap, v)
        end
        Timers.timers[name] = v
      end
    end
  else
    Timers:HandleEventError('Timer', name, nextCall)
  end
end

function Timers:Think()
  --if GameRules:State_Get() >= DOTA_GAMERULES_STATE_POST_GAME then
    --return
  --end

  -- Track game time, since the dt passed in to think is actually wall-clock time not simulation time.
  local nowGame = GameRules:GetGameTime()
  local nowReal = Time()

  -- Process game-time timers
  while true do
    local top = heap_peek(Timers._gameHeap)
    if not top or top.endTime > nowGame then break end
    heap_pop(Timers._gameHeap)
    local name = top._name
    -- Remove from map; guard against stale entries
    local v = Timers.timers[name]
    if v == top then
      Timers.timers[name] = nil
      top._heapIndex = nil
      Timers:_ProcessTimer(name, top, nowGame)
    end
  end

  -- Process real-time timers
  while true do
    local top = heap_peek(Timers._realHeap)
    if not top or top.endTime > nowReal then break end
    heap_pop(Timers._realHeap)
    local name = top._name
    local v = Timers.timers[name]
    if v == top then
      Timers.timers[name] = nil
      top._heapIndex = nil
      Timers:_ProcessTimer(name, top, nowReal)
    end
  end

  return TIMERS_THINK
end

function Timers:HandleEventError(name, event, err)
  print(err)

  -- Ensure we have data
  name = tostring(name or 'unknown')
  event = tostring(event or 'unknown')
  err = tostring(err or 'unknown')

  -- Tell everyone there was an error
  --Say(nil, name .. ' threw an error on event '..event, false)
  --Say(nil, err, false)

  -- Prevent loop arounds
  if not self.errorHandled then
    -- Store that we handled an error
    self.errorHandled = true
  end
end

function Timers:RemainingTime(name)
  --Calculates Remaining Time on a given timer
  local v = Timers.timers[name]
  local bUseGameTime = true
  if v.useGameTime ~= nil and v.useGameTime == false then
    bUseGameTime = false
  end
  local bOldStyle = false
  if v.useOldStyle ~= nil and v.useOldStyle == true then
    bOldStyle = true
  end
  local now = GameRules:GetGameTime()
  if not bUseGameTime then
    now = Time()
  end

  if v.endTime == nil then
    v.endTime = now
  end

  return v.endTime - now
end

function Timers:CreateTimer(name, args, context)
  if type(name) == "function" then
    if args ~= nil then
      context = args
    end
    args = {callback = name}
    name = DoUniqueString("timer")
  elseif type(name) == "table" then
    args = name
    name = DoUniqueString("timer")
  elseif type(name) == "number" then
    args = {endTime = name, callback = args}
    name = DoUniqueString("timer")
  end
  if not args.callback then
    print("Invalid timer created: "..name)
    return
  end

  local useGameTime = not (args.useGameTime ~= nil and args.useGameTime == false)
  local now = useGameTime and GameRules:GetGameTime() or Time()

  if args.endTime == nil then
    args.endTime = now
  elseif args.useOldStyle == nil or args.useOldStyle == false then
    args.endTime = now + args.endTime
  end

  args.context = context
  args._name = name
  args._heapType = useGameTime and 'game' or 'real'

  Timers.timers[name] = args
  if useGameTime then
    heap_push(Timers._gameHeap, args)
  else
    heap_push(Timers._realHeap, args)
  end

  return name
end

function Timers:RemoveTimer(name)
  local v = Timers.timers[name]
  if v then
    Timers.timers[name] = nil
    if v._heapType == 'game' then
      heap_remove(Timers._gameHeap, v)
    else
      heap_remove(Timers._realHeap, v)
    end
  end
  if Timers.runningTimer == name then
    Timers.removeSelf = true
  end
end

function Timers:RemoveTimers(killAll)
  local newMap = {}
  Timers.removeSelf = true

  if killAll then
    -- clear heaps
    self._gameHeap = heap_new()
    self._realHeap = heap_new()
  else
    -- retain only persist timers, rebuild heaps
    local gameHeap = heap_new()
    local realHeap = heap_new()
    for k, v in pairs(Timers.timers) do
      if v.persist then
        newMap[k] = v
        if v._heapType == 'game' then
          heap_push(gameHeap, v)
        else
          heap_push(realHeap, v)
        end
      end
    end
    self._gameHeap = gameHeap
    self._realHeap = realHeap
  end

  Timers.timers = newMap
end

if not Timers.timers then Timers:start() end

GameRules.Timers = Timers
