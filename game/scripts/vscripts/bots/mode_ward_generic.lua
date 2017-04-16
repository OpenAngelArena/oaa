

local RadiantWardLocation = Vector(-2550,50)
local DireWardLocation = Vector(2300,-250)

function  OnStart()
end

function OnEnd()
end

function GetDesire()
	local npcBot=GetBot()
	
	local itemnumber = npcBot:FindItemSlot("item_ward_observer")
	if itemnumber >= 0 and itemnumber <= 5 then
		return 0.7
	else
		return 0.0;
	end
end

function Think()
	local npcBot=GetBot()
	
--	if npcBot:GetTeam() == TEAM_RADIANT then	
--		npcBot:Action_MoveToLocation( RadiantBase )
--		npcBot:Action_AttackMove ( RadiantBase )
--		return
--	else
--		npcBot:Action_MoveToLocation( DireBase )
--		npcBot:Action_AttackMove ( DireBase )
--		return
--	end

	local itemnumber = npcBot:FindItemSlot("item_ward_observer")
	if itemnumber >= 0 and itemnumber <= 5 then
		local hItem = npcBot:GetItemInSlot( itemnumber )
--		print("->  ",npcBot:GetUnitName()," using: ",hItem:GetName())
		local WardLocation
		if npcBot:GetTeam() == TEAM_RADIANT then
			WardLocation = RadiantWardLocation
		else
			WardLocation = DireWardLocation
		end
		npcBot:Action_UseAbilityOnLocation( hItem,WardLocation )
		return
	end
	return
end



