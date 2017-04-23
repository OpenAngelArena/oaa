
require('libraries/timers')

if GarbageCollection == nil then
  print('Creating new GarbageCollection object')
  GarbageCollection = class({})
end

function GarbageCollection:Add(table, duration)
  return Timers:CreateTimer(function()
    GarbageCollection:CollectTrash(table)
    return duration
  end)
end

function GarbageCollection:Remove(name)
  Timers:RemoveTimer(name)
end

function GarbageCollection:CollectTrash(table)
  print('I\'m just cleaning up.')
  table = filter(function(x) return x ~= nil end, table)
end
