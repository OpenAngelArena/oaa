_print = _print or print
_error = _error or error
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
    if data[1] then
      data[1] = '[Server] ' .. data[1]
    else
      data[1] = '[Server] --'
    end
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

  -- Report to the external server immediately (This is blocked by calls futrther down unfortunately, so it needs to run early)
  local mode = "Unknown game mode!"
  if IsInToolsMode() then
    mode = "Tools Mode"
  elseif GameRules:IsCheatMode() then
    mode = "Cheat Mode"
  end
  D2CustomLogging:sendPayloadForTracking(D2CustomLogging.LOG_LEVEL_EXCEPTION, "CAPTURED_EXCEPTION", {
    ErrorMessage = "Script Runtime Error: " .. info.source:sub(2) .. ":" .. info.currentline .. ": " .. args[1],
    ErrorTime = GetSystemDate() .. " " .. GetSystemTime(),
    GameVersion = GAME_VERSION,
    GameMode = mode,
    DedicatedServers = (IsDedicatedServer() and 1) or 0,
    MatchID = tostring(GameRules:GetMatchID())
  })

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
