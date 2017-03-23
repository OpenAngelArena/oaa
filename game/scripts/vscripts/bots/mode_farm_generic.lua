--- AUTHOR: RamonNZ 
--- This is mostly built from the ground up. In fact it's kind of a clusterfuck of code. 
--- I wrote the whole thing in one file rather that switching between different files and desire. Yes I eventually will do that.
--- Credits: PLATINUM_DOTA2 (Pooya J.) I took a bit of his code here and there, but not much.  However I learned a lot from looking at what he did.

--Utility = require( GetScriptDirectory().."/Utility")
--Duels = require( GetScriptDirectory() .. "/vscripts/components/duels/duels")
--require('components/duels/duels')

-------
_G._savedEnv = getfenv()
module( "mode_generic_laning", package.seeall )
----------1

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

local WeakestCreep=nil;
local LowestHealth=10000;

local DireBase = Vector(5000,-300);
local Dire1 = Vector(3600,-1100);	--bot easy
local Dire2 = Vector(3600,1000);	--top easy
local Dire3 = Vector(1200,-400); 	--mid easy
local Dire4 = Vector(2200,0);		--mid hard
local Dire5 = Vector(2200,-2300);	--bot hard
local Dire6 = Vector(1700,1800);	--top hard
local RadiantBase = Vector(-5000,-300);
local Radiant1 = Vector(-3600,1000);	--bot easy
local Radiant2 = Vector(-3600,-1300);	--top easy
local Radiant3 = Vector(-1200,-400); 	--mid easy
local Radiant4 = Vector(-2200,0);		--mid hard
local Radiant5 = Vector(-1700,-1900);	--bot hard
local Radiant6 = Vector(-1900,1700);	--top hard

local Ancient1 = Vector(0,2500);
local Ancient2 = Vector(0,-3000);
local CurrentCamp = Vector(0,0);
local bOnce = false;
local camp = 2;

local oldmode = 3454;
		local spellwait = 0;
		local currentspell = 0;

local stopmessage = -100;
local xxtime = 0;
local runtime = -10;
local retreattime = -100;

local herosearchradius = 1200; --Must be below 1600
local creepsearchradius = 500; --Must be below 1600. Don't make too high or they try to attack 2 camps at once.

function  OnStart()
	if bOnce == false then
		if GetBot():GetTeam() == TEAM_DIRE then
			CurrentCamp = Dire2;
			bOnce = true;
		else
			CurrentCamp = Radiant2;
			bOnce = true;
		end
	end
end

function OnEnd()
end

function GetDesire()
	return 0.99;
end

local function SwitchCamp()
	local npcBot=GetBot()

	local randomx=camp;
	local lowernumber = 1;
	local uppernumber = 3;
	if npcBot:GetLevel() <= 3 then
		lowernumber = 1;
		uppernumber = 3;
	elseif npcBot:GetLevel() <= 6 then
		lowernumber = 1;
		uppernumber = 4;
	elseif npcBot:GetLevel() <= 9 then
		lowernumber = 1;
		uppernumber = 5;
	elseif npcBot:GetLevel() <= 11 then
		lowernumber = 1;
		uppernumber = 6;
	elseif npcBot:GetLevel() <= 18 then
		lowernumber = 1;
		uppernumber = 9;
--	elseif npcBot:GetLevel() < 25 then
--		lowernumber = 4;
--		uppernumber = 11;
	else
		lowernumber = 4;
		uppernumber = 11;
	end
	while camp == randomx do
		randomx= RandomInt( lowernumber, uppernumber );
	end
