
local npcBot = nil

local RadiantBase = Vector(-5200,-150)		--perfected
local DireBase = Vector(5000,-50)			--perfected

local myBase = Vector(0,0)

local itemnumber = 0
local FirstAbility = 0
local SecondAbility = -1

local shieldcount = 0
local shieldslot = -1
local itemcount = 0
local hItem

local BotImplemented = {
"npc_dota_hero_axe",
"npc_dota_hero_bane",
"npc_dota_hero_bounty_hunter",
"npc_dota_hero_bloodseeker",
"npc_dota_hero_bristleback",
"npc_dota_hero_chaos_knight",
"npc_dota_hero_crystal_maiden",
"npc_dota_hero_dazzle",
"npc_dota_hero_death_prophet",
"npc_dota_hero_dragon_knight",
"npc_dota_hero_drow_ranger",
"npc_dota_hero_earthshaker",
"npc_dota_hero_jakiro",
"npc_dota_hero_juggernaut",
"npc_dota_hero_kunkka",
"npc_dota_hero_lich",
"npc_dota_hero_lina",
"npc_dota_hero_lion",
"npc_dota_hero_luna",
"npc_dota_hero_necrolyte",
"npc_dota_hero_omniknight",
"npc_dota_hero_oracle",
"npc_dota_hero_phantom_assassin",
"npc_dota_hero_pudge",
"npc_dota_hero_razor",
"npc_dota_hero_riki",
"npc_dota_hero_sand_king",
"npc_dota_hero_nevermore",
"npc_dota_hero_skywrath_mage",
"npc_dota_hero_sniper",
"npc_dota_hero_sven",
"npc_dota_hero_tidehunter",
"npc_dota_hero_tiny",
"npc_dota_hero_vengefulspirit",
"npc_dota_hero_viper",
"npc_dota_hero_warlock",
"npc_dota_hero_windrunner",
"npc_dota_hero_witch_doctor",
"npc_dota_hero_skeleton_king",
"npc_dota_hero_zuus"}

----------------------------------------------------------------------------
---	Default Functions
----------------------------------------------------------------------------




function  OnStart()
	npcBot=GetBot()
	if npcBot:GetTeam() == TEAM_RADIANT then
		myBase = RadiantBase
	else
		myBase = DireBase
	end

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

	--Basic Item Fix:
	if npcBot:FindItemSlot("item_upgrade_core") ~= -1 or npcBot:FindItemSlot("item_upgrade_core_2") ~= -1 or npcBot:FindItemSlot("item_upgrade_core_3") ~= -1 or npcBot:FindItemSlot("item_upgrade_core_4") ~= -1 or npcBot:FindItemSlot("item_farming_core") ~= -1 or npcBot:FindItemSlot("item_reflex_core") ~= -1 then
--		npcBot.IsRetreating = true
		return 7
	else
--		return 0
	end

	if GetUnitToLocationDistance( npcBot, myBase ) < 400 then
--		print("--> ",npcBot:GetUnitName(),"Within Distance")

--	end
--	print ("asdf",npcBot:FindItemSlot("item_stout_shield"))

		if npcBot:FindItemSlot("item_stout_shield") == -1 and npcBot:FindItemSlot("item_poor_mans_shield") == -1 and npcBot:FindItemSlot("item_vanguard") == -1 and npcBot:FindItemSlot("item_crimson_guard") == -1 and npcBot:FindItemSlot("item_abyssal_blade") == -1 and npcBot:GetGold() >= 200 and DotaTime() < 600 then --and npcBot:GetUnitName() ~= "npc_dota_hero_tidehunter"
			npcBot:ActionImmediate_PurchaseItem("item_stout_shield");
		end

		itemcount = 0
		shieldcount = 0
		for index =0,8,1 do
			hItem = npcBot:GetItemInSlot( index )
			if hItem ~= nil then
				if hItem:GetName() == "item_stout_shield" or hItem:GetName() == "item_poor_mans_shield" or hItem:GetName() == "item_vanguard" then
					shieldcount = shieldcount +1
					shieldslot = index
