--[[
===== ChatCommand =====
Makes it easier to create commands from anywhere in your code.
Does not break when using script_reload

Usage:
	-Create some instance of ChatCommand with : cls = ChatCommand()
	-Create a function cls:MyFunction(keys) somewhere in your code
		keys are those delivered from the 'player_chat' event
	-Use cls:LinkCommand("-MyTrigger", "MyFunction")
		Use this to call this function everytime someone's chat starts with -MyTrigger

created by Zarnotox
]] 

ChatCommand = ChatCommand or class({})

function ChatCommand:constructor() 
	ListenToGameEvent("player_chat", Dynamic_Wrap(ChatCommand, 'OnPlayerChat'), self)
end

function ChatCommand:LinkCommand(command, funcName)
	self.commands = self.commands or {}
	self.commands[command] = funcName
end

function ChatCommand:OnPlayerChat(keys)
	self.commands = self.commands or {}

	local teamonly = 1
  	local userID = 1
  	local text = keys.text

	local splitted = split(text, " ")

	if self.commands[splitted[1]] ~= nil then
		local funcName = self.commands[splitted[1]]
		self[funcName](self, keys)
	end
end

function ChatCommand:GoldCommand(keys)
    local id = keys.userid
    local text = keys.text

    local splitted = split(text, " ")
    local gold = tonumber(splitted[2])

    print("Trying to give player'".. id .. "' " .. gold .. " custom gold")
    print("Right now you have " .. Gold:GetGold(id) .. " custom gold")
    Gold:ModifyGold(id, gold)
    print("And now you have " .. Gold:GetGold(id) .. " custom gold")
  end