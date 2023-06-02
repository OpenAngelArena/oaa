if not _ListenToGameEvent then
  _ListenToGameEvent = ListenToGameEvent
end

-- ListenToGameEvent('event_name', Dynamic_Wrap(class_object, 'function_name'), class_object)
function ListenToGameEvent (eventName, fn, obj)
  return _ListenToGameEvent(eventName, function (...)
    local data = {...}
    local status, err = pcall(function() --luacheck: ignore status
      fn(unpack(data))
    end)
    if err then
      print(err)
      error(err)
    end
  end, obj)
end