--					print("--> ",npcBot:GetUnitName(),"shield found.")
				end
			end
			if npcBot:GetItemInSlot( index ) ~= nil then
				itemcount = itemcount +1
--			else
--				print("--> ",npcBot:GetUnitName(),"nil item:")
			end
		end


		if shieldcount > 1 then
--			print("--> More than one shield: ",npcBot:GetUnitName(),shieldcount)
			local hItem = npcBot:GetItemInSlot( shieldslot )
			npcBot:ActionImmediate_SellItem( hItem )
--			print("--> ",npcBot:GetUnitName(),"ActionImmediate_SellItem duplicate shield:",hItem:GetName())
		end

--		itemnumber = npcBot:FindItemSlot("item_tpscroll")
--		if itemnumber ~= -1 then
--			local hItem = npcBot:GetItemInSlot( itemnumber )
--			npcBot:ActionImmediate_SellItem( hItem )
--			print("--> ",npcBot:GetUnitName(),"ActionImmediate_SellItem:",hItem:GetName())
--		end
--		itemnumber = npcBot:FindItemSlot("item_ward_observer")
--		if itemnumber ~= -1 then
--			local hItem = npcBot:GetItemInSlot( itemnumber )
--			npcBot:ActionImmediate_SellItem( hItem )
--			print("--> ",npcBot:GetUnitName(),"ActionImmediate_SellItem:",hItem:GetName())
--		end
		if itemcount > 8 then
			itemnumber = npcBot:FindItemSlot("item_tango_single")
			if itemnumber ~= -1 then
				local hItem = npcBot:GetItemInSlot( itemnumber )
				npcBot:ActionImmediate_SellItem( hItem )
				npcBot:Action_DropItem( hItem,npcBot:GetLocation() )
--				print("--> ",npcBot:GetUnitName(),"Action_DropItem:",hItem:GetName())
				return 0.0
			end
			itemnumber = npcBot:FindItemSlot("item_clarity")
			if itemnumber ~= -1 then
				local hItem = npcBot:GetItemInSlot( itemnumber )
				npcBot:ActionImmediate_SellItem( hItem )
				npcBot:Action_DropItem( hItem,npcBot:GetLocation() )
--				print("--> ",npcBot:GetUnitName(),"Action_DropItem:",hItem:GetName())
				return 0.0
			end
			itemnumber = npcBot:FindItemSlot("item_enchanted_mango")
			if itemnumber ~= -1 then
				local hItem = npcBot:GetItemInSlot( itemnumber )
				npcBot:ActionImmediate_SellItem( hItem )
				npcBot:Action_DropItem( hItem,npcBot:GetLocation() )
--				print("--> ",npcBot:GetUnitName(),"Action_DropItem:",hItem:GetName())
				return 0.0
			end
			itemnumber = npcBot:FindItemSlot("item_tango")
			if itemnumber ~= -1 then
				local hItem = npcBot:GetItemInSlot( itemnumber )
				npcBot:ActionImmediate_SellItem( hItem )
--				print("--> ",npcBot:GetUnitName(),"ActionImmediate_SellItem:",hItem:GetName())
				return 0.0
			end
			itemnumber = npcBot:FindItemSlot("item_quelling_blade")
			if itemnumber ~= -1 then
				local hItem = npcBot:GetItemInSlot( itemnumber )
				npcBot:ActionImmediate_SellItem( hItem )
--				print("--> ",npcBot:GetUnitName(),"ActionImmediate_SellItem:",hItem:GetName())
				return 0.0
			end
			itemnumber = npcBot:FindItemSlot("item_magic_wand")
			if itemnumber ~= -1 then
				local hItem = npcBot:GetItemInSlot( itemnumber )
				npcBot:ActionImmediate_SellItem( hItem )
--				print("--> ",npcBot:GetUnitName(),"ActionImmediate_SellItem:",hItem:GetName())
				return 0.0
			end
			itemnumber = npcBot:FindItemSlot("item_stout_shield")
			if itemnumber ~= -1 then
				local hItem = npcBot:GetItemInSlot( itemnumber )
				npcBot:ActionImmediate_SellItem( hItem )
