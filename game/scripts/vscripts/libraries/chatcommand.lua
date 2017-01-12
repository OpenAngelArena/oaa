--[[
===== ChatCommand =====
Makes it easier to create commands from anywhere in your code.
Does not break when using script_reload

Usage:
	-Create some instance of ChatCommand with : cls = ChatCommand()
	-Create a function cls:MyFunction(keys) 			OR 		function SomeClass:SomeFunction(keys)
		keys are those delivered from the 'player_chat' event
	-Use cls:LinkCommand("-MyTrigger", "MyFunction") 	OR 		cls:LinkCommand("-MyTrigger", "SomeFunction", SomeClass) 
		Use this to call this function everytime someone's chat starts with -MyTrigger

created by Zarnotox
]] 

ChatCommand = ChatCommand or class({})

function ChatCommand:constructor() 
	ListenToGameEvent("player_chat", Dynamic_Wrap(ChatCommand, 'OnPlayerChat'), self)
end

function ChatCommand:LinkCommand(command, funcName, obj)
	print("CREATING LINK")
	print(command)
	print(funcName)
	print(obj)
	self.commands = self.commands or {}
	self.commands[command] = {funcName, obj}
end

function ChatCommand:OnPlayerChat(keys)
	self.commands = self.commands or {}

	local teamonly = 1
  	local userID = 1
  	local text = keys.text

	local splitted = split(text, " ")

	if self.commands[splitted[1]] ~= nil then
		local loacation = self.commands[splitted[1]]
		funcName = loacation[1]
		obj = loacation[2] or self

		obj[funcName](obj, keys)
	end
end