--	if DotaTime() > stopmessage then
--		print("---------------------> ",npcBot:GetUnitName()," is switching camps to #",camp);
--		stopmessage=DotaTime()+2;
--	end
	runtime = DotaTime()+5; 
	camp = randomx;

	if npcBot:GetTeam() == TEAM_RADIANT then
		if camp == 1 then
			CurrentCamp = Radiant1
		elseif camp == 2 then
			CurrentCamp = Radiant2
		elseif camp == 3 then
			CurrentCamp = Radiant3
		elseif camp == 4 then
			CurrentCamp = Radiant4
		elseif camp == 5 then
			CurrentCamp = Radiant5
		elseif camp == 6 then
			CurrentCamp = Radiant6
		elseif camp == 7 then
			CurrentCamp = Dire5
		elseif camp == 8 then
			CurrentCamp = Dire6
		elseif camp == 9 then
			CurrentCamp = Dire4
		elseif camp == 10 then
			CurrentCamp = Ancient1
		elseif camp == 11 then
			CurrentCamp = Ancient2
		end
	else
		if camp == 1 then
			CurrentCamp = Dire1
		elseif camp == 2 then
			CurrentCamp = Dire2
		elseif camp == 3 then
			CurrentCamp = Dire3
		elseif camp == 4 then
			CurrentCamp = Dire4
		elseif camp == 5 then
			CurrentCamp = Dire5
		elseif camp == 6 then
			CurrentCamp = Dire6
		elseif camp == 7 then
			CurrentCamp = Radiant5
		elseif camp == 8 then
			CurrentCamp = Radiant6
		elseif camp == 9 then
			CurrentCamp = Radiant4
		elseif camp == 10 then
			CurrentCamp = Ancient1
		elseif camp == 11 then
			CurrentCamp = Ancient2
		end
	end
end

function Think()
	local npcBot=GetBot()
--	local playerNotBot;
	
--	print(npcBot:GetUnitName(),npcBot:GetAttackPoint(),GetLaneFrontLocation(GetTeam(),LANE_BOT,0.0),GetLaneFrontAmount(GetTeam(),LANE_BOT,true));
	
	if npcBot:IsUsingAbility() or npcBot:IsChanneling() then
		return;
	end
	
	local EnemyHeroes = npcBot:GetNearbyHeroes( herosearchradius,true,BOT_MODE_NONE );
	local EnemyCreeps = npcBot:GetNearbyCreeps( creepsearchradius, true )		
	local NeutralCreeps= npcBot:GetNearbyNeutralCreeps( creepsearchradius );
	


--	if oldmode ~= npcBot:GetActiveMode() then
--		oldmode=npcBot:GetActiveMode();
--		if oldmode==BOT_MODE_NONE then
--			print("---------------------> ",npcBot:GetUnitName()," BOT_MODE_NONE");
--		elseif oldmode==BOT_MODE_LANING then
--			print("---------------------> ",npcBot:GetUnitName()," BOT_MODE_LANING");
--		elseif oldmode==BOT_MODE_ATTACK then
--			print("---------------------> ",npcBot:GetUnitName()," BOT_MODE_ATTACK");
--		elseif oldmode==BOT_MODE_ROAM then
--			print("---------------------> ",npcBot:GetUnitName()," BOT_MODE_ROAM");
--		elseif oldmode==BOT_MODE_RETREAT then
--			print("---------------------> ",npcBot:GetUnitName()," BOT_MODE_RETREAT");
--		elseif oldmode==BOT_MODE_SECRET_SHOP then
--			print("---------------------> ",npcBot:GetUnitName()," BOT_MODE_SECRET_SHOP");
--		elseif oldmode==BOT_MODE_SIDE_SHOP then
--			print("---------------------> ",npcBot:GetUnitName()," BOT_MODE_SIDE_SHOP");
--		elseif oldmode==BOT_MODE_PUSH_TOWER_TOP then
--			print("---------------------> ",npcBot:GetUnitName()," BOT_MODE_PUSH_TOWER_TOP");
--		elseif oldmode==BOT_MODE_PUSH_TOWER_MID then
--			print("---------------------> ",npcBot:GetUnitName()," BOT_MODE_PUSH_TOWER_MID");
--		elseif oldmode==BOT_MODE_PUSH_TOWER_BOT then
--			print("---------------------> ",npcBot:GetUnitName()," BOT_MODE_PUSH_TOWER_BOT");
--		elseif oldmode==BOT_MODE_DEFEND_TOWER_TOP then
--			print("---------------------> ",npcBot:GetUnitName()," BOT_MODE_DEFEND_TOWER_TOP");
--		elseif oldmode==BOT_MODE_DEFEND_TOWER_MID then
--			print("---------------------> ",npcBot:GetUnitName()," BOT_MODE_DEFEND_TOWER_MID");
--		elseif oldmode==BOT_MODE_DEFEND_TOWER_BOT then
--			print("---------------------> ",npcBot:GetUnitName()," BOT_MODE_DEFEND_TOWER_BOT");
--		elseif oldmode==BOT_MODE_ASSEMBLE then
--			print("---------------------> ",npcBot:GetUnitName()," BOT_MODE_ASSEMBLE");
--		elseif oldmode==BOT_MODE_TEAM_ROAM then
--			print("---------------------> ",npcBot:GetUnitName()," BOT_MODE_TEAM_ROAM");
--		elseif oldmode==BOT_MODE_FARM then
--			print("---------------------> ",npcBot:GetUnitName()," BOT_MODE_FARM");
--		elseif oldmode==BOT_MODE_DEFEND_ALLY then
--			print("---------------------> ",npcBot:GetUnitName()," BOT_MODE_DEFEND_ALLY");
--		elseif oldmode==BOT_MODE_EVASIVE_MANEUVERS then
--			print("---------------------> ",npcBot:GetUnitName()," BOT_MODE_EVASIVE_MANEUVERS");
--		elseif oldmode==BOT_MODE_ROSHAN then
--			print("---------------------> ",npcBot:GetUnitName()," BOT_MODE_ROSHAN");
--		elseif oldmode==BOT_MODE_ITEM then
--			print("---------------------> ",npcBot:GetUnitName()," BOT_MODE_ITEM");
--		elseif oldmode==BOT_MODE_WARD then
--			print("---------------------> ",npcBot:GetUnitName()," BOT_MODE_WARD");
--		else
--			print("---------------------> ",npcBot:GetUnitName()," Unknown Bot Mode????");
--		end
--	end

