-------
--_G._savedEnv = getfenv()
--module( "mode_generic_retreat", package.seeall )
----------

--Loc = require(GetScriptDirectory().."/Utility")

local freakoutpercentage=0.225
local freakoutvalue=190


local DuelLocation2 = Vector(-5150,4650) 	--Radiant Side
local DuelLocation1 = Vector(4850,-4350) 	--Dire Side
local DuelMidLocation1 = Vector(6300,-6100)
local DuelMidLocation2 = Vector(-6400,6200)

local DuelLocation = Vector(0,0)
local DuelMidLocation = Vector(0,0)


local RadiantBase = Vector(-5200,-150)		--perfected
local DireBase = Vector(5000,-50)			--perfected
local myBase = Vector(0,0)

local currentduel = false
local herofighttime = -100

local maxsearchradius = 1600 --Must not be greater than 1600 or error
local creepsearchradius = 1200 --Must not be greater than 1600 or error, 1200 is a lot, but not unmanageable
local attackmovetime = -100

local ClosestHero = nil
local EnemyHeroes = {}

local AISwitchOffDistance = 1400 -- must not be greater than 1600
local bottleUseTime = -100



----------------------------------------------------------------------------
---	My Functions
----------------------------------------------------------------------------




local function GetClosestHero( searchradius,bEnemies )
	local npcBot=GetBot()

	EnemyHeroes = npcBot:GetNearbyHeroes( searchradius,bEnemies,BOT_MODE_NONE )
	local LowestDistance = 10000
	ClosestHero = nil

--	print (npcBot:GetUnitName(),EnemyHeroes)
	if #EnemyHeroes~=0 then
--		print (npcBot:GetUnitName()," EnemyHeroes~=0 and movingtoheroes == false")
		for _,hero in pairs(EnemyHeroes) do
			if hero~=nil and hero:IsAlive() then
				if GetUnitToUnitDistance( hero, npcBot )<LowestDistance then
					ClosestHero=hero
				end
			end
		end
	end
end




local function DuelStuff()
	local npcBot=GetBot()
	
	if npcBot.IsDuelRetreating == true then
--		if npcBot:GetHealth()/npcBot:GetMaxHealth()>0.10 then
--			npcBot.IsDuelRetreating = false
--			print ("--> ",npcBot:GetUnitName()," decided not to Duel Retreat")
--		else

		if npcBot:GetTeam() == TEAM_RADIANT then
			myBase = RadiantBase
		else
			myBase = DireBase
		end
		if GetUnitToLocationDistance( npcBot, myBase ) < 400 then
			npcBot:Action_AttackMove( myBase )
--			print ("--> ",npcBot:GetUnitName()," Action_AttackMove")
		else
			npcBot:Action_MoveToLocation( myBase )
--			print ("--> ",npcBot:GetUnitName()," Action_MoveToLocation")
		end
--		print ("--> ",npcBot:GetUnitName()," is Duel Retreating")
		return
	end
	
	GetClosestHero( maxsearchradius,true )
	if ClosestHero ~= nil then 
		local AttackRange = AISwitchOffDistance
		if AttackRange < npcBot:GetAttackRange()+100 then
			AttackRange = npcBot:GetAttackRange()+100
		end
--		print(npcBot:GetUnitName(),"Here")
--		print(npcBot:GetUnitName(),"GetUnitToUnitDistance( hero, npcBot )", GetUnitToUnitDistance( hero, npcBot ), "npcBot:GetAttackRange()+100",npcBot:GetAttackRange()+100)
		
		if GetUnitToUnitDistance( ClosestHero, npcBot ) > AttackRange then
--			if attackmovetime < DotaTime() then
--				attackmovetime = DotaTime()+3
				local halfWayLocation = ClosestHero:GetLocation() + npcBot:GetLocation() + npcBot:GetLocation()
				halfWayLocation = halfWayLocation/3
--				npcBot:Action_ClearActions( true )
				npcBot:Action_AttackMove( halfWayLocation )
--				print(npcBot:GetUnitName(),"Moving towards enemies. No retreat due to attack range: < ClosestHero ",GetUnitToUnitDistance( ClosestHero, npcBot ))
				return
--			end
		else
			if npcBot:GetCurrentActionType() == BOT_ACTION_TYPE_IDLE or npcBot:GetCurrentActionType() == BOT_ACTION_TYPE_NONE then
				local halfWayLocation = ClosestHero:GetLocation() + npcBot:GetLocation() + npcBot:GetLocation()
				halfWayLocation = halfWayLocation/3
--				npcBot:Action_ClearActions( true )
				npcBot:Action_AttackMove( halfWayLocation )
--				print(npcBot:GetUnitName(),"Idle. No Retreat")
				return
			end
		end
	else
		if attackmovetime < DotaTime() then
			attackmovetime = DotaTime()
			local halfWayLocation = DuelMidLocation + DuelMidLocation + npcBot:GetLocation()
			halfWayLocation = halfWayLocation/3
			npcBot:Action_AttackMove( DuelMidLocation )
			return
		end
	end
end




----------------------------------------------------------------------------
---	Default Functions
----------------------------------------------------------------------------




