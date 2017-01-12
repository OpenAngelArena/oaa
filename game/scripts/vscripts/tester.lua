
tester = tester or ChatCommand()

tester:LinkCommand("-gold", 'GoldCommand')
function tester:GoldCommand(keys)
	local id = keys.userid
	local text = keys.text

	local splitted = split(text, " ")
	local gold = tonumber(splitted[2])

	print("Trying to give player'".. id .. "' " .. gold .. " custom gold")
	print("Right now you have " .. Gold:GetGold(id) .. " custom gold")
	Gold:ModifyGold(id, gold)
	print("And now you have " .. Gold:GetGold(id) .. " custom gold")
end


TestClass = TestClass or class({})

tester:LinkCommand("-test", "TestCommand", TestClass)
function TestClass:TestCommand(keys)
	print("testcommand works")
end