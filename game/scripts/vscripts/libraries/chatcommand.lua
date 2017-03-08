--[[
===== ChatCommand =====
Makes it easier to create commands from anywhere in your code.
Does not break when using script_reload
Usage:
	-Create a function MyFunction(keys) 						OR 		function SomeClass:SomeFunction(keys)
		keys are those delivered from the 'player_chat' event
	-Use ChatCommand:LinkCommand("-MyTrigger", "MyFunction") 	OR 		ChatCommand:LinkCommand("-MyTrigger", "SomeFunction", SomeClass) 
		Use this to call this function everytime someone's chat starts with -MyTrigger
created by Zarnotox with a lot of constructive help from the mod data guys https://discord.gg/Z7eCcGT (THIS IS NOT THE AAA DISCORD, THIS IS THE MODDATA DISCORD. YOU DID NOT FIND THE SECRET. check it out!)
]] 

ChatCommand = ChatCommand or {}

-- Begin Initialise
function ChatCommand:Init() 
	self.initialised = true
	ListenToGameEvent("player_chat", Dynamic_Wrap(ChatCommand, 'OnPlayerChat'), self)
end

if not ChatCommand.initialised then
    ChatCommand:Init()
end
-- End Initialise

-- Function to create the link
function ChatCommand:LinkCommand(command, funcName, obj)
	self.commands = self.commands or {}
	self.commands[command] = {funcName, obj}
end

-- Function that's called when somebody chats
function ChatCommand:OnPlayerChat(keys)
	self.commands = self.commands or {}
	local text = keys.text

	local splitted = split(text, " ")

	if self.commands[splitted[1]] ~= nil then
		local location = self.commands[splitted[1]]
		funcName = location[1]

		if location[2] == nil then
			_G[funcName](keys)
		else
			local obj = location[2]
			obj[funcName](obj, keys)
		end
	end
end
