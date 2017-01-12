
-- Global function
ChatCommand:LinkCommand("-test", "TestCommand")
function TestCommand(keys)
	print("this test command works")
end


-- Object:function
GoldClass = GoldClass or class({})

ChatCommand:LinkCommand("-gold", 'GoldCommand', GoldClass)
function GoldClass:GoldCommand(keys)
	self.gold = self.gold or 0

	local splitted = split(keys.text, " ")
	local money = tonumber(splitted[2])

	print("you had " .. self.gold .." gold before")
	self.gold = self.gold + money
	print("But now you have " .. self.gold .." gold!")
end