--	if EnemyHeroes~=nil or #EnemyHeroes~=0 then
--	if not Duels.currentDuel or Duels.currentDuel == DUEL_IS_STARTING then 
	local freakoutvalue
	if #EnemyHeroes~=0 then
		freakoutvalue=0.15	--would make higher if I could tell when I'm duelling or not.
	else
		freakoutvalue=0.30
	end
	if npcBot:GetHealth()/npcBot:GetMaxHealth()<freakoutvalue then
		npcBot.IsRetreating= true;
		retreattime = DotaTime()+5;
		SwitchCamp()
		if DotaTime() > stopmessage then
			print("---------------------> ",npcBot:GetUnitName()," is running for their life.");
			stopmessage=DotaTime()+7;
		end

		if npcBot:GetTeam() == TEAM_RADIANT then
			npcBot:Action_MoveToLocation(RadiantBase);
			return;
		else
			npcBot:Action_MoveToLocation(DireBase);
			return;
		end
	end
	if npcBot.IsRetreating == true then
		if npcBot:GetHealth()/npcBot:GetMaxHealth()>0.30 then
			npcBot.IsRetreating = false
			print("---------------------> ",npcBot:GetUnitName()," is not Retreating any more");
			return;
		end
		if npcBot:GetTeam() == TEAM_RADIANT then
			npcBot:Action_MoveToLocation(RadiantBase);
			return;
		else
			npcBot:Action_MoveToLocation(DireBase);
			return;
		end
	elseif retreattime > DotaTime() then
--		if DotaTime() > stopmessage then
--			print("---------------------> ",npcBot:GetUnitName()," retreattime");
--			stopmessage=DotaTime()+7;
--		end
		return;
	end
	if #EnemyHeroes~=0 then
		
--		if DotaTime() > stopmessage then
--			print("---------------------> ",npcBot:GetUnitName()," is attacking");
--			stopmessage=DotaTime()+15;
--		end
		
		local WeakestHero=nil;
		LowestHealth=10000;
--		npcBot:ActionImmediate_Chat("EnemyHeroes~=nil", false);
--		print("--> "..npcBot:GetUnitName().."EnemyHeroes~=nil");
		for _,hero in pairs(EnemyHeroes) do
			if hero~=nil and hero:IsAlive() then
				if hero:GetHealth()<LowestHealth then
					LowestHealth=hero:GetHealth();
					WeakestHero=hero;
				end
			end
		end
		
		local WeakestHeroLocation = WeakestHero:GetLocation();
		--DOTA_UNIT_TARGET_TEAM_ENEMY
		--DOTA_UNIT_TARGET_TEAM_BOTH 
		--DOTA_UNIT_TARGET_HERO 
		--DOTA_UNIT_TARGET_CREEP 
