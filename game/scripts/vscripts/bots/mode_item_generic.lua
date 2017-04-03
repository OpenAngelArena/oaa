
local DireBase = Vector(5000,-300)
local RadiantBase = Vector(-5000,-300)

local myBase = Vector(0,0)

local itemnumber = 0



function  OnStart()
end

function OnEnd()
end

function GetDesire()
	local npcBot=GetBot()
	if npcBot:GetTeam() == TEAM_RADIANT then
		myBase = RadiantBase
	else
		myBase = DireBase
	end
--	if GetUnitToLocationDistance( npcBot, myBase ) < 400 then
--		print("--> ",npcBot:GetUnitName(),"Within Distance")
--		itemnumber = npcBot:FindItemSlot("item_tpscroll")
--		if itemnumber >= 0 then
--			local hItem = npcBot:GetItemInSlot( itemnumber ) 
--			npcBot:ActionImmediate_SellItem( hItem )
--			print("--> ",npcBot:GetUnitName(),"ActionImmediate_SellItem:",hItem:GetName())
--		end
--		itemnumber = npcBot:FindItemSlot("item_ward_observer")
--		if itemnumber >= 0 then
--			local hItem = npcBot:GetItemInSlot( itemnumber ) 
--			npcBot:ActionImmediate_SellItem( hItem )
--			print("--> ",npcBot:GetUnitName(),"ActionImmediate_SellItem:",hItem:GetName())
--		end
--	end
--	print ("asdf",npcBot:FindItemSlot("item_stout_shield"))
	if npcBot:FindItemSlot("item_stout_shield") == -1 and npcBot:GetGold() >= 200 then
		npcBot:ActionImmediate_PurchaseItem("item_stout_shield");
	end
	return 0.0
end