--				print("--> ",npcBot:GetUnitName(),"ActionImmediate_SellItem:",hItem:GetName())
				return 0.0
			end
			itemnumber = npcBot:FindItemSlot("item_bottle")
			if itemnumber ~= -1 then
				local hItem = npcBot:GetItemInSlot( itemnumber )
				npcBot:ActionImmediate_SellItem( hItem )
--				print("--> ",npcBot:GetUnitName(),"ActionImmediate_SellItem:",hItem:GetName())
				return 0.0
			end
--			itemnumber = npcBot:FindItemSlot("item_infinite_bottle")
--			if itemnumber ~= -1 then
--				local hItem = npcBot:GetItemInSlot( itemnumber )
--				npcBot:ActionImmediate_SellItem( hItem )
--				npcBot:Action_DropItem( hItem,npcBot:GetLocation() )
--				print("--> ",npcBot:GetUnitName(),"Action_DropItem:",hItem:GetName())
--				return 0.0
--			end

--			itemnumber = npcBot:FindItemSlot("item_magic_stick")
--			if itemnumber ~= -1 then
--				local hItem = npcBot:GetItemInSlot( itemnumber )
--				npcBot:ActionImmediate_SellItem( hItem )
--				print("--> ",npcBot:GetUnitName(),"ActionImmediate_SellItem:",hItem:GetName())
--				return
--			end
		end
	end

	return 0.0
end

function Think()
	local npcBot=GetBot()

	if GetUnitToLocationDistance( npcBot, myBase ) < 200 then
		itemnumber = npcBot:FindItemSlot("item_farming_core")
		if itemnumber ~= -1 then
			local hItem = npcBot:GetItemInSlot( itemnumber )
			npcBot:ActionImmediate_SellItem( hItem )
--			print("--> ",npcBot:GetUnitName(),"ActionImmediate_SellItem:",hItem:GetName())
			return
		end
		itemnumber = npcBot:FindItemSlot("item_reflex_core")
		if itemnumber ~= -1 then
			local hItem = npcBot:GetItemInSlot( itemnumber )
			npcBot:ActionImmediate_SellItem( hItem )
--			print("--> ",npcBot:GetUnitName(),"ActionImmediate_SellItem:",hItem:GetName())
			return
		end
		itemnumber = npcBot:FindItemSlot("item_upgrade_core")
		if itemnumber ~= -1 then
			local hItem = npcBot:GetItemInSlot( itemnumber )
			npcBot:ActionImmediate_SellItem( hItem )
--			print("--> ",npcBot:GetUnitName(),"ActionImmediate_SellItem:",hItem:GetName())
			return
		end
		itemnumber = npcBot:FindItemSlot("item_upgrade_core_2")
		if itemnumber ~= -1 then
			local hItem = npcBot:GetItemInSlot( itemnumber )
			npcBot:ActionImmediate_SellItem( hItem )
--			print("--> ",npcBot:GetUnitName(),"ActionImmediate_SellItem:",hItem:GetName())
			return
		end
		itemnumber = npcBot:FindItemSlot("item_upgrade_core_3")
		if itemnumber ~= -1 then
			local hItem = npcBot:GetItemInSlot( itemnumber )
			npcBot:ActionImmediate_SellItem( hItem )
--			print("--> ",npcBot:GetUnitName(),"ActionImmediate_SellItem:",hItem:GetName())
			return
		end
		itemnumber = npcBot:FindItemSlot("item_upgrade_core_4")
		if itemnumber ~= -1 then
			local hItem = npcBot:GetItemInSlot( itemnumber )
			npcBot:ActionImmediate_SellItem( hItem )
--			print("--> ",npcBot:GetUnitName(),"ActionImmediate_SellItem:",hItem:GetName())
			return
		end
	end

	if GetUnitToLocationDistance( npcBot, myBase ) < 400 then
		npcBot:Action_AttackMove( myBase )
--		print ("--> ",npcBot:GetUnitName()," Action_AttackMove")
	else
		npcBot:Action_MoveToLocation( myBase )
--		print ("--> ",npcBot:GetUnitName()," Action_MoveToLocation")
	end
	return
end
