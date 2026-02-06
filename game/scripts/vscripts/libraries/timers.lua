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

-- Min-heap helper functions for O(log n) timer management
-- Heap entries are {endTime, name} pairs, ordered by endTime

local function heap_parent(i)
  return math.floor(i / 2)
end

local function heap_left(i)
  return 2 * i
end

local function heap_right(i)
  return 2 * i + 1
end

local function heap_swap(heap, i, j)
  heap[i], heap[j] = heap[j], heap[i]
end

local function heap_bubble_up(heap, i)
  while i > 1 do
    local p = heap_parent(i)
    if heap[p][1] <= heap[i][1] then
      break
    end
    heap_swap(heap, i, p)
    i = p
  end
end

local function heap_bubble_down(heap, i)
  local n = #heap
  while true do
    local smallest = i
    local l = heap_left(i)
    local r = heap_right(i)

    if l <= n and heap[l][1] < heap[smallest][1] then
      smallest = l
    end
    if r <= n and heap[r][1] < heap[smallest][1] then
      smallest = r
    end

    if smallest == i then
      break
    end

    heap_swap(heap, i, smallest)
    i = smallest
  end
end

local function heap_push(heap, endTime, name)
  local entry = {endTime, name}
  heap[#heap + 1] = entry
  heap_bubble_up(heap, #heap)
end

local function heap_pop(heap)
  local n = #heap
  if n == 0 then
    return nil
  end

  local top = heap[1]
  if n == 1 then
    heap[1] = nil
  else
    heap[1] = heap[n]
    heap[n] = nil
    heap_bubble_down(heap, 1)
  end

  return top
end

local function heap_peek(heap)
  return heap[1]
end

function Timers:start()
  Timers = self
  self.timers = {}

  -- Initialize heaps for efficient timer management
  self.gameTimeHeap = {}
  self.realTimeHeap = {}

  -- Lazy deletion sets for removed timers still in heaps
  self.gameTimeRemoved = {}
  self.realTimeRemoved = {}

  -- Counter for periodic heap cleanup
  self.thinkCount = 0

  --local ent = Entities:CreateByClassname("info_target") -- Entities:FindByClassname(nil, 'CWorld')
  local ent = SpawnEntityFromTableSynchronous("info_target", {targetname="timers_lua_thinker"})
  ent:SetThink("Think", self, "timers", TIMERS_THINK)
end

-- Process a single heap, executing all ready timers
local function ProcessHeap(heap, removedSet, now)
  while true do
    local top = heap_peek(heap)
    if not top then
      break
    end

    local endTime = top[1]
    local name = top[2]

    -- Early exit: if the smallest endTime is still in the future, nothing is ready
    if endTime > now then
      break
    end

    -- Pop this timer from the heap
    heap_pop(heap)

    -- Check for lazy deletion
    if removedSet[name] then
      removedSet[name] = nil
    else
      -- Get the timer data
      local v = Timers.timers[name]

      -- Timer might have been removed or replaced since it was pushed
      if v and v.endTime == endTime then
        -- Remove from timers lookup
        Timers.timers[name] = nil

        local bOldStyle = v.useOldStyle == true

        Timers.runningTimer = name
        Timers.removeSelf = false

        -- Run the callback
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

        -- Make sure it worked
        if status then
          -- Check if it needs to loop
          if nextCall and not Timers.removeSelf then
            -- Change its end time
            if bOldStyle then
              v.endTime = v.endTime + nextCall - now
            else
              v.endTime = v.endTime + nextCall
            end

            -- Re-add to timers table and heap
            Timers.timers[name] = v
            heap_push(heap, v.endTime, name)
          end
        else
          -- Nope, handle the error
          Timers:HandleEventError('Timer', name, nextCall)
        end
      end
    end
  end
end

-- Rebuild a heap, filtering out removed and stale entries
local function RebuildHeap(oldHeap, removedSet, timersTable)
  local newHeap = {}
  for i = 1, #oldHeap do
    local entry = oldHeap[i]
    local endTime = entry[1]
    local name = entry[2]
    local timer = timersTable[name]
    -- Only keep entries that aren't marked removed, exist in timers table,
    -- and have matching endTime (filters out stale entries from replaced timers)
    if not removedSet[name] and timer and timer.endTime == endTime then
      heap_push(newHeap, endTime, name)
    end
  end
  return newHeap
end

-- How often to run cleanup (in think ticks, ~10 seconds at 0.01s per tick)
local CLEANUP_INTERVAL = 1000

function Timers:Think()
  --if GameRules:State_Get() >= DOTA_GAMERULES_STATE_POST_GAME then
    --return
  --end

  -- Track game time, since the dt passed in to think is actually wall-clock time not simulation time.
  local gameTimeNow = GameRules:GetGameTime()
  local realTimeNow = Time()

  -- Process game time timers
  ProcessHeap(self.gameTimeHeap, self.gameTimeRemoved, gameTimeNow)

  -- Process real time timers
  ProcessHeap(self.realTimeHeap, self.realTimeRemoved, realTimeNow)

  -- Periodic cleanup to remove stale entries from heaps
  self.thinkCount = self.thinkCount + 1
  if self.thinkCount >= CLEANUP_INTERVAL then
    self.thinkCount = 0

    -- Only rebuild if there are removed entries to clean up
    if next(self.gameTimeRemoved) then
      self.gameTimeHeap = RebuildHeap(self.gameTimeHeap, self.gameTimeRemoved, self.timers)
      self.gameTimeRemoved = {}
    end
    if next(self.realTimeRemoved) then
      self.realTimeHeap = RebuildHeap(self.realTimeHeap, self.realTimeRemoved, self.timers)
      self.realTimeRemoved = {}
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
  local v = Timers.timers[name]
  local bUseGameTime = v.useGameTime == nil or v.useGameTime ~= false

  local now = GameRules:GetGameTime()
  if not bUseGameTime then
    now = Time()
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

  local bUseGameTime = args.useGameTime == nil or args.useGameTime ~= false

  local now = GameRules:GetGameTime()
  if not bUseGameTime then
    now = Time()
  end

  if args.endTime == nil then
    args.endTime = now
  elseif args.useOldStyle == nil or args.useOldStyle == false then
    args.endTime = now + args.endTime
  end

  args.context = context

  Timers.timers[name] = args

  -- Push onto the appropriate heap and clear any lazy deletion mark
  if bUseGameTime then
    Timers.gameTimeRemoved[name] = nil
    heap_push(Timers.gameTimeHeap, args.endTime, name)
  else
    Timers.realTimeRemoved[name] = nil
    heap_push(Timers.realTimeHeap, args.endTime, name)
  end

  return name
end

function Timers:RemoveTimer(name)
  local timer = Timers.timers[name]
  if timer then
    -- Mark for lazy deletion in the appropriate heap
    local bUseGameTime = timer.useGameTime == nil or timer.useGameTime ~= false
    if bUseGameTime then
      Timers.gameTimeRemoved[name] = true
    else
      Timers.realTimeRemoved[name] = true
    end
  else
    -- Timer already removed from table, mark in both sets to be safe
    Timers.gameTimeRemoved[name] = true
    Timers.realTimeRemoved[name] = true
  end

  Timers.timers[name] = nil
  if Timers.runningTimer == name then
    Timers.removeSelf = true
  end
end

function Timers:RemoveTimers(killAll)
  Timers.removeSelf = true

  if killAll then
    -- Clear everything
    Timers.timers = {}
    Timers.gameTimeHeap = {}
    Timers.realTimeHeap = {}
    Timers.gameTimeRemoved = {}
    Timers.realTimeRemoved = {}
  else
    -- Keep only persistent timers, rebuild heaps
    local timers = {}
    local gameTimeHeap = {}
    local realTimeHeap = {}

    for k, v in pairs(Timers.timers) do
      if v.persist then
        timers[k] = v
        local bUseGameTime = v.useGameTime == nil or v.useGameTime ~= false
        if bUseGameTime then
          heap_push(gameTimeHeap, v.endTime, k)
        else
          heap_push(realTimeHeap, v.endTime, k)
        end
      end
    end

    Timers.timers = timers
    Timers.gameTimeHeap = gameTimeHeap
    Timers.realTimeHeap = realTimeHeap
    Timers.gameTimeRemoved = {}
    Timers.realTimeRemoved = {}
  end
end

if not Timers.timers then Timers:start() end

GameRules.Timers = Timers
