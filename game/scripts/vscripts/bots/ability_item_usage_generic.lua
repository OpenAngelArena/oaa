local itemnumber = 0
local FirstAbility = 0
local SecondAbility = 1
local bOnce = false




----------------------------------------------------------------------------
---	My Functions
----------------------------------------------------------------------------




local function RunOnce()
	local npcBot=GetBot()
	
--	print("--> ",npcBot:GetUnitName()," run once")
	bOnce = true
	local npcBot=GetBot()
	if npcBot:GetUnitName() == "npc_dota_hero_axe" then
		FirstAbility = 2
		SecondAbility = 0
	elseif npcBot:GetUnitName() == "npc_dota_hero_bane" then
		FirstAbility = 1
		SecondAbility = 2
	elseif npcBot:GetUnitName() == "npc_dota_hero_bounty_hunter" then
		FirstAbility = 0
		SecondAbility = 1
	elseif npcBot:GetUnitName() == "npc_dota_hero_bristleback" then
		FirstAbility = 1
		SecondAbility = 2
	elseif npcBot:GetUnitName() == "npc_dota_hero_bloodseeker" then
		FirstAbility = 1
		SecondAbility = 0
	elseif npcBot:GetUnitName() == "npc_dota_hero_chaos_knight" then
		FirstAbility = 1
		SecondAbility = 2
	elseif npcBot:GetUnitName() == "npc_dota_hero_crystal_maiden" then
		FirstAbility = 0
		SecondAbility = 1
	elseif npcBot:GetUnitName() == "npc_dota_hero_dazzle" then
		FirstAbility = 2
		SecondAbility = 0
	elseif npcBot:GetUnitName() == "npc_dota_hero_death_prophet" then
		FirstAbility = 0
		SecondAbility = 2
	elseif npcBot:GetUnitName() == "npc_dota_hero_dragon_knight" then
		FirstAbility = 0
		SecondAbility = 2
	elseif npcBot:GetUnitName() == "npc_dota_hero_drow_ranger" then
		FirstAbility = 2
		SecondAbility = 1
	elseif npcBot:GetUnitName() == "npc_dota_hero_earthshaker" then
		FirstAbility = 0
		SecondAbility = 1
	elseif npcBot:GetUnitName() == "npc_dota_hero_jakiro" then
		FirstAbility = 0
		SecondAbility = 2
	elseif npcBot:GetUnitName() == "npc_dota_hero_juggernaut" then
		FirstAbility = 1
		SecondAbility = 0
	elseif npcBot:GetUnitName() == "npc_dota_hero_kunkka" then
		FirstAbility = 0
		SecondAbility = 1
	elseif npcBot:GetUnitName() == "npc_dota_hero_lich" then
		FirstAbility = 0
		SecondAbility = 1
	elseif npcBot:GetUnitName() == "npc_dota_hero_lina" then
		FirstAbility = 0
		SecondAbility = 1
	elseif npcBot:GetUnitName() == "npc_dota_hero_lion" then
		FirstAbility = 0
		SecondAbility = 2
	elseif npcBot:GetUnitName() == "npc_dota_hero_luna" then
		FirstAbility = 1
		SecondAbility = 0
	elseif npcBot:GetUnitName() == "npc_dota_hero_necrolyte" then
		FirstAbility = 0
		SecondAbility = 2
	elseif npcBot:GetUnitName() == "npc_dota_hero_omniknight" then
		FirstAbility = 0
		SecondAbility = 2
	elseif npcBot:GetUnitName() == "npc_dota_hero_oracle" then
		FirstAbility = 0
		SecondAbility = 2
	elseif npcBot:GetUnitName() == "npc_dota_hero_phantom_assassin" then
		FirstAbility = 1
		SecondAbility = 2
	elseif npcBot:GetUnitName() == "npc_dota_hero_pudge" then
		FirstAbility = 0 -- 1 if he can use rot
		SecondAbility = 1
	elseif npcBot:GetUnitName() == "npc_dota_hero_razor" then
		FirstAbility = 0
		SecondAbility = 2
	elseif npcBot:GetUnitName() == "npc_dota_hero_riki" then
		FirstAbility = 2
		SecondAbility = 1
	elseif npcBot:GetUnitName() == "npc_dota_hero_sand_king" then
		FirstAbility = 0
		SecondAbility = 1
	elseif npcBot:GetUnitName() == "npc_dota_hero_nevermore" then
		FirstAbility = 0
		SecondAbility = 1
	elseif npcBot:GetUnitName() == "npc_dota_hero_sniper" then
		FirstAbility = 0
		SecondAbility = 1
	elseif npcBot:GetUnitName() == "npc_dota_hero_skywrath_mage" then
		FirstAbility = 0
		SecondAbility = 2
	elseif npcBot:GetUnitName() == "npc_dota_hero_sven" then
		FirstAbility = 0
		SecondAbility = 1
	elseif npcBot:GetUnitName() == "npc_dota_hero_tidehunter" then
		FirstAbility = 2
		SecondAbility = 1
	elseif npcBot:GetUnitName() == "npc_dota_hero_tiny" then
		FirstAbility = 0
		SecondAbility = 1
	elseif npcBot:GetUnitName() == "npc_dota_hero_vengefulspirit" then
		FirstAbility = 1
		SecondAbility = 0
	elseif npcBot:GetUnitName() == "npc_dota_hero_viper" then
		FirstAbility = 0
		SecondAbility = 2
	elseif npcBot:GetUnitName() == "npc_dota_hero_warlock" then
		FirstAbility = 1
		SecondAbility = 0
	elseif npcBot:GetUnitName() == "npc_dota_hero_windrunner" then
		FirstAbility = 1
		SecondAbility = 2
	elseif npcBot:GetUnitName() == "npc_dota_hero_witch_doctor" then
		FirstAbility = 0
		SecondAbility = 1
	elseif npcBot:GetUnitName() == "npc_dota_hero_skeleton_king" then
		FirstAbility = 1
		SecondAbility = 2
	elseif npcBot:GetUnitName() == "npc_dota_hero_zuus" then
		FirstAbility = 0
		SecondAbility = 1
	else
		FirstAbility = 0
		SecondAbility = 1
	end
