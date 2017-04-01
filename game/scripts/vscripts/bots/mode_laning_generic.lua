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

local AttackRangeModifier = 1.2
local AttackRangeAdded = 100


local WeakestCreep = nil
local StrongestCreep = nil
local ClosestCreep = nil
local ClosestHero = nil

--Vectors
local DuelLocation1 = Vector(4600,-4200)
local DuelLocation2 = Vector(-4900,4400)

local DireBase = Vector(5000,-300)
local RadiantBase = Vector(-5000,-300)

local RadiantBotEasy = Vector(-3750,1400)
local RadiantTopEasy = Vector(-3750,-1300)
local RadiantMidEasy = Vector(-1100,-400)
local RadiantMidMedium = Vector(-2100,200)
local RadiantBotMedium = Vector(-1900,-2200)
local RadiantTopMedium = Vector(-1800,1900)

local DireTopEasy = Vector(3750,1200)
local DireBotEasy = Vector(3800,-1600)
local DireMidEasy = Vector(1000,200)
local DireMidMedium = Vector(2000,-600)
local DireTopMedium = Vector(1600,2000)
local DireBotMedium = Vector(1700,-2500)


local AncientsTop = Vector(0,2500)
local AncientsBot = Vector(0,-3000)

local CurrentCamp = Vector(0,0)
local NextCamp = Vector(0,0)
local NextNextCamp = Vector(0,0)



local runningtocreeps = false
local bOnce = false
local movingtoheroes = false
local camp = 2

local oldmode = 3454
		
local currentAbility = 0


--stop timers

local runawaytimer = -100
local attackmovetime = -100
local fightwaittime = -100
local stopmessage = -100
local runtime = -100
local herofighttime = -100
local campswitchtime = -100
local abilitywaittime = -100
local abilitywaitadd = 0.75
local movewaittime = -100



local EnemyHeroes = {}
local EnemyCreeps = {}
local NeutralCreeps = {}
local CurrentCreeps = {}

local currentduel = false



----	Important Hero vs Hero/Creep Variables:

local maxsearchradius = 1600 --Must not be greater than 1600 or error
local creepsearchradius = 1000  -- (1200) Must not be greater than 1600 or error
local AISwitchOffDistance = 1400 -- must not be greater than 1600





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




local function SwitchCamp()
	local npcBot=GetBot()

	local randomx=camp
	local lowernumber = 0
	local uppernumber = 4
	if npcBot:GetLevel() <= 4 then
		lowernumber = 0
		uppernumber = 4
	elseif npcBot:GetLevel() <= 8 then
		lowernumber = 0
		uppernumber = 5
	elseif npcBot:GetLevel() <= 12 then
		lowernumber = 0
		uppernumber = 6
	elseif npcBot:GetLevel() <= 16 then
		lowernumber = 1
		uppernumber = 8
	elseif npcBot:GetLevel() <= 20 then
		lowernumber = 1
		uppernumber = 8
--	elseif npcBot:GetLevel() < 25 then
--		lowernumber = 4
--		uppernumber = 11
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
--	if DotaTime() > stopmessage then
--		print("---------------------> ",npcBot:GetUnitName()," is switching camps to #",camp)
--		stopmessage=DotaTime()+2
--	end
	runtime = DotaTime()+5 
	camp = randomx

	if npcBot:GetTeam() == TEAM_RADIANT then
		if camp == 1 then
			CurrentCamp = RadiantBotEasy
		elseif camp == 2 then
			CurrentCamp = RadiantTopEasy
		elseif camp == 3 then
			CurrentCamp = RadiantMidEasy
		elseif camp == 4 then
			CurrentCamp = RadiantMidMedium
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
			CurrentCamp = AncientsTop
		elseif camp == 11 then
			CurrentCamp = AncientsBot
		end
	else
		if camp == 1 then
			CurrentCamp = DireBotEasy
		elseif camp == 2 then
			CurrentCamp = DireTopEasy
		elseif camp == 3 then
			CurrentCamp = DireMidEasy
		elseif camp == 4 then
			CurrentCamp = DireMidMedium
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
	
	local AttackRange = AISwitchOffDistance
	if GetUnitToUnitDistance( ClosestHero, npcBot ) > AttackRange then
--	if attackmovetime < DotaTime() then
		attackmovetime = DotaTime()+5
		local halfWayLocation = ClosestHero:GetLocation() + npcBot:GetLocation() + npcBot:GetLocation()
		halfWayLocation = halfWayLocation/3