function  OnStart()
end




function OnEnd()
end




function GetDesire()
	local npcBot=GetBot()
	
	--Stop TP
	if npcBot:HasModifier("modifier_teleporting") then
		npcBot:Action_ClearActions( true )
--		print("---> ",npcBot:GetUnitName()," Attempted teleport intercepted.")
	end

	local npcBotLocation = npcBot:GetLocation()
	GetClosestHero( AISwitchOffDistance,true )

	if npcBotLocation.x > DuelLocation1.x and npcBotLocation.y < DuelLocation1.y then
		DuelMidLocation = DuelMidLocation1
		currentduel = true
	elseif npcBotLocation.x < DuelLocation2.x and npcBotLocation.y > DuelLocation2.y then
		DuelMidLocation = DuelMidLocation2
		currentduel = true
	else
		currentduel = false
	end

	if currentduel == true then
--		print("--> Duel Location #1b",DuelLocation1,npcBot:GetUnitName(),npcBotLocation)
		if npcBot:GetHealth()/npcBot:GetMaxHealth() < 0.04 then
			npcBot.IsDuelRetreating = true
			return 0.9 -- high
		elseif npcBot:GetHealth()/npcBot:GetMaxHealth() > 0.08 then
			npcBot.IsDuelRetreating = false
			return 0.9
--			return 0.6 -- not too high, so that default fight AI can take over and choose targets
		end
		if ClosestHero ~= nil then
			if GetUnitToUnitDistance( ClosestHero, npcBot ) < AISwitchOffDistance then
				return 0.65 -- not too high, so that default fight AI can take over and choose targets
			end
		else
			return 0.9
		end
	end

	if npcBot.IsRetreating == true then
--		print ("---------------------> ",npcBot:GetUnitName()," is retreating")
		if npcBot:GetHealth()/npcBot:GetMaxHealth()>0.72 and npcBot:GetMana()/npcBot:GetMaxMana()>0.72 then
			npcBot.IsRetreating = false
--			print("---------------------> ",npcBot:GetUnitName()," is not Retreating any more")
			return 0.0
		end
	end
	if npcBot.IsRetreating== true then
		return 1.0
--		retreattime = DotaTime()+6
	end
	if npcBot:GetHealth()/npcBot:GetMaxHealth()<freakoutpercentage or npcBot:GetHealth()<freakoutvalue then
--		if npcBot.IsRetreating ~= true and npcBot:WasRecentlyDamagedByCreep( 0.5 ) then
		npcBot.Ping = npcBot:GetLocation()
--			print("---> PING! ",npcBot:GetUnitName(),npcBot.Ping)

--			Ping ruins everything
--			npcBot:ActionImmediate_Ping( npcBot.Ping.x, npcBot.Ping.y, false )
--		end
		npcBot.Target = nil
		npcBot.IsRetreating = true
		npcBot.SwitchCamp = true
		return 1.0
--		retreattime = DotaTime()+6
	end
	return 0.0
end




function Think()
	local npcBot=GetBot()

	if npcBot:IsAlive() ~= true or npcBot:GetHealth() == 0 then
		return
	end
	
	if npcBot:HasModifier("modifier_teleporting") then
		npcBot:Action_ClearActions( true )
--		print("---------------------> ",npcBot:GetUnitName()," Attempted teleport intercepted.")
	end
	
	-- Use bottle:
	if DotaTime() > bottleUseTime then
		
		local itemNumber = npcBot:FindItemSlot("item_infinite_bottle")
		if itemNumber ~= -1 then
			if npcBot:GetMaxHealth()-npcBot:GetHealth() >= 100 or npcBot:GetMana()/npcBot:GetMaxMana() < 0.25 then
				local hItem = npcBot:GetItemInSlot( itemNumber )
				if hItem:IsFullyCastable() and hItem:GetCurrentCharges() > 1 then
--					print("->  ",npcBot:GetUnitName()," used: ",hItem:GetName())
					npcBot:Action_UseAbility( hItem )
					bottleUseTime = DotaTime() + 22.55
					return
				end
--				npcBot:Action_UseAbilityOnEntity( hItem, npcBot )
			end
		end
	end
	
	if currentduel == true then
		DuelStuff()
		return
	end

--	print ("--> ",npcBot:GetUnitName()," is retreating")
--		if DotaTime() > stopmessage then
--			print("---------------------> ",npcBot:GetUnitName()," is running for their life.")
--			stopmessage=DotaTime()+7
--		end
	if npcBot:GetTeam() == TEAM_RADIANT then
		myBase = RadiantBase
	else
		myBase = DireBase
	end
	if npcBot.IsRetreating == true then
		if GetUnitToLocationDistance( npcBot, myBase ) < 400 then
			npcBot:Action_AttackMove( myBase )
--			print ("--> ",npcBot:GetUnitName()," Action_AttackMove")
		else
			npcBot:Action_MoveToLocation( myBase )
--			print ("--> ",npcBot:GetUnitName()," Action_MoveToLocation")
		end
	end
end




--------
--for k,v in pairs( mode_generic_retreat ) do	_G._savedEnv[k] = v end