end




local function LevelUp()
	local npcBot=GetBot()

	local hAbility
	--First try Ultimate
	for abilityIndex = 3,9,1 do
		hAbility = npcBot:GetAbilityInSlot( abilityIndex )
		if hAbility ~= nil then
			if hAbility:IsUltimate() and hAbility:CanAbilityBeUpgraded() then
				npcBot:ActionImmediate_LevelAbility (hAbility:GetName())
--				print("--> ",npcBot:GetUnitName()," levelled up ",hAbility:GetName()," at level ",npcBot:GetLevel())
			end
		end
	end
	if npcBot:GetAbilityPoints() <= 0 then
		return
	end
	--Then try Talents: Slot 10+ = Talents
	for abilityIndex = 9,23,1 do
		hAbility = npcBot:GetAbilityInSlot( abilityIndex )
		if hAbility ~= nil then
			if hAbility:CanAbilityBeUpgraded() then
				npcBot:ActionImmediate_LevelAbility (hAbility:GetName())
--				print("--> ",npcBot:GetUnitName()," levelled up Ultimate: ",hAbility:GetName()," at level ",npcBot:GetLevel())
			end
		end
	end
	if npcBot:GetAbilityPoints() <= 0 then
		return
	end
	--Then try maxing the first skill - usually a nuke
	hAbility = npcBot:GetAbilityInSlot( FirstAbility )
	if hAbility:CanAbilityBeUpgraded() then
		npcBot:ActionImmediate_LevelAbility (hAbility:GetName())
--		print("--> ",npcBot:GetUnitName()," levelled up FirstAbility: ",hAbility:GetName()," at level ",npcBot:GetLevel())
	end
	if npcBot:GetAbilityPoints() <= 0 then
		return
	end
	--Second Ability +1
--	if SecondAbility ~= -1 then
	hAbility = npcBot:GetAbilityInSlot( SecondAbility )
	if hAbility:CanAbilityBeUpgraded() and hAbility:GetLevel() <= 0 then
		npcBot:ActionImmediate_LevelAbility (hAbility:GetName())
--		print("--> ",npcBot:GetUnitName()," levelled up SecondAbility: ",hAbility:GetName()," at level ",npcBot:GetLevel())
	end
--	end
	if npcBot:GetAbilityPoints() <= 0 then
		return
	end
	--Other skills +1
	for abilityIndex = 0,9,1 do
		hAbility = npcBot:GetAbilityInSlot( abilityIndex )
		if hAbility:GetLevel() <= 0 then
			if hAbility:CanAbilityBeUpgraded() then
				npcBot:ActionImmediate_LevelAbility (hAbility:GetName())
--				print("--> ",npcBot:GetUnitName()," levelled up 0 Level Ability: ",hAbility:GetName()," at level ",npcBot:GetLevel())
			end
		end
	end
	if npcBot:GetAbilityPoints() <= 0 then
		return
	end
	--Second skill maxed
--	if SecondAbility ~= -1 then
	hAbility = npcBot:GetAbilityInSlot( SecondAbility )
	if hAbility:CanAbilityBeUpgraded() then
		npcBot:ActionImmediate_LevelAbility (hAbility:GetName())
--		print("--> ",npcBot:GetUnitName()," levelled up Talent: ",hAbility:GetName()," at level ",npcBot:GetLevel())
	end
--	end
	if npcBot:GetAbilityPoints() <= 0 then
		return
	end
	--Finish up - upgrade anything and everything else that can be upgraded
	for abilityIndex = 0,23,1 do
		hAbility = npcBot:GetAbilityInSlot( abilityIndex )
		if hAbility ~= nil then
			if hAbility:CanAbilityBeUpgraded() then
				npcBot:ActionImmediate_LevelAbility (hAbility:GetName())
--				print("--> ",npcBot:GetUnitName()," levelled up Ability: ",hAbility:GetName()," at level ",npcBot:GetLevel())
			end
		end
	end
	return
end




----------------------------------------------------------------------------
---	Default Functions
----------------------------------------------------------------------------




function AbilityLevelUpThink()
	local npcBot=GetBot()
	
	if bOnce == false then 
		RunOnce()
	end
	if npcBot:GetAbilityPoints() > 0 then
		LevelUp()
	end
end