--		local spellList = {};
		
		--print ("---------------------> ",GetBot():GetUnitName(),"used spell number",hAbility:GetAbilityName());
		if spellwait < DotaTime() then
--			print ("---------------------> ",GetBot():GetUnitName(),"spellwait < DotaTime1");
			currentspell= currentspell+1;
			if currentspell > 2 then
				currentspell = 0;
--				print ("---------------------> ",GetBot():GetUnitName(),"currentspell = 0a");
			end
--			local spell = npcBot:GetAbility( currentspell )
			local hAbility = npcBot:GetAbilityInSlot(currentspell)
			if hAbility and not hAbility:IsPassive() and not hAbility:IsToggle() and hAbility:GetLevel() > 0 then
			
--				print ("---------------------> ",GetBot():GetUnitName(),"hAbility and not spell:IsPassive1",currentspell);
				if hAbility:IsFullyCastable() then
					print ("---------------------> ",GetBot():GetUnitName(),"IsFullyCastable: ",currentspell);
					
--					local hAbilityName = hAbility:GetAbilityName();
--					local hAbilityName = tostring(hAbility:GetAbilityName());
--					local abilityIndex = npcBot:GetAbilityByIndex(currentspell);
--					local abilityName = abilityIndex:GetAbilityName();
					local abilityName = hAbility:GetName();
					local testing = hAbility:GetBehavior();
--					print ("---------------------> ",GetBot():GetUnitName(),"GetBehavior:",testing);

--					if hAbility:GetBehavior() % 8 then
					if bit.band(hAbility:GetBehavior(), DOTA_ABILITY_BEHAVIOR_UNIT_TARGET ) then
						print ("---------------------> ",GetBot():GetUnitName(),"DOTA_ABILITY_BEHAVIOR_UNIT_TARGET:",currentspell);
--						if bit.band(hAbility.CDOTABaseAbility:GetAbilityTargetTeam(), DOTA_UNIT_TARGET_TEAM_ENEMY ) or bit.band(hAbility.CDOTABaseAbility:GetAbilityTargetTeam(), DOTA_UNIT_TARGET_TEAM_BOTH ) then
--						print ("---------------------> ",GetBot():GetUnitName(),"DOTA_UNIT_TARGET_TEAM_ENEMY:",currentspell);
						npcBot:Action_UseAbilityOnEntity(hAbility,WeakestHero);
						spellwait = DotaTime()+.5;
						print ("---------------------> ",GetBot():GetUnitName(),"used spell number:",currentspell);
						return;
					elseif bit.band(hAbility:GetBehavior(), DOTA_ABILITY_BEHAVIOR_AOE ) then
						print ("---------------------> ",GetBot():GetUnitName(),"DOTA_ABILITY_BEHAVIOR_AOE:",currentspell);
						local weakestdistance = GetUnitToUnitDistance(WeakestHero, npcBot);
						if weakestdistance < 100 then
							print ("---------------------> ",GetBot():GetUnitName(),"AOE spell not used because distance:",weakestdistance);
							npcBot:Action_UseAbility(hAbility);
							spellwait = DotaTime()+.5;
							print ("---------------------> ",GetBot():GetUnitName(),"used spell number:",currentspell);
							return;
						else
							npcBot:Action_AttackUnit(WeakestHero,true);
						end
					elseif bit.band(hAbility:GetBehavior(), DOTA_ABILITY_BEHAVIOR_NO_TARGET ) or bit.band(hAbility:GetBehavior(), DOTA_ABILITY_BEHAVIOR_POINT ) then
						print ("---------------------> ",GetBot():GetUnitName(),"DOTA_ABILITY_BEHAVIOR_NO_TARGET:",currentspell);
						
						--if hAbility:GetAbilityTargetTeam() == DOTA_UNIT_TARGET_TEAM_ENEMY or hAbility:GetAbilityTargetTeam() == DOTA_UNIT_TARGET_TEAM_BOTH then
