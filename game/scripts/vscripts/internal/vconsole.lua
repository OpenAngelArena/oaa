_print = print
_error = error
--_assert = assert

--_print("print", print)
--_print("error", error)
--_print("assert", assert)

function print(...)
  local data = {...}
  if not IsInToolsMode() then
    CustomGameEventManager:Send_ServerToAllClients("vconsole", {
      type = "print",
      data = data
    })
    data[1] = '[Server] ' .. data[1]
  end
  _print(unpack(data))
end

function error(...)
  local args = {...}
  local offset = args[2] or 2
  local info = debug.getinfo(offset, "Sl")
  local data = {
    "Script Runtime Error: " .. info.source:sub(2) .. ":" .. info.currentline .. ": " .. args[1],
    debug.traceback()
  }
  CustomGameEventManager:Send_ServerToAllClients("vconsole", {
    type = "error",
    data = data -- pass traceback to panorma
  })
  for k,v in pairs(data) do
    _print(k, tostring(v))
  end
  _error(unpack({...}))
end

--_print("print", print)
--_print("error", error)
--_print("assert", assert)
