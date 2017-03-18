--[[
===== ChatCommand =====
Makes it easier to create commands from anywhere in your code.
Does not break when using script_reload
Usage:
  -Create a function MyFunction(keys)             OR     function SomeClass:SomeFunction(keys)
    keys are those delivered from the 'player_chat' event
  -Use ChatCommand:LinkCommand("-MyTrigger", "MyFunction")   OR     ChatCommand:LinkCommand("-MyTrigger", "SomeFunction", SomeClass)
    Use this to call this function everytime someone's chat starts with -MyTrigger
created by Zarnotox with a lot of constructive help from the mod data guys https://discord.gg/Z7eCcGT (THIS IS NOT THE AAA DISCORD, THIS IS THE MODDATA DISCORD. YOU DID NOT FIND THE SECRET. check it out!)
]]

ACCESSLEVEL_ADMIN = 10
ACCESSLEVEL_NONE = 0

ACCESSLEVELS = {
  ['76561198069417260'] = ACCESSLEVEL_ADMIN, --Chronophylos
}

ChatCommand = ChatCommand or {}

-- Begin Initialise
function ChatCommand:Init()
  self.initialised = true
  ListenToGameEvent("player_chat", Dynamic_Wrap(ChatCommand, 'OnPlayerChat'), self)
end

if not ChatCommand.initialised then
  ChatCommand:Init()

  ChatCommand.commands = {}
  ChatCommand.commands["-getClearance"] = {
    description = "Get the access level of a Player",
    usage = "[PlayerID]",
    accessLevel = ACCESSLEVEL_NONE,
    funcName = 'CMD_getClearance',
    obj = ChatCommand
  }
  ChatCommand.commands["-help"] = {
    description = "Display this help",
    usage = "",
    accessLevel = ACCESSLEVEL_NONE,
    funcName = 'CMD_Help',
    obj = ChatCommand
  }
  ChatCommand.commands["-settings"] = {
    description = "Manage GameMode Settings",
    usage = "[(get <setting> | set <setting> <value>) | help]",
    accessLevel = ACCESSLEVEL_ADMIN,
    funcName = 'CMD_Settings',
    obj = ChatCommand,
  }
  ChatCommand.commands["-exec"] = {
    description = "Exec Lua Code",
    usage = "<funcName> [<obj>]",
    accessLevel = ACCESSLEVEL_ADMIN,
    funcName = 'CMD_Exec',
    obj = ChatCommand,
  }

end
-- End Initialise

-- Function to create the link
function ChatCommand:LinkCommand(command, description, usage, accessLevel, funcName, obj)
  if string.sub(command, 1, 1) ~= '-' then
    command = '-' + command
  end

  self.commands[command] = {
    description = description,
    usage = usage,
    accessLevel = accessLevel,
    funcName = funcName,
    obj = obj
  }
end

-- Function that's called when somebody chats
function ChatCommand:OnPlayerChat(keys)
  local text = keys.text

  local splitted = split(text, " ")
  keys.command = splitted

  if self.commands[splitted[1]] ~= nil then
    local location = self.commands[splitted[1]]
    accessLevel = location.accessLevel
    funcName = location.funcName

    if not ChatCommand:checkAccessLevel(keys.playerid, accessLevel) then
      Say(PlayerResource:GetPlayer(keys.playerid), "You don't have the required access level for this command!", true)
      return
    end

    PrintTable(location)

    if location.obj == nil then
      _G[funcName](keys)
    else
      local obj = location.obj
      obj[funcName](obj, keys)
    end
  end
end

function ChatCommand:checkAccessLevel (PlayerID, requiredAccessLevel)
  local steamID64 = tostring(PlayerResource:GetSteamID(PlayerID))
  return ACCESSLEVELS[steamID64] >= requiredAccessLevel
end

function ChatCommand:displayUsage (player, command)
  local value = self.commands[command]
  --[[Say(player, "Command: " .. command, true)
  Say(player, "Description: " .. value.description, true)
  Say(player, "Required Access Level: " .. value.accessLevel, true)
  Say(player, "Usage: " .. command .. " " .. value.usage, true)]]
  print("Command: " .. command)
  print("Description: " .. value.description)
  print("Required Access Level: " .. value.accessLevel)
  print("Usage: " .. command .. " " .. value.usage)
end

function ChatCommand:Send (player, text)
  Notifications:Bottom (
    player, {
      text=text,
      duration=5,
      style={
        color="white",
        ["font-size"]="20px",
        ["horizontal-align"]="left"
      }
    }
  )
end

function ChatCommand:CMD_getClearance (keys)
  local PlayerID = keys.playerid
  if keys.command[2] ~= nil then
    PlayerID = tonumber(keys.command[2])
  end
  local steamID64 = tostring(PlayerResource:GetSteamID(PlayerID))
  local accessLevel = ACCESSLEVELS[steamID64] or ACCESSLEVEL_NONE

  ChatCommand:Send(PlayerResource:GetPlayer(keys.playerid), steamID64 .. " has a cleareance of " .. tostring(accessLevel), true)
end

function ChatCommand:CMD_Help (keys)
  local player = PlayerResource:GetPlayer(keys.playerid)
  local counter
  for command,_ in pairs(self.commands) do
    ChatCommand:displayUsage(player, command)
  end
end

function ChatCommand:CMD_Settings (keys)
  local player = PlayerResource:GetPlayer(keys.playerid)
  local action = keys.command[2]
  local arg = keys.command[3]
  local arg2 = keys.command[4]

  if action == "get" and arg then
    ChatCommand:Send(player, arg .. "=" .. _G[arg])
  elseif action == "set" and arg then
    ChatCommand:Send(player, "Setting " .. arg .. " to " .. arg2)
    _G[arg] = arg2
  else
    ChatCommand:displayUsage(player, keys.command[1])
  end
end

function ChatCommand:CMD_Exec (keys)
  -- XXX
  -- XXX NOTE this is VERY dangerous
  -- XXX
  local player = PlayerResource:GetPlayer(keys.playerid)
  local funcName = keys.command[2]
  local obj = keys.command[3]
  local arg = nil
  for k,v in pairs(key.command) do
    if k > 3 then
      arg[k]=v
    end
  end

  if funcName == nil then
    ChatCommand:displayUsage(player, keys.command[1])
  end

  if obj == nil then
    _G[funcName](arg)
  else
    obj[funcName](obj, arg)
  end

end