--						if bit.band(hAbility.CDOTABaseAbility:GetAbilityTargetTeam(), DOTA_UNIT_TARGET_TEAM_ENEMY ) or bit.band(hAbility.CDOTABaseAbility:GetAbilityTargetTeam(), DOTA_UNIT_TARGET_TEAM_BOTH ) then
						print ("---------------------> ",GetBot():GetUnitName(),"DOTA_ABILITY_BEHAVIOR_NO_TARGET or POINT:",currentspell);
						npcBot:Action_UseAbilityOnLocation(hAbility,WeakestHeroLocation);
						spellwait = DotaTime()+.5;
						print ("---------------------> ",GetBot():GetUnitName(),"used spell number:",currentspell);
						return;

					end
				end
			end
		end
		npcBot:Action_AttackUnit(WeakestHero,true);
		return;
	elseif #EnemyCreeps~=0 then 
		WeakestCreep=nil;
		LowestHealth=10000;
--		npcBot:ActionImmediate_Chat("EnemyCreeps~=nil", false);
--		print("--> "..npcBot:GetUnitName().."EnemyCreeps~=nil");
		for _,creep in pairs(EnemyCreeps) do
			if creep~=nil and creep:IsAlive() then
				if creep:GetHealth()<LowestHealth then
					LowestHealth=creep:GetHealth();
					WeakestCreep=creep;
				end
			end
		end
		
		local WeakestCreepLocation = WeakestCreep:GetLocation();
		--DOTA_UNIT_TARGET_TEAM_ENEMY
		--DOTA_UNIT_TARGET_TEAM_BOTH 
		--DOTA_UNIT_TARGET_HERO 
		--DOTA_UNIT_TARGET_CREEP 
--		local spellList = {};
		
		--print ("---------------------> ",GetBot():GetUnitName(),"used spell number",hAbility:GetAbilityName());
		if spellwait < DotaTime() then
--			print ("---------------------> ",GetBot():GetUnitName(),"spellwait < DotaTime1");
			currentspell= currentspell+1;
			if currentspell > 2 then
				currentspell = 0;
--				print ("---------------------> ",GetBot():GetUnitName(),"currentspell = 0a");
			end
--			local spell = npcBot:GetAbility( currentspell )
			local hAbility = npcBot:GetAbilityInSlot(currentspell)
			if hAbility and not hAbility:IsPassive() and not hAbility:IsToggle() and hAbility:GetLevel() > 0 then
			
--				print ("---------------------> ",GetBot():GetUnitName(),"hAbility and not spell:IsPassive1",currentspell);
				if hAbility:IsFullyCastable() then
					print ("---------------------> ",GetBot():GetUnitName(),"IsFullyCastable: ",currentspell);
					
--					local hAbilityName = hAbility:GetAbilityName();
--					local hAbilityName = tostring(hAbility:GetAbilityName());
--					local abilityIndex = npcBot:GetAbilityByIndex(currentspell);
--					local abilityName = abilityIndex:GetAbilityName();
					local abilityName = hAbility:GetName();
					local testing = hAbility:GetBehavior();
--					print ("---------------------> ",GetBot():GetUnitName(),"GetBehavior:",testing);

--					if hAbility:GetBehavior() % 8 then
					if bit.band(hAbility:GetBehavior(), DOTA_ABILITY_BEHAVIOR_UNIT_TARGET ) then
						print ("---------------------> ",GetBot():GetUnitName(),"DOTA_ABILITY_BEHAVIOR_UNIT_TARGET:",currentspell);