--		npcBot:Action_ClearActions( true )
		npcBot:Action_AttackMove( halfWayLocation )
--		print("--> AttackMoveHeroes: ",npcBot:GetUnitName(),"ClosestHero: ",ClosestHero:GetUnitName(),"Distance:",GetUnitToUnitDistance( ClosestHero, npcBot ))
		return
	end
--		print(npcBot:GetUnitName(),"currentduel == true")
	return
end




local function GetCreepsInRadius(nRadius)
	local npcBot=GetBot()

	NeutralCreeps= npcBot:GetNearbyNeutralCreeps( creepsearchradius )
	EnemyCreeps = npcBot:GetNearbyCreeps( creepsearchradius, true )
	
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




local function SwitchCamps()
	local npcBot=GetBot()
	
	if DotaTime() > -10 then
		if runningtocreeps == false then
--		print ("---> switchcampcheck ",npcBot:GetUnitName())
			if (CurrentCamp == RadiantMidMedium or CurrentCamp == DireMidMedium) and GetUnitToLocationDistance( npcBot, CurrentCamp ) > 300 then
				npcBot:Action_AttackMove (CurrentCamp)
				return
			elseif (CurrentCamp == RadiantMidEasy or CurrentCamp == DireMidEasy) and GetUnitToLocationDistance( npcBot, CurrentCamp ) > 300 then
				npcBot:Action_AttackMove (CurrentCamp)
				return
			elseif GetUnitToLocationDistance( npcBot, CurrentCamp ) > 900 then
				npcBot:Action_AttackMove (CurrentCamp)
				return
--			npcBot:Action_MoveToLocation (CurrentCamp)
			else
				if DotaTime() > runtime then --or npcBot:GetCurrentActionType() == BOT_ACTION_TYPE_IDLE or npcBot:GetCurrentActionType() == BOT_ACTION_TYPE_NONE then --
					if NextCamp ~= Vector(0,0) then
						CurrentCamp = NextCamp
						NextCamp = NextNextCamp
						NextNextCamp = Vector(0,0)
						npcBot:Action_AttackMove (CurrentCamp)
						return
					else
						SwitchCamp()
						runtime = DotaTime()+1
						npcBot:Action_AttackMove (CurrentCamp)
						return
--					npcBot:Action_MoveToLocation (CurrentCamp)
--					return
					end
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
--	npcBot.IsFarming = true
	if bOnce == false then
		bOnce = true
		if GetBot():GetTeam() == TEAM_RADIANT then
			CurrentCamp = RadiantMidMedium
			NextCamp = RadiantBotMedium
			NextNextCamp = RadiantMidMedium
		else
			CurrentCamp = RadiantMidMedium	--DireMidMedium
			NextCamp = RadiantMidMedium	--DireTopMedium
			NextNextCamp = RadiantMidMedium	--DireMidMedium

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
		return 0.1
	elseif npcBotLocation.x < DuelLocation2.x and npcBotLocation.y > DuelLocation2.y then
		currentduel = true
--		print("--> Duel Location #2a")
		return 0.1
	else
		currentduel = false
	end
	
	GetClosestHero( maxsearchradius,true )
--	if ClosestHero == nil then
	if #EnemyHeroes==0 then
		return 0.1
	else
		return 0.7 -- general farm desire
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
--	GetClosestHero( maxsearchradius,true )
--	if ClosestHero ~= nil then 
--		AttackMoveHeroes()
--	end
	
	

--	print(npcBot:GetUnitName(),"Farm continuing")
	
	if npcBot.IsFarming == false then
--	if npcBot.IsRetreating == true and campswitchtime < DotaTime() then
--		campswitchtime = DotaTime() +30
		SwitchCamp()
--		print ("---> ",npcBot:GetUnitName()," switched camps")
		npcBot.IsFarming = true
	end

	
	GetCreepsInRadius(creepsearchradius)

	if #EnemyCreeps == 0 and #NeutralCreeps == 0 then
		runningtocreeps = false
		SwitchCamps()
		return
	else
		runningtocreeps = true
	end
	

	if npcBot:GetAttackRange()+AttackRangeAdded < GetUnitToUnitDistance( ClosestCreep, npcBot ) then 
--		npcBot.Target = ClosestCreep
		local halfWayLocation = ClosestCreep:GetLocation() + npcBot:GetLocation()
		halfWayLocation = halfWayLocation/2
		npcBot:Action_AttackMove( halfWayLocation )
		runningtocreeps = true
