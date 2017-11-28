if not _ListenToGameEvent then
  _ListenToGameEvent = ListenToGameEvent
end

-- ListenToGameEvent('dota_rune_activated_server', Dynamic_Wrap(GameMode, 'OnRuneActivated'), self)
function ListenToGameEvent (eventName, fn, obj)
  return _ListenToGameEvent(eventName, function (...)
    local data = {...}
    local status, err = pcall(function()
      fn(unpack(data))
    end)
    if err then
      print(err)
      error(err)
    end
  end, obj)
end
