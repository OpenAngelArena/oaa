--- AUTHOR: RamonNZ 
--- This is mostly built from the ground up. In fact it's kind of a clusterfuck of code. 
--- I wrote the whole thing in one file rather that switching between different files and desire. Yes I eventually will do that.
--- Credits: PLATINUM_DOTA2 (Pooya J.) I took a bit of his code here and there, but not much.  However I learned a lot from looking at what he did.
---	Thanks darklord for helping stop the bots tping.

----------

--    BOT_ACTION_TYPE_NONE
--    BOT_ACTION_TYPE_IDLE
--    BOT_ACTION_TYPE_MOVE_TO
--    BOT_ACTION_TYPE_ATTACK
--    BOT_ACTION_TYPE_ATTACKMOVE
--    BOT_ACTION_TYPE_USE_ABILITY
--    BOT_ACTION_TYPE_PICK_UP_RUNE
--    BOT_ACTION_TYPE_PICK_UP_ITEM
--    BOT_ACTION_TYPE_DROP_ITEM
--    BOT_ACTION_TYPE_SHRINE
--    BOT_ACTION_TYPE_DELAY


local DOTA_ABILITY_BEHAVIOR_HIDDEN = 1			-- : This ability can be owned by a unit but can't be casted and wont show up on the HUD.
local DOTA_ABILITY_BEHAVIOR_PASSIVE = 2 		--: Can't be casted like above but this one shows up on the ability HUD
local DOTA_ABILITY_BEHAVIOR_NO_TARGET = 4 		--: Doesn't need a target to be cast, ability fires off as soon as the button is pressed
local DOTA_ABILITY_BEHAVIOR_UNIT_TARGET = 8 	--: Ability needs a target to be casted on.
local DOTA_ABILITY_BEHAVIOR_POINT = 16 			--: Ability can be cast anywhere the mouse cursor is (If a unit is clicked it will just be cast where the unit was standing)
local DOTA_ABILITY_BEHAVIOR_AOE = 32 			--: This ability draws a radius where the ability will have effect. Kinda like POINT but with a an area of effect display.
local DOTA_ABILITY_BEHAVIOR_NOT_LEARNABLE = 64 	--: This ability probably can be casted or have a casting scheme but cannot be learned (these are usually abilities that are temporary like techie's bomb detonate)
local DOTA_ABILITY_BEHAVIOR_CHANNELLED = 128 	--: This abillity is channelled. If the user moves or is silenced the ability is interrupted.
local DOTA_ABILITY_BEHAVIOR_ITEM = 256 			--: This ability is tied up to an item.
local DOTA_ABILITY_BEHAVIOR_TOGGLE = 512 		--: This ability can be insta-toggled
local DOTA_ABILITY_BEHAVIOR_DIRECTIONAL = 1024 	--: This ability has a direction from the hero		
local DOTA_ABILITY_BEHAVIOR_IMMEDIATE = 2048 	--	: This ability does not interrupt other abilities

---DOTA_UNIT_TARGET_TEAM_NONE 	0 	
--DOTA_UNIT_TARGET_TEAM_FRIENDLY 	1 	Targets all those that are in the same team as the team that was declared the source.
--DOTA_UNIT_TARGET_TEAM_ENEMY 	2 	Targets all those that are not in the same team as the team that was declared the source.
--DOTA_UNIT_TARGET_TEAM_BOTH 	3 	Targets all entities from every team.
--DOTA_UNIT_TARGET_TEAM_CUSTOM 	4 	

local AttackRangeAdded = 75 -- be careful messing with this


local WeakestCreep = nil
local StrongestCreep = nil
local ClosestCreep = nil
local ClosestHero = nil

--Vectors
local DuelLocation2 = Vector(-5150,4650) 	--Radiant Side
local DuelLocation1 = Vector(4850,-4350) 	--Dire Side

local RadiantBase = Vector(-5200,-150)		--perfected
local DireBase = Vector(5000,-50)			--perfected

local RadiantTopEasy = Vector(-3700,1250)	--perfected
local RadiantMidEasy = Vector(-1100,-150)	--perfected
local RadiantMidHalfWay = Vector(-2000,-800)--perfected
local RadiantBotEasy = Vector(-3700,-1450)	--perfected

local RadiantTopMedium = Vector(-2050,2050)	--perfected
local RadiantMidMedium = Vector(-2000,200)	--perfected
local RadiantBotMedium = Vector(-2050,-2150)--perfected

local DireTopEasy = Vector(3450,1300)		--perfected
local DireMidEasy = Vector(900,150)			--perfected
local DireMidHalfWay = Vector(2550,850)		--perfected
local DireBotEasy = Vector(3450,-1500)		--perfected

local DireTopMedium = Vector(1550,2150)		--perfected
local DireMidMedium = Vector(1800,-450)		--perfected
local DireBotMedium = Vector(1550,-2500)	--perfected

local AncientsTop = Vector(-100,2600)		--perfected
local AncientsBot = Vector(-150,-3000)		--perfected

local EmptyLocation = Vector(0,0)

local CurrentCamp = Vector(0,0)
local PreviousCamp =  Vector(0,0)
local NextCamp = Vector(0,0)
local NextNextCamp = Vector(0,0)
local OldLocation = Vector(0,0)
local myBase = Vector(0,0)


--local runningtocreeps = false
local bOnce = false

local camp = 2

local currentAbility = 0
local currentAbilityAttempt = 0

local stopmessage = -100
local stopmessage2 = -100
local stopmessage3 = -100
local stopmessage4 = -100
local stopmessage5 = -100
local stopmessage6 = -100
local stopmessage7 = -100
local stopmessage8 = -100
local stopmessage9 = -100
local stopmessage10 = -100
local stopmessage11 = -100
local stopmessage12 = -100
local stopmessage13 = -100
local stopmessage14 = -100
local stopmessage15 = -100

local newLocationTimer = -100
local quickRunBackTimer = -100
local runTimer = -100
local abilityWaitTimer = -100
local abilityWaitAdd = 0.00
local bottleUseTime = -100
local bottleCheckTime = -100
local shrapnelTimer =  -100

local EnemyHeroes = {}
local EnemyCreeps = {}
local NeutralCreeps = {}
local CurrentCreeps = {}
local ItemList = {}
local teamtable = {};

local currentduel = false
local bAttackMove = false
local bMoveToLocation = false

--Ping Stuff
local PingUnit1 = ""
local PingUnit2 = ""
local PingUnit3 = ""
local PingUnit4 = ""
local PingUnit5 = ""
local PingLocation1 = Vector(0,0)
local PingLocation2 = Vector(0,0)
local PingLocation3 = Vector(0,0)
local PingLocation4 = Vector(0,0)
local PingLocation5 = Vector(0,0)
local PingLocationArrived1 = Vector(0,0)
local PingLocationArrived2 = Vector(0,0)
local PingLocationArrived3 = Vector(0,0)
local PingLocationArrived4 = Vector(0,0)
local PingLocationArrived5 = Vector(0,0)

--Pickup Item Stuff:
local itemcount = 0
local arrayItem = nil
--local arrayPlayer = nil
local arrayLocation = Vector(0,0)
local closestBottleLocation = Vector(0,0)
local closestBottle = nil
local badBottle = nil
local badBottle2 = nil
local currentBottle = nil

--local closestMangoLocation = Vector(0,0)
--local closestMango = nil
--local closestTangoLocation = Vector(0,0)
--local closestTango = nil
--local closestClarityLocation = Vector(0,0)
--local closestClarity = nil


----	Important Hero vs Hero/Creep Variables:

local maxsearchradius = 1600 --Must not be greater than 1600 or error
local creepsearchradius = 650  -- Must not be greater than 1600 or error
--local AISwitchOffDistance = 1400 -- must not be greater than 1600





----------------------------------------------------------------------------
---	My Functions
----------------------------------------------------------------------------




local function GetClosestHero( searchradius,bEnemies )
	local npcBot=GetBot()
	EnemyHeroes = {}
	EnemyHeroes = npcBot:GetNearbyHeroes( searchradius,bEnemies,BOT_MODE_NONE )
	local LowestDistance = 10000
	ClosestHero = nil


	if #EnemyHeroes~=0 then
		for _,hero in pairs(EnemyHeroes) do
			if hero~=nil and hero:IsAlive() then
				if GetUnitToUnitDistance( hero, npcBot )<LowestDistance then
					ClosestHero=hero
				end
			end
		end
	end
end




local function SwitchCamp()
	local npcBot=GetBot()

	local randomx=camp
	local lowernumber = 0
	local uppernumber = 5
	if npcBot:GetLevel() <= 5 then
		lowernumber = 0
		uppernumber = 5
	elseif npcBot:GetLevel() <= 11 then
		lowernumber = 0
		uppernumber = 6
	elseif npcBot:GetLevel() <= 14 then
		lowernumber = 0
		uppernumber = 8
	elseif npcBot:GetLevel() <= 17 then
		lowernumber = 0
		uppernumber = 9

	else
		lowernumber = 4
		uppernumber = 11
	end
	while camp == randomx do
		randomx= RandomInt( lowernumber, uppernumber )
	end
	if randomx == 0 then
		randomx = uppernumber
	end

	camp = randomx
	PreviousCamp = CurrentCamp
	if npcBot:GetTeam() == TEAM_RADIANT then
		if camp == 1 then
			CurrentCamp = RadiantBotEasy
		elseif camp == 2 then
			CurrentCamp = RadiantTopEasy
		elseif camp == 3 then
			if PreviousCamp == RadiantMidMedium then
				CurrentCamp = RadiantMidHalfWay
				NextCamp = RadiantMidEasy
			else
				CurrentCamp = RadiantMidEasy
			end
		elseif camp == 4 then
			if PreviousCamp == RadiantMidEasy then
				CurrentCamp = RadiantMidHalfWay
				NextCamp = RadiantMidMedium
			else
				CurrentCamp = RadiantMidMedium
			end
		elseif camp == 5 then
			CurrentCamp = RadiantBotMedium
		elseif camp == 6 then
			CurrentCamp = RadiantTopMedium
		elseif camp == 7 then
			CurrentCamp = DireTopMedium
		elseif camp == 8 then
			CurrentCamp = DireBotMedium
		elseif camp == 9 then
			CurrentCamp = DireMidMedium
		elseif camp == 10 then
			CurrentCamp = AncientsBot
		elseif camp == 11 then
			CurrentCamp = AncientsTop
		end
	else
		if camp == 1 then
			CurrentCamp = DireBotEasy
		elseif camp == 2 then
			CurrentCamp = DireTopEasy
		elseif camp == 3 then
			if PreviousCamp == DireMidMedium then
				CurrentCamp = DireMidHalfWay
				NextCamp = DireMidEasy
			else
				CurrentCamp = DireMidEasy
			end
		elseif camp == 4 then
			if PreviousCamp == DireMidEasy then
				CurrentCamp = DireMidHalfWay
				NextCamp = DireMidMedium
			else
				CurrentCamp = DireMidMedium
			end
		elseif camp == 5 then
			CurrentCamp = DireTopMedium
		elseif camp == 6 then
			CurrentCamp = DireBotMedium
		elseif camp == 7 then
			CurrentCamp = RadiantBotMedium
		elseif camp == 8 then
			CurrentCamp = RadiantTopMedium
		elseif camp == 9 then
			CurrentCamp = RadiantMidMedium
		elseif camp == 10 then
			CurrentCamp = AncientsTop
		elseif camp == 11 then
			CurrentCamp = AncientsBot
		end
	end
end




local function AttackMoveHeroes (nRadius)
	local npcBot=GetBot()
	

----AttackMove to Heroes:
	if GetUnitToUnitDistance( ClosestHero, npcBot ) > npcBot:GetAttackRange()+AttackRangeAdded then
		local halfWayLocation = ClosestHero:GetLocation() + npcBot:GetLocation() + npcBot:GetLocation()
		halfWayLocation = halfWayLocation/3
--		npcBot:Action_ClearActions( true )
		npcBot:Action_AttackMove( halfWayLocation )
		if DotaTime() > stopmessage2 then
			--print("-->  AttackMoveHeroes:",npcBot:GetUnitName())
			stopmessage2=DotaTime()+10
		end
		
--		print("--> AttackMoveHeroes: ",npcBot:GetUnitName(),"ClosestHero: ",ClosestHero:GetUnitName(),"Distance:",GetUnitToUnitDistance( ClosestHero, npcBot ))
		return
	end
--		print(npcBot:GetUnitName(),"currentduel == true")
	return
end




local function GetCreepsInRadius(nRadius)
	local npcBot=GetBot()

	NeutralCreeps = nil
	EnemyCreeps = nil
	NeutralCreeps= npcBot:GetNearbyNeutralCreeps( nRadius )
	EnemyCreeps = npcBot:GetNearbyCreeps( nRadius, true )
	
	if #EnemyCreeps~=0 then
		CurrentCreeps = EnemyCreeps
	elseif #NeutralCreeps~=0 then 
		CurrentCreeps = NeutralCreeps
	end

	ClosestCreep = nil
	WeakestCreep = nil
	StrongestCreep = nil
	local HighestHealth = 0
	local LowestDistance = 10000
	local LowestHealth = 10000

	if CurrentCreeps ~= nil then
	for _,creep in pairs(CurrentCreeps) do
		if creep ~=nil then
			if creep:IsNull() ~= true then
				if creep:IsAlive() then
					if GetUnitToUnitDistance( creep, npcBot )<LowestDistance then
						LowestDistance = GetUnitToUnitDistance( creep, npcBot )
						ClosestCreep=creep
					end
					if creep:GetHealth()<LowestHealth then
						LowestHealth=creep:GetHealth()
						WeakestCreep=creep
					end
					if creep:GetHealth()>HighestHealth then
						HighestHealth = creep:GetHealth()
						StrongestCreep=creep
					end
				end
			end
		end
	end
	end
end




local function SwitchCamps()
	local npcBot=GetBot()
--	print("---> ",npcBot:GetUnitName(),"switchcamps")
	if DotaTime() > -10 then
--		if runningtocreeps == false then
--		print ("---> switchcampcheck ",npcBot:GetUnitName())
		if npcBot.IsRetreating ~= true then
		
--			if CurrentCamp == PingLocation1 and GetUnitToLocationDistance( npcBot, CurrentCamp ) < 150 then


			if npcBot:GetTeam() == TEAM_RADIANT then
				teamtable = GetTeamPlayers(TEAM_RADIANT)
			else
				teamtable = GetTeamPlayers(TEAM_DIRE)
			end
			for arrayKey, playerID in pairs(teamtable) do
				local hUnit = GetTeamMember(playerID)

--Run Once:
				if hUnit ~= nil then
					if PingUnit1 == "" then 
						PingUnit1 = hUnit:GetUnitName()
					elseif PingUnit2== "" then 
						PingUnit2 = hUnit:GetUnitName()
					elseif PingUnit3== "" then 
						PingUnit3 = hUnit:GetUnitName()
					elseif PingUnit4== "" then 
						PingUnit4 = hUnit:GetUnitName()
					elseif PingUnit5== "" then 
						PingUnit5 = hUnit:GetUnitName()
--						print("--> Creating List ",npcBot:GetUnitName(),"Last Unit's Name: ",hUnit:GetUnitName())
					end
				
					local latestPing = hUnit.Ping
					if latestPing ~= nil and latestPing ~= EmptyLocation then 
--						forceBotUnit = hUnit:GetUnitName()
						if PingUnit1 == hUnit:GetUnitName() then
							PingLocation1 = hUnit.Ping
--							print("--> Found a ping: ",npcBot:GetUnitName(),"    Unit's Ping: ",hUnit:GetUnitName())
						elseif PingUnit2 == hUnit:GetUnitName() then
							PingLocation2 = hUnit.Ping
--							print("--> Found a ping: ",npcBot:GetUnitName(),"    Unit's Ping: ",hUnit:GetUnitName())
						elseif PingUnit3 == hUnit:GetUnitName() then
							PingLocation3 = hUnit.Ping
--							print("--> Found a ping: ",npcBot:GetUnitName(),"    Unit's Ping: ",hUnit:GetUnitName())
						elseif PingUnit4 == hUnit:GetUnitName() then
							PingLocation4 = hUnit.Ping
--							print("--> Found a ping: ",npcBot:GetUnitName(),"    Unit's Ping: ",hUnit:GetUnitName())
						elseif PingUnit5 == hUnit:GetUnitName() then
							PingLocation5 = hUnit.Ping
--							print("--> Found a ping: ",npcBot:GetUnitName(),"    Unit's Ping: ",hUnit:GetUnitName())
						end
					end
				end
			end

			--Ping forcebotlocation:
			
			local forceBotLocation = EmptyLocation
			if PingLocation1 ~= EmptyLocation and PingLocation1 ~= PingLocationArrived1 then
				forceBotLocation = PingLocation1
			elseif PingLocation2 ~= EmptyLocation and PingLocation2 ~= PingLocationArrived2 then
				forceBotLocation = PingLocation2
			elseif PingLocation3 ~= EmptyLocation and PingLocation3 ~= PingLocationArrived3 then
				forceBotLocation = PingLocation3
			elseif PingLocation4 ~= EmptyLocation and PingLocation4 ~= PingLocationArrived4 then
				forceBotLocation = PingLocation4
			elseif PingLocation5 ~= EmptyLocation and PingLocation5 ~= PingLocationArrived5 then
				forceBotLocation = PingLocation5
			end

			if forceBotLocation ~= EmptyLocation then
				CurrentCamp = forceBotLocation
--				local halfWayLocation = npcBot:GetLocation() + forceBotLocation
--				halfWayLocation = halfWayLocation/2
--				npcBot:Action_AttackMove (halfWayLocation) --changed fixme?
				npcBot:Action_AttackMove (CurrentCamp)
				if DotaTime() > stopmessage14 then
					--print("-------------->  ForceBotLocation:",npcBot:GetUnitName(),"Camp:",CurrentCamp,"Loc:",npcBot:GetLocation(),"Distance:",GetUnitToLocationDistance( npcBot, CurrentCamp ))
					stopmessage14=DotaTime()+5
				end
				return
			end
			
			if (CurrentCamp == DireMidEasy or CurrentCamp == DireMidMedium) and GetUnitToLocationDistance( npcBot, CurrentCamp ) > 250 then
				npcBot:Action_AttackMove (CurrentCamp)
				if DotaTime() > stopmessage3 then
					--print("--->  Moving To CurrentCamp:",npcBot:GetUnitName())
					stopmessage3=DotaTime()+10
				end
				return
			elseif (CurrentCamp == RadiantMidEasy or CurrentCamp == RadiantMidMedium) and GetUnitToLocationDistance( npcBot, CurrentCamp ) > 250 then
--				local halfWayLocation = npcBot:GetLocation() + CurrentCamp
--				halfWayLocation = halfWayLocation/2
--				npcBot:Action_AttackMove (halfWayLocation) --changed fixme?
				npcBot:Action_AttackMove (CurrentCamp)
				if DotaTime() > stopmessage3 then
					--print("--->  Moving To CurrentCamp:",npcBot:GetUnitName())
					stopmessage3=DotaTime()+10
				end
				return
			elseif GetUnitToLocationDistance( npcBot, CurrentCamp ) > 500 then

--				local halfWayLocation = npcBot:GetLocation() + CurrentCamp
--				halfWayLocation = halfWayLocation/2
--				npcBot:Action_AttackMove (halfWayLocation) --changed fixme?
				npcBot:Action_AttackMove (CurrentCamp)
				if DotaTime() > stopmessage3 then
					--print("--->  Moving To CurrentCamp:",npcBot:GetUnitName())
					stopmessage3=DotaTime()+10
				end
				return
			end
			
			--fixme here:
			if npcBot:GetHealth()/npcBot:GetMaxHealth() < 0.6 then --or npcBot:GetMana()/npcBot:GetMaxMana() < 0.15  then

				npcBot.IsRetreating = true
				if DotaTime() > stopmessage4 then
					--print("---->  Walking Home/Healing After Camp:",npcBot:GetUnitName())
					stopmessage4=DotaTime()+10
				end
			end
			

			if DotaTime() > runTimer then --or npcBot:GetCurrentActionType() == BOT_ACTION_TYPE_IDLE or npcBot:GetCurrentActionType() == BOT_ACTION_TYPE_NONE then --
				
--					print("-->  Switch Camp Check:",npcBot:GetUnitName())
				if NextCamp ~= Vector(0,0) then
					CurrentCamp = NextCamp
					NextCamp = NextNextCamp
					NextNextCamp = Vector(0,0)
					runTimer = DotaTime()+1
					local halfWayLocation = npcBot:GetLocation() + CurrentCamp
					halfWayLocation = halfWayLocation/2
					npcBot:Action_AttackMove (halfWayLocation) --Changed fixme?
--					npcBot:Action_AttackMove (CurrentCamp)
					if DotaTime() > stopmessage5 then
						--print("----->  Current Camp = Next Camp:",npcBot:GetUnitName())
						stopmessage5=DotaTime()+10
					end
					return
				else
					SwitchCamp()
					runTimer = DotaTime()+1
					local halfWayLocation = npcBot:GetLocation() + CurrentCamp
					halfWayLocation = halfWayLocation/2
					npcBot:Action_AttackMove (halfWayLocation) --Changed fixme?
--					npcBot:Action_AttackMove (CurrentCamp)
					if DotaTime() > stopmessage6 then
						--print("------>  SwitchCamp-ing:",npcBot:GetUnitName())
						stopmessage6=DotaTime()+10
					end
					return
				end
			end
		end
	end
end




----------------------------------------------------------------------------
---	Default Functions
----------------------------------------------------------------------------




function  OnStart()
	local npcBot=GetBot()
	if bOnce == false then
		bOnce = true
		if GetBot():GetTeam() == TEAM_RADIANT then
			CurrentCamp = RadiantMidMedium
			NextCamp = RadiantBotMedium
			NextNextCamp = RadiantMidMedium
		else
			CurrentCamp = DireMidMedium
			NextCamp = DireTopMedium
			NextNextCamp = DireMidMedium

		end
	end
end




function OnEnd()
end




function GetDesire()
	local npcBot=GetBot()
	
	if npcBot:HasModifier("modifier_teleporting") then
		npcBot:Action_ClearActions( true )
--		print("---------------------> ",npcBot:GetUnitName()," Attempted teleport intercepted.")
	end
	
	local npcBotLocation = npcBot:GetLocation()
	if npcBot.IsAttacking == true then
--		print(npcBot:GetUnitName(),"npcBot.IsAttacking #1")
	end
--	if npcBot:IsAttacking() == true then
--		print(npcBot:GetUnitName(),"npcBot:IsAttacking() #2")
--	end
--	print("--> Duel Location #1",DuelLocation1,npcBot:GetUnitName(),npcBotLocation)
	if npcBotLocation.x > DuelLocation1.x and npcBotLocation.y < DuelLocation1.y then
		currentduel = true
--		print("--> Duel Location #1a")
		return 0.3
	elseif npcBotLocation.x < DuelLocation2.x and npcBotLocation.y > DuelLocation2.y then
		currentduel = true
--		print("--> Duel Location #2a")
		return 0.3
	else
		currentduel = false
	end
	
	GetClosestHero( maxsearchradius,true )
--	if ClosestHero == nil then
	if #EnemyHeroes~=0 then
		return 0.3
	else
		return 0.60 -- general farm desire
	end
end




function Think()
	local npcBot=GetBot()

	if npcBot:HasModifier("modifier_teleporting") then
		npcBot:Action_ClearActions( true )
--		print("---------------------> ",npcBot:GetUnitName()," Attempted teleport intercepted.")
	end
	
--	local playerNotBot
--	print(npcBot:GetUnitName(),"Farm starting")
--	print(npcBot:GetUnitName(),npcBot:GetAttackPoint(),GetLaneFrontLocation(GetTeam(),LANE_BOT,0.0),GetLaneFrontAmount(GetTeam(),LANE_BOT,true))
	
	if npcBot:IsUsingAbility() or npcBot:IsChanneling() then
		return
	end
	
	if currentduel == true then
		AttackMoveHeroes()
	end
	
	-- Use bottle:
	if DotaTime() > bottleUseTime then
		if npcBot:GetTeam() == TEAM_RADIANT then
			myBase = RadiantBase
		else
			myBase = DireBase
		end
		if GetUnitToLocationDistance( npcBot, myBase ) > 1600 then
			local itemNumber = npcBot:FindItemSlot("item_infinite_bottle")
			if itemNumber ~= -1 then
				if npcBot:GetMaxHealth()-npcBot:GetHealth() >= 100 then --or npcBot:GetMana()/npcBot:GetMaxMana() <= 0.15 then
					local hItem = npcBot:GetItemInSlot( itemNumber )
					if hItem:IsFullyCastable() and hItem:GetCurrentCharges() > 1 then
						--print("->  ",npcBot:GetUnitName()," used: ",hItem:GetName())
						npcBot:Action_UseAbility( hItem )
						bottleUseTime = DotaTime() + 2.50
						return
					end
--					npcBot:Action_UseAbilityOnEntity( hItem, npcBot )
				end
			end
		end
	end
			

----Release ForceBotLocation:
	if GetUnitToLocationDistance( npcBot, PingLocation1 ) < 150 then
		PingLocationArrived1 = PingLocation1
		if DotaTime() > stopmessage15 then
			--print("--------------->  ForceBotLocation 1 finished:",npcBot:GetUnitName())
			stopmessage15=DotaTime()+10
		end
	elseif GetUnitToLocationDistance( npcBot, PingLocation2 ) < 150 then
		PingLocationArrived2 = PingLocation2
		if DotaTime() > stopmessage15 then
			--print("--------------->  ForceBotLocation 2 finished:",npcBot:GetUnitName())
			stopmessage15=DotaTime()+10
		end
	elseif GetUnitToLocationDistance( npcBot, PingLocation3 ) < 150 then
		PingLocationArrived3 = PingLocation3
		if DotaTime() > stopmessage15 then
			--print("--------------->  ForceBotLocation 3 finished:",npcBot:GetUnitName())
			stopmessage15=DotaTime()+10
		end
	elseif GetUnitToLocationDistance( npcBot, PingLocation4 ) < 150 then
		PingLocationArrived4 = PingLocation4
		if DotaTime() > stopmessage15 then
			--print("--------------->  ForceBotLocation 4 finished:",npcBot:GetUnitName())
			stopmessage15=DotaTime()+10
		end
	elseif GetUnitToLocationDistance( npcBot, PingLocation5 ) < 150 then
		PingLocationArrived5 = PingLocation5
		if DotaTime() > stopmessage15 then
			--print("--------------->  ForceBotLocation 5 finished:",npcBot:GetUnitName())
			stopmessage15=DotaTime()+10
		end
	end

--	GetClosestHero( maxsearchradius,true )
--	if ClosestHero ~= nil then 
--		AttackMoveHeroes()
--	end

--	Control with Smoke code
	teamtable = {}
	if npcBot:GetTeam() == TEAM_RADIANT then
		teamtable = GetTeamPlayers(TEAM_RADIANT)
	else
		teamtable = GetTeamPlayers(TEAM_DIRE)
	end
	local halfWayLocation
	local SmokePlayer
	
	bMoveToLocation = false
	bAttackMove = false
	for arrayKey, playerID in pairs(teamtable) do
--		if IsPlayerBot(playerID) then
--		print(npcBot:GetUnitName(),"Is Player",playerID)
		local hUnit = GetTeamMember(playerID)

		
		if hUnit ~= nil then
--		if hUnit:IsPlayer() then
--			end
--			print(npcBot:GetUnitName(),"hUnit ~= nil ",hUnit:GetUnitName())
			local hItem = hUnit:GetItemInSlot( 6 ) 
			local hItem2 = hUnit:GetItemInSlot( 7 ) 
			
			if hItem ~= nil then
				if hItem:GetName() == "item_smoke_of_deceit" then
					bAttackMove = true
					halfWayLocation = hUnit:GetLocation() + npcBot:GetLocation() + npcBot:GetLocation()
					halfWayLocation = halfWayLocation/3
					SmokePlayer = hUnit
				end
			end
			if hItem2 ~= nil then
				if hItem2:GetName() == "item_smoke_of_deceit" then
					bMoveToLocation = true
					halfWayLocation = hUnit:GetLocation() + npcBot:GetLocation() + npcBot:GetLocation()
					halfWayLocation = halfWayLocation/3
					SmokePlayer = hUnit
				end
			end
		end
	end
	
	
--Smoke MoveToLocation Code:
	if bMoveToLocation == true then --changed, fixme?
		if npcBot:GetAttackRange() < GetUnitToUnitDistance( SmokePlayer, npcBot ) then 
			npcBot:Action_MoveToLocation( halfWayLocation )
			if DotaTime() > stopmessage7 then
				--print("------->  Smoke - MoveToLocation:",npcBot:GetUnitName())
				stopmessage7=DotaTime()+10
			end
		end
		return
	end
	
--Pick up items: { hItem, hOwner, nPlayer, vLocation }
--		"owner","item","location","playerid"
	itemcount = 0
	local ItemBottleHandle = nil
	for index =0,8,1 do
		hItem = npcBot:GetItemInSlot( index )
		if hItem ~= nil then
			itemcount = itemcount +1
			if hItem:GetName() == "item_infinite_bottle" then
				ItemBottleHandle = hItem
	--			print("--> ",npcBot:GetUnitName(),"bottle found in inventry.")
			end
		end
	end
	if ItemBottleHandle ~= nil then
		itemcount = itemcount -1
	end
		

	closestBottleLocation = EmptyLocation
	closestBottle = nil

	if itemcount < 9 then
		ItemList = nil
		ItemList = GetDroppedItemList()

		for arrayKey,arrayValue in pairs(ItemList) do
			arrayPlayer = nil
			arrayItem = nil
			arrayLocation = EmptyLocation
			for arrayKey2,arrayValue2 in pairs(arrayValue) do

				if arrayKey2 == "location" then
					arrayLocation = arrayValue2
--				elseif arrayKey2 == "playerid" then
--					arrayPlayer = arrayValue2
				elseif arrayKey2 == "item" then
					arrayItem = arrayValue2
					if arrayItem ~= nil then 
						if arrayItem:GetName() == "item_infinite_bottle" then
--							print("--> ",npcBot:GetUnitName(),"found",arrayItem:GetName())
--							print(arrayLocation,arrayPlayer,arrayItem,arrayItem:GetName())
							if arrayLocation ~= EmptyLocation then
								if badBottle2 ~= arrayItem then
									if GetUnitToLocationDistance(npcBot,arrayLocation) < GetUnitToLocationDistance(npcBot,closestBottleLocation) then
										closestBottleLocation = arrayLocation
										closestBottle = arrayItem
									end
								end
							end
						end
					end
				end
			end
		end

		if closestBottle == nil then
			currentBottle = nil
			if DotaTime() > stopmessage then
--				print ("-> ",npcBot:GetUnitName(),"closestBottle = nil 1 early:")
				stopmessage=DotaTime()+5
			end
		elseif closestBottle ~= badBottle then
--	check to stop running after a bottle in an impossible location
			if currentBottle ~= closestBottle then
				currentBottle = closestBottle
				bottleCheckTime = DotaTime() +2
--				print("-> ",npcBot:GetUnitName(),"new bottle 1:",currentBottle)
			elseif bottleCheckTime < DotaTime() then
				badBottle = closestBottle
				print("---> ",npcBot:GetUnitName(),"bad bottle 1:",badBottle)
			end
			if ItemBottleHandle == nil then
				if GetUnitToLocationDistance(npcBot,closestBottleLocation) < 600 then
	--			print("-> ",npcBot:GetUnitName(),"picking up new:",closestBottle:GetName(),GetUnitToLocationDistance(npcBot,closestBottleLocation))
					npcBot:Action_PickUpItem( closestBottle )
					return
				end
			else
				if ItemBottleHandle:GetCurrentCharges() <= 3 and GetUnitToLocationDistance(npcBot,closestBottleLocation) < 600 then
	--				print("-> ",npcBot:GetUnitName(),"picking up urgent:",closestBottle:GetName(),GetUnitToLocationDistance(npcBot,closestBottleLocation))
					npcBot:Action_PickUpItem( closestBottle )
					return
				elseif ItemBottleHandle:GetCurrentCharges() <= 6 and GetUnitToLocationDistance(npcBot,closestBottleLocation) < 300 then
					npcBot:Action_PickUpItem( closestBottle )
	--				print("-> ",npcBot:GetUnitName(),"picking up due to low charges:",closestBottle:GetName(),GetUnitToLocationDistance(npcBot,closestBottleLocation))
					return
				elseif ItemBottleHandle:GetCurrentCharges() <= 12 and GetUnitToLocationDistance(npcBot,closestBottleLocation) < 150 then
					npcBot:Action_PickUpItem( closestBottle )
	--				print("-> ",npcBot:GetUnitName(),"picking up due to med charges:",closestBottle:GetName(),GetUnitToLocationDistance(npcBot,closestBottleLocation))
					return
				elseif GetUnitToLocationDistance(npcBot,closestBottleLocation) < 75 then
					npcBot:Action_PickUpItem( closestBottle )
	--				print("-> ",npcBot:GetUnitName(),"picking up close:",closestBottle:GetName(),GetUnitToLocationDistance(npcBot,closestBottleLocation))
					return
				else
--					print ("-> ",npcBot:GetUnitName(),"not going for bottle in fight:",currentBottle)
					currentBottle = nil
				end
			end
		end
	end
	
	if creepsearchradius < npcBot:GetAttackRange()+AttackRangeAdded then
		GetCreepsInRadius(npcBot:GetAttackRange()+AttackRangeAdded)
	else
		GetCreepsInRadius(creepsearchradius)
	end
--	NeutralCreeps = nil
--	EnemyCreeps = nil
--	NeutralCreeps = npcBot:GetNearbyNeutralCreeps( creepsearchradius )	--maybe fixes it
--	EnemyCreeps = npcBot:GetNearbyCreeps( creepsearchradius, true )		--maybe fixes it

	if (#EnemyCreeps == 0 and #NeutralCreeps == 0) or ClosestCreep == nil then

--Smoke AttackMove

		if bAttackMove == true then --changed, fixme?
			if npcBot:GetAttackRange() < GetUnitToUnitDistance( SmokePlayer, npcBot ) then 
				npcBot:Action_AttackMove( halfWayLocation )
				if DotaTime() > stopmessage8 then
					--print("-------->  Smoke - AttackMove:",npcBot:GetUnitName())
					stopmessage8=DotaTime()+10
				end
			end
			return
		end
	

		if itemcount < 9 then
--			if DotaTime() > stopmessage then
--				stopmessage=DotaTime()
			if closestBottle == nil then
				currentBottle = nil
				if DotaTime() > stopmessage then
--					print ("-> ",npcBot:GetUnitName(),"closestBottle = nil 2 early:")
					stopmessage=DotaTime()+5
				end
			elseif closestBottle ~= badBottle2 then
--	check to stop running after a bottle in an impossible location
				if currentBottle ~= closestBottle then
					currentBottle = closestBottle
					bottleCheckTime = DotaTime() +4
--					print("-> ",npcBot:GetUnitName(),"new bottle 2:",currentBottle)
				elseif bottleCheckTime < DotaTime() then
					badBottle2 = currentBottle
					print("-----> ",npcBot:GetUnitName(),"bad bottle 2:",badBottle2)
				end

				if ItemBottleHandle == nil then
					if GetUnitToLocationDistance(npcBot,closestBottleLocation) < 2000 then
						npcBot:Action_PickUpItem( closestBottle )
						return
					end
				else
					if ItemBottleHandle:GetCurrentCharges() <= 3 and GetUnitToLocationDistance(npcBot,closestBottleLocation) < 2000 then
						npcBot:Action_PickUpItem( closestBottle )
						return
					elseif ItemBottleHandle:GetCurrentCharges() <= 6 and GetUnitToLocationDistance(npcBot,closestBottleLocation) < 1200 then
						npcBot:Action_PickUpItem( closestBottle )
						return
					elseif ItemBottleHandle:GetCurrentCharges() <= 12 and GetUnitToLocationDistance(npcBot,closestBottleLocation) < 600 then
						npcBot:Action_PickUpItem( closestBottle )
						return
					elseif ItemBottleHandle:GetCurrentCharges() <= 24 and GetUnitToLocationDistance(npcBot,closestBottleLocation) < 300 then
						npcBot:Action_PickUpItem( closestBottle )
						return
					elseif GetUnitToLocationDistance(npcBot,closestBottleLocation) < 150 then
						npcBot:Action_PickUpItem( closestBottle )
						return
					else
--						print ("-> ",npcBot:GetUnitName(),"not going for bottle out of fight:",currentBottle)
						currentBottle = nil
					end
				end
			end
		end

		if npcBot.SwitchCamp == true then
			SwitchCamp()
		end

		SwitchCamps()
		npcBot.SwitchCamp = false
		return
	end

	--Outside range code:
	
	if npcBot:GetAttackRange()+AttackRangeAdded < GetUnitToUnitDistance( ClosestCreep, npcBot ) then 

	--Fix Getting Stuck
		if quickRunBackTimer > DotaTime() then
			if npcBot:GetTeam() == TEAM_RADIANT then
				myBase = RadiantMidHalfWay
			else
				myBase = DireMidHalfWay
			end
			npcBot:Action_MoveToLocation(myBase)
			print("--->  Fix Getting Stuck",npcBot:GetUnitName())
			return
		end
	
	--Fix Getting Stuck
		if newLocationTimer < DotaTime() then	
			newLocationTimer = DotaTime()+3
			local NewLocation = npcBot:GetLocation()
			if NewLocation == OldLocation then
				quickRunBackTimer = DotaTime()+3
--				print("--->  Location Stuck",npcBot:GetUnitName())
			else
				OldLocation = NewLocation
			end
		end
		

	--AttackMove - Closest Creep - From Outside Range
		local halfWayLocation = ClosestCreep:GetLocation() + npcBot:GetLocation() + npcBot:GetLocation()
		halfWayLocation = halfWayLocation/3
		npcBot:Action_AttackMove( halfWayLocation )
		if DotaTime() > stopmessage11 then
			--print("----------->  AttackMove - Closest Creep - From Outside Range:",npcBot:GetUnitName())
			stopmessage11=DotaTime()+10
		end
		return
	else
		--Creep is Within Range script
	
		GetCreepsInRadius(npcBot:GetAttackRange()+AttackRangeAdded)
		local oldClosestCreep = ClosestCreep

			--Cast Spells script:
		if abilityWaitTimer <= DotaTime() then
			
			currentAbilityAttempt = currentAbilityAttempt +1
			if currentAbilityAttempt > 4 then
				currentAbilityAttempt = 1
				if npcBot:GetUnitName() == "npc_dota_hero_nevermore" then
					currentAbility = currentAbility -1
				else
					currentAbility = currentAbility +1
				end
			end

			hAbility = nil
			while hAbility == nil do
				if currentAbility >= 16 then
					currentAbility = 0
				elseif currentAbility < 0 then
					currentAbility = 15
				end
				hAbility = npcBot:GetAbilityInSlot(currentAbility)
				if hAbility ~= nil then
				--Kunkka, Lion, Bristleback,
				local AN = hAbility:GetName()
					if AN== "bristleback_viscous_nasal_goo" or AN== "lion_voodoo" or AN== "kunkka_x_marks_the_spot" or AN== "death_prophet_silence" or AN== "omniknight_repel" or AN== "oracle_fates_edict" or AN== "skywrath_mage_concussive_shot" or AN== "warlock_upheaval" or AN== "windrunner_shackleshot" or AN== "witch_doctor_maledict" or AN== "bounty_hunter_wind_walk" or AN== "bounty_hunter_wind_walk" then
						hAbility = nil
						currentAbility = currentAbility +1
					elseif hAbility:IsUltimate() == true then
						hAbility = nil
						if npcBot:GetUnitName() == "npc_dota_hero_nevermore" then
							currentAbility = currentAbility -1
						else
							currentAbility = currentAbility +1
						end
					end
				else
					if npcBot:GetUnitName() == "npc_dota_hero_nevermore" then
						currentAbility = currentAbility -1
					else
						currentAbility = currentAbility +1
					end
				end
			end
	--			if npcBot:GetUnitName() == "npc_dota_hero_juggernaut" then
	--				print ("Juggernaut")
	--				if hAbility:GetName() == "juggernaut_blade_fury" then
	--					local abilitybehavior = hAbility:GetBehavior()
	--					local abilitytargetteam = hAbility:GetAbilityTargetTeam()
	--					print ("---> ",GetBot():GetUnitName(), hAbility:GetName(), " GetBehavior = ", abilitybehavior)
	--					print ("---> ",GetBot():GetUnitName(), hAbility:GetName(), " GetAbilityTargetTeam = ", abilitytargetteam)
	--				else 
	--					print ("---> ",GetBot():GetUnitName(), hAbility:GetName())
	--				end
	--			end

----	Toggle on AutoCast:
--			local AN = hAbility:GetName()
--			if (AN== "viper_poison_attack" or AN== "drow_ranger_frost_arrows" or AN== "jakiro_liquid_fire" or AN== "clinkz_searing_arrows" or AN== "doom_bringer_infernal_blade" or AN== "enchantress_impetus" or AN== "huskar_burning_spear" or AN== "obsidian_destroyer_arcane_orb" or AN== "silencer_glaives_of_wisdom" or AN== "tusk_walrus_punch" or AN== "lich_frost_armor" or AN== "ogre_magi_bloodlust") then
--				if hAbility:GetAutoCastState() == false then
--					hAbility:ToggleAutoCast()
--					print ("->  Toggle On:",GetBot():GetUnitName(), hAbility:GetName())
--					if npcBot:GetUnitName() == "npc_dota_hero_nevermore" then
--						currentAbility = currentAbility -1
--					else
--						currentAbility = currentAbility +1
--					end
--					abilityWaitTimer= DotaTime()+1
--					return
--				end
--			end



--			if hAbility:IsToggle() and hAbility:GetToggleState() == false then--hAbility:IsToggle() then--and hAbility:GetToggleState() == false then
--				hAbility:ToggleAutoCast()
--				print ("->  Toggle On:",GetBot():GetUnitName(), hAbility:GetName())
--			end

	--		local hAbility = npcBot:GetAbilityInSlot(currentAbility)
	--		print ("---> cooldown) ",GetBot():GetUnitName(),hAbility:GetName(),hAbility:GetCooldownTimeRemaining())
			if hAbility and not hAbility:IsPassive() and hAbility:IsFullyCastable() then--  and not hAbility:IsToggle() and hAbility:GetLevel() > 0 and hAbility:GetCooldownTimeRemaining() == 0 then
	--			print ("---> Legit Ability, attempt) ",currentAbilityAttempt,GetBot():GetUnitName(), hAbility:GetName())
	
--				if npcBot:GetUnitName() == "npc_dota_hero_viper" then
--					print("-> ",hAbility:GetName())
--				end
	
				local bitBandBehavior = hAbility:GetBehavior()
				if currentAbilityAttempt == 1 then
					if not bit.band(bitBandBehavior, DOTA_ABILITY_BEHAVIOR_UNIT_TARGET ) then
						currentAbilityAttempt = 2
	--					print ("---> currentAbilityAttempt = 2a) ",GetBot():GetUnitName(), hAbility:GetName())
					end
	--				if bit.band(bitBandBehavior, DOTA_ABILITY_BEHAVIOR_NO_TARGET ) then
	--					currentAbilityAttempt = 2
	--				print ("---> currentAbilityAttempt = 2b) ",GetBot():GetUnitName(), hAbility:GetName())
	--				end
				end
				if currentAbilityAttempt == 1 or currentAbilityAttempt == 2 then
					if bit.band(bitBandBehavior, DOTA_ABILITY_BEHAVIOR_POINT ) and not bit.band(bitBandBehavior, DOTA_ABILITY_BEHAVIOR_UNIT_TARGET ) then
						currentAbilityAttempt = 3
	--					print ("---> currentAbilityAttempt = 3) ",GetBot():GetUnitName(), hAbility:GetName())
					end
				end
				if DotaTime() > stopmessage9 then
					--print("--------->  using CurrentAbility ",npcBot:GetUnitName(),currentAbilityAttempt)
					stopmessage9=DotaTime()+1
				end
				--Do the spell
				if currentAbilityAttempt == 1 then
	--			if bit.band(hAbility:GetBehavior(), DOTA_ABILITY_BEHAVIOR_UNIT_TARGET ) then
					if GetUnitToUnitDistance( ClosestCreep, npcBot ) < npcBot:GetAttackRange()+AttackRangeAdded then
						npcBot:Action_UseAbilityOnEntity(hAbility,WeakestCreep)
						abilityWaitTimer = DotaTime()+abilityWaitAdd
	--				if GetBot():GetUnitName() == npc_dota_hero_dazzle then
	--					print ("---> Action_UseAbilityOnEntity(hAbility,WeakestCreep) ",GetBot():GetUnitName(), hAbility:GetName())
	--				end
						return
					end
				elseif currentAbilityAttempt == 2 then
	--				if bit.band(hAbility:GetBehavior(), DOTA_ABILITY_BEHAVIOR_AOE ) then
					if GetUnitToUnitDistance( ClosestCreep, npcBot ) < npcBot:GetAttackRange()+AttackRangeAdded then
--						if hAbility:GetName() ~= "nevermore_shadowraze3" then
							npcBot:Action_UseAbility(hAbility)
							abilityWaitTimer = DotaTime()+abilityWaitAdd
	--						if GetBot():GetUnitName() == npc_dota_hero_dazzle then
	--						print ("---> Action_UseAbility(hAbility) ",GetBot():GetUnitName(), hAbility:GetName())
	--						end
							return
--						end
					end
				elseif currentAbilityAttempt == 3 then
					local shrapnelWait = false
					if GetUnitToUnitDistance( ClosestCreep, npcBot ) < npcBot:GetAttackRange()+AttackRangeAdded then
						if hAbility:GetName() == "sniper_shrapnel" and shrapnelTimer < DotaTime() then
							shrapnelTimer = DotaTime() + 20
--							print("Sniper - shrapnelTimer < DotaTime()")
						elseif hAbility:GetName() == "sniper_shrapnel" and shrapnelTimer > DotaTime() then
							shrapnelWait = true
--							print("Sniper - shrapnelWait = true")
						end
						if shrapnelWait == false then
--							print ("---> Action_UseAbilityOnLocation() ",GetBot():GetUnitName(), hAbility:GetName())
	--				if bit.band(hAbility:GetBehavior(), DOTA_ABILITY_BEHAVIOR_NO_TARGET ) or bit.band(hAbility:GetBehavior(), DOTA_ABILITY_BEHAVIOR_POINT ) then
							npcBot:Action_UseAbilityOnLocation(hAbility,WeakestCreep:GetLocation())
							abilityWaitTimer = DotaTime()+abilityWaitAdd
	--				if GetBot():GetUnitName() == npc_dota_hero_dazzle then
	--					print ("---> Action_UseAbilityOnLocation(hAbility,WeakestCreep:GetLocation()) ",GetBot():GetUnitName(), hAbility:GetName())
	--				end
							return
						end
					end
				elseif currentAbilityAttempt == 4 and hAbility:GetName() ~= "bane_nightmare" then
					if GetUnitToUnitDistance( ClosestCreep, npcBot ) < npcBot:GetAttackRange()+AttackRangeAdded then
						npcBot:Action_UseAbilityOnEntity(hAbility,npcBot)
						abilityWaitTimer = DotaTime()+abilityWaitAdd
	--					if GetBot():GetUnitName() == npc_dota_hero_dazzle then
	--						print ("---> Self -> Action_UseAbilityOnEntity(hAbility,npcBot:GetUnitName()) ",npcBot:GetUnitName(), hAbility:GetName())
	--					end
						return
					end
	--			elseif currentAbilityAttempt == 4 then
	--				if bit.band(hAbility:GetBehavior(), DOTA_ABILITY_BEHAVIOR_NO_TARGET ) or bit.band(hAbility:GetBehavior(), DOTA_ABILITY_BEHAVIOR_POINT ) then
	--					npcBot:Action_UseAbilityOnLocation(hAbility,StrongestCreep:GetLocation())
	--					abilityWaitTimer = DotaTime()+abilityWaitAdd
	--					print ("---> Action_UseAbilityOnLocation(hAbility,StrongestCreep:GetLocation()) ",GetBot():GetUnitName(), hAbility:GetName())
	--					return
				end
				
	--					return
	--				if bit.band(hAbility:GetAbilityTargetTeam(), DOTA_UNIT_TARGET_TEAM_FRIENDLY ) then
	--					npcBot:Action_UseAbilityOnEntity(hAbility,npcBot)
	--					abilityWaitTimer = DotaTime()+abilityWaitAdd
	--					print ("---> DOTA_UNIT_TARGET_TEAM_FRIENDLY (self) ",GetBot():GetUnitName(), hAbility:GetName())
	--				end
	--					return
	--				elseif bit.band(hAbility:GetAbilityTargetTeam(), DOTA_UNIT_TARGET_NONE ) then
	--					npcBot:Action_UseAbility(hAbility)
	--					abilityWaitTimer = DotaTime()+abilityWaitAdd
	--						print ("---> DOTA_UNIT_TARGET_NONE ",GetBot():GetUnitName(), hAbility:GetName())
	--					return
	--				if GetUnitToUnitDistance( ClosestCreep, npcBot ) < npcBot:GetAttackRange()+AttackRangeAdded then
	--					npcBot:Action_UseAbility(hAbility)
	--					abilityWaitTimer = DotaTime()+abilityWaitAdd
	--						print ("---> Just use anything ",GetBot():GetUnitName(), hAbility:GetName())
	--					return
	--				end
	--			end
	--		else
	--			currentAbilityAttempt = 1
	--			currentAbility = currentAbility +1
			else
				currentAbilityAttempt = 0
				if npcBot:GetUnitName() == "npc_dota_hero_nevermore" then
					currentAbility = currentAbility -1
				else
					currentAbility = currentAbility +1
				end
			end
		end

		
		if npcBot.Target ~= nil then
			if npcBot.Target:IsNull() then
				npcBot.Target = nil
			end
		end
		
		if GetUnitToUnitDistance( WeakestCreep, npcBot ) <= npcBot:GetAttackRange()+AttackRangeAdded then
			if npcBot.Target == nil or npcBot.Target:IsAlive() ~= true then
				npcBot.Target = WeakestCreep
				if DotaTime() > stopmessage12 then
					--print("------------>  npcBot.Target == nil or is not alive, npcBot.Target = WeakestCreep:",npcBot:GetUnitName())
					stopmessage12=DotaTime()+10
				end
			else
				if npcBot.Target:GetHealth() > WeakestCreep:GetHealth() then
					npcBot.Target = WeakestCreep
					if DotaTime() > stopmessage13 then
						--print("------------->  npcBot.Target:GetHealth() > WeakestCreep:GetHealth(), npcBot.Target = WeakestCreep:",npcBot:GetUnitName())
						stopmessage13=DotaTime()+10
					end
				end
			end
		else
			npcBot.Target = ClosestCreep
		end
		
		
	----	#Mini Retreat 
	--	if npcBot.Back == true then
	--		if npcBot:WasRecentlyDamagedByCreep( 1.0 ) == false or GetUnitToUnitDistance(npcBot.Target,npcBot) > npcBot:GetAttackRange()/1.5 then
	--			npcBot.Back = false
	--		end
	--	end


	--	if npcBot:WasRecentlyDamagedByCreep( 1.0 ) == true and GetUnitToUnitDistance(ClosestCreep,npcBot) < npcBot:GetAttackRange()/2 then
	--		npcBot.Back = true
	--	end

		
	--	if runawaytimer < DotaTime() then
	--		runawaytimer = DotaTime()+4
	--		if npcBot.Back == true then
	--			print ("---> ",GetBot():GetUnitName(),"runaway")
	--			if npcBot:GetTeam() == TEAM_RADIANT then
	--				npcBot:Action_MoveToLocation( RadiantBase ) 
	--				return
	--			else
	--				npcBot:Action_MoveToLocation( DireBase )
	--				return
	--			end
	--		end
	--	end


	--	if npcBot:GetAttackRange() < 200 then
	--		if npcBot.Target == nil or npcBot.Target:IsAlive() ~= true then
	--			npcBot.Target = WeakestCreep --ClosestCreep

	--		elseif npcBot:GetAttackRange()+50 < GetUnitToUnitDistance( npcBot.Target, npcBot ) then  -- this just doesn't work.
	--			print ("---> ",GetBot():GetUnitName(),"New Target Distance",GetUnitToUnitDistance(ClosestCreep,npcBot),"Old Target Distance",GetUnitToUnitDistance(npcBot.Target,npcBot))
	--			npcBot.Target = ClosestCreep
	--		end


	--	print("--->  Weakest Creep Distance:	",npcBot:GetUnitName(), GetUnitToUnitDistance( WeakestCreep, npcBot ))
		npcBot:Action_AttackUnit(npcBot.Target,true)
	--	runningtocreeps = true
		if DotaTime() > stopmessage10 then
			--print("---------->  AttackUnit - Closest/Weakest Creep",npcBot:GetUnitName())
			stopmessage10=DotaTime()+10
		end
		return
	end
	print(npcBot:GetUnitName(),"No action???")
end

