function table.clone(org)
  return {unpack(org)}
end

function Event ()
  local state = {
    listeners = {}
  }

  local api = {
    debug = false
  }

  local function listen (fn)
    if api.debug then
      print('Adding listener')
    end
    local handler = {
      fn = fn,
      removed = false
    }
    table.insert(state.listeners, handler)

    local function unlisten ()
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

  local function broadcast ( ... )
    if api.debug then
      print('Triggering ' .. #state.listeners .. ' listener')
    end
    if #state.listeners == 0 then
      return
    end
    local handlers = table.clone(state.listeners)
    local data = {...}
    local errors = {}

    for index = 1,#handlers do
      local handler = handlers[index]
      if handler and not handler.removed then
        local status, err = pcall(function ()
          handler.fn(unpack(data))
        end)
        if err then
          print(err)
          table.insert(errors, err)
        end
      end
    end

    for index = 1,#errors do
      -- this will throw and not print any of the others, but whatever
      error(errors[index])
    end
  end

  api.broadcast = broadcast
  api.listen = listen

  return api
end
