
function Event ()
  local state = {
    listeners = {}
  }

  function listen (fn)
    local handler = {
      fn = fn,
      removed = false
    }
    table.insert(state.listeners, handler)

    function unlisten ()
      for index = 1,#state.listeners do
        if state.listeners[index] == handler then
          table.remove(state.listeners, index)
          handler.removed = true
          return
        end
      end
    end

    return unlisten
  end

  function broadcast ( ... )
    for index = 1,#state.listeners do
      local handler = state.listeners[index]
      if handler and not handler.removed then
        handler.fn(unpack({...}))
      end
    end
  end

  return {
    broadcast = broadcast,
    listen = listen
  }
end