--						if bit.band(hAbility.CDOTABaseAbility:GetAbilityTargetTeam(), DOTA_UNIT_TARGET_TEAM_ENEMY ) or bit.band(hAbility.CDOTABaseAbility:GetAbilityTargetTeam(), DOTA_UNIT_TARGET_TEAM_BOTH ) then
--						print ("---------------------> ",GetBot():GetUnitName(),"DOTA_UNIT_TARGET_TEAM_ENEMY:",currentspell);
						npcBot:Action_UseAbilityOnEntity(hAbility,WeakestCreep);
						spellwait = DotaTime()+.5;
						print ("---------------------> ",GetBot():GetUnitName(),"used spell number:",currentspell);
						return;
					elseif bit.band(hAbility:GetBehavior(), DOTA_ABILITY_BEHAVIOR_AOE ) then
						print ("---------------------> ",GetBot():GetUnitName(),"DOTA_ABILITY_BEHAVIOR_AOE:",currentspell);
						local weakestdistance = GetUnitToUnitDistance(WeakestCreep, npcBot);
						if weakestdistance < 100 then
							print ("---------------------> ",GetBot():GetUnitName(),"AOE spell not used because distance:",weakestdistance);
							npcBot:Action_UseAbility(hAbility);
							spellwait = DotaTime()+.5;
							print ("---------------------> ",GetBot():GetUnitName(),"used spell number:",currentspell);
							return;
						else
							npcBot:Action_AttackUnit(WeakestCreep,true);
						end
					elseif bit.band(hAbility:GetBehavior(), DOTA_ABILITY_BEHAVIOR_NO_TARGET ) or bit.band(hAbility:GetBehavior(), DOTA_ABILITY_BEHAVIOR_POINT ) then
						print ("---------------------> ",GetBot():GetUnitName(),"DOTA_ABILITY_BEHAVIOR_NO_TARGET:",currentspell);
						
						--if hAbility:GetAbilityTargetTeam() == DOTA_UNIT_TARGET_TEAM_ENEMY or hAbility:GetAbilityTargetTeam() == DOTA_UNIT_TARGET_TEAM_BOTH then
--						if bit.band(hAbility.CDOTABaseAbility:GetAbilityTargetTeam(), DOTA_UNIT_TARGET_TEAM_ENEMY ) or bit.band(hAbility.CDOTABaseAbility:GetAbilityTargetTeam(), DOTA_UNIT_TARGET_TEAM_BOTH ) then
						print ("---------------------> ",GetBot():GetUnitName(),"DOTA_ABILITY_BEHAVIOR_NO_TARGET or POINT:",currentspell);
						npcBot:Action_UseAbilityOnLocation(hAbility,WeakestCreepLocation);
						spellwait = DotaTime()+.5;
						print ("---------------------> ",GetBot():GetUnitName(),"used spell number:",currentspell);
						return;

					end
				end
			end
		end
		npcBot:Action_AttackUnit(WeakestCreep,true);
		return;
	elseif #NeutralCreeps~=0 then
	
		print("---------------------> ",npcBot:GetUnitName()," Neutral Creeps???");
		WeakestCreep=nil;
		LowestHealth=10000;
--		npcBot:ActionImmediate_Chat("NeutralCreeps~=nil", false);
--		print("--> "..npcBot:GetUnitName().."NeutralCreeps~=nil");
		for _,creep in pairs(NeutralCreeps) do
			if creep~=nil and creep:IsAlive() then
				if creep:GetHealth()<LowestHealth then
					LowestHealth=creep:GetHealth();
					WeakestCreep=creep;
				end
			end
		end
		npcBot:Action_AttackUnit(WeakestCreep,true);
		return;
	elseif DotaTime() > 0 then
		if GetUnitToLocationDistance( npcBot, CurrentCamp ) > 200 then
			npcBot:Action_AttackMove (CurrentCamp)
			npcBot:Action_MoveToLocation (CurrentCamp)
		else
			if DotaTime() > runtime then --or npcBot:GetCurrentActionType() == BOT_ACTION_TYPE_IDLE or npcBot:GetCurrentActionType() == BOT_ACTION_TYPE_NONE then --
				if DotaTime() > stopmessage then
					print("---------------------> ",npcBot:GetUnitName()," runtime is ",runtime," Dota time is ",DotaTime());
					stopmessage=DotaTime()+2;
				end
				SwitchCamp()

				npcBot:Action_AttackMove (CurrentCamp)
				npcBot:Action_MoveToLocation (CurrentCamp)
--				return;
			end
		end
	end
end





--------
for k,v in pairs( mode_generic_laning ) do	_G._savedEnv[k] = v end