--			print("---> ",npcBot:GetUnitName()," attackmoving because of creep distance: ",GetUnitToUnitDistance( ClosestCreep, npcBot )," range is greater than : GetAttackRange()",npcBot:GetAttackRange()+AttackRangeAdded)
		movewaittime = DotaTime()+1.0
		return
	end

	local currentsearchradius = 0
	if npcBot:GetAttackRange()+AttackRangeAdded > creepsearchradius then
		currentsearchradius = creepsearchradius
	else
		currentsearchradius = npcBot:GetAttackRange()+AttackRangeAdded
	end

	GetCreepsInRadius(npcBot:GetAttackRange()+50)

		--DOTA_UNIT_TARGET_TEAM_ENEMY
		--DOTA_UNIT_TARGET_TEAM_BOTH 
		--DOTA_UNIT_TARGET_HERO 
		--DOTA_UNIT_TARGET_CREEP 
--		local spellList = {}
		
		--print ("---------------------> ",GetBot():GetUnitName(),"used spell number",hAbility:GetName())
	if abilitywaittime < DotaTime() then
--		print ("---------------------> ",GetBot():GetUnitName(),"spellwait < DotaTime1")
		local hAbility = nil
		while hAbility == nil do
			currentAbility= currentAbility+1
			if currentAbility >= 16 then
				currentAbility = 0
			end
			hAbility = npcBot:GetAbilityInSlot(currentAbility)
			if hAbility ~= nil then
				if hAbility:IsUltimate() == true then
					hAbility = nil
				end
			end
--				if hAbility:IsFullyCastable() ~= true
--					hAbility = nil
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

		local hAbility = npcBot:GetAbilityInSlot(currentAbility)
		if hAbility and not hAbility:IsPassive() and not hAbility:IsToggle() and hAbility:GetLevel() > 0 then
		
			if hAbility:IsFullyCastable() then
				runningtocreeps = true
				local abilityName = hAbility:GetName()
				local testing = hAbility:GetBehavior()
				if bit.band(hAbility:GetBehavior(), DOTA_ABILITY_BEHAVIOR_UNIT_TARGET ) then
					npcBot:Action_UseAbilityOnEntity(hAbility,StrongestCreep)
					abilitywaittime = DotaTime()+abilitywaitadd
					return
				elseif bit.band(hAbility:GetBehavior(), DOTA_ABILITY_BEHAVIOR_AOE ) then
					if GetUnitToUnitDistance( ClosestCreep, npcBot ) < 200 then
						npcBot:Action_UseAbility(hAbility)
						abilitywaittime = DotaTime()+abilitywaitadd
						return
					end
				elseif bit.band(hAbility:GetBehavior(), DOTA_ABILITY_BEHAVIOR_NO_TARGET ) or bit.band(hAbility:GetBehavior(), DOTA_ABILITY_BEHAVIOR_POINT ) then
					npcBot:Action_UseAbilityOnLocation(hAbility,StrongestCreep:GetLocation())
					abilitywaittime = DotaTime()+abilitywaitadd
					return
				elseif bit.band(hAbility:GetAbilityTargetTeam(), DOTA_UNIT_TARGET_TEAM_FRIENDLY ) then
					npcBot:Action_UseAbilityOnEntity(hAbility,npcBot)
					abilitywaittime = DotaTime()+abilitywaitadd
					return
				elseif bit.band(hAbility:GetAbilityTargetTeam(), DOTA_UNIT_TARGET_NONE ) then
					npcBot:Action_UseAbility(hAbility)
					abilitywaittime = DotaTime()+abilitywaitadd
					return
				elseif GetUnitToUnitDistance( ClosestCreep, npcBot ) < 200 then
					npcBot:Action_UseAbility(hAbility)
					abilitywaittime = DotaTime()+abilitywaitadd
					return
				end
			end
		end
	end

	
	if npcBot.Target ~= nil then
		if npcBot.Target:IsNull() then
			npcBot.Target = nil
		end
	end
	
	if npcBot.Target == nil or npcBot.Target:IsAlive() ~= true then
		npcBot.Target = WeakestCreep
	elseif npcBot.Target:GetHealth() > WeakestCreep:GetHealth() then
		npcBot.Target = WeakestCreep
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


	npcBot:Action_AttackUnit(npcBot.Target,true)
	runningtocreeps = true
	return

end

