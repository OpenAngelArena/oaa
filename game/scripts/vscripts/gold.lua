--Created by: Angel Arena Black Star

require('libraries/playertables')

--[[## gold/tick ##
	created in AABS gamemode.lua:193 with a timer Timers:CreateTimer(CUSTOM_GOLD_TICK_TIME, Dynamic_Wrap(GameMode, "GameModeThink"))
	function GameMode:GameModeThink() in AABS gamemode.lua:265

	## Some gold globals in  settings.lua:152-155 ##
	CUSTOM_STARTING_GOLD = 625
	CUSTOM_GOLD_FOR_RANDOM_TOTAL = 1000
	CUSTOM_GOLD_PER_TICK = 4   
	CUSTOM_GOLD_TICK_TIME = 0.6

	## To do ##
	- Gold/tick + gold from abandonned teammates + gold/tick from talents (see reference above)
	- Shop
	- Creeps are killed + Alchemist & Doom their gold abilities
	- Heroes are killed + track from bounty hunter
	- Duel victory
	- Bounty rune
	- Hand of Midas

	- showing gold  bottomright (depends if your hero/teammate is selected) 
					scoreboard
]]

-- AABS /data/globals.lua
if not Globals_Initialized then
	Globals_Initialized = true
	PLAYER_DATA = {[0] = {}, [1] = {}, [2] = {}, [3] = {}, [4] = {}, [5] = {}, [6] = {}, [7] = {}, [8] = {}, [9] = {}, [10] = {}, [11] = {}, [12] = {}, [13] = {}, [14] = {}, [15] = {}, [16] = {}, [17] = {}, [18] = {}, [19] = {}, [20] = {}, [21] = {}, [22] = {}, [23] = {}}
end

-- function UnitVarToPlayerID(unitvar) -- AABS util.lua line 1020 - 1033
function UnitVarToPlayerID(unitvar)
	if unitvar then
		if type(unitvar) == "number" then
			return unitvar
		elseif type(unitvar) == "table" and not unitvar:IsNull() and unitvar.entindex and unitvar:entindex() then
			if unitvar.GetPlayerID and unitvar:GetPlayerID() > -1 then
				return unitvar:GetPlayerID()
			elseif unitvar.GetPlayerOwnerID then
				return unitvar:GetPlayerOwnerID()
			end
		end
	end
	return -1
end

-- AABS gold.lua
if Gold == nil then
	_G.Gold = class({})
end

function Gold:UpdatePlayerGold(unitvar)
	-- added to make this work from AABS gamemode.lua:212
	if not PlayerTables:TableExists("arena") then
		PlayerTables:CreateTable("arena", { gold = {} }, {0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23})
	end

	local playerID = UnitVarToPlayerID(unitvar)
	if playerID and playerID > -1 then
		PlayerResource:SetGold(playerID, 0, false)
		local allgold = PlayerTables:GetTableValue("arena", "gold")
		allgold[playerID] = PLAYER_DATA[playerID].SavedGold
		PlayerTables:SetTableValue("arena", "gold", allgold)
	end
end

function Gold:ClearGold(unitvar)
	Gold:SetGold(unitvar, 0)
end

function Gold:SetGold(unitvar, gold)
	local playerID = UnitVarToPlayerID(unitvar)
	PLAYER_DATA[playerID].SavedGold = math.floor(gold)
	Gold:UpdatePlayerGold(playerID)
end

function Gold:ModifyGold(unitvar, gold, bReliable, iReason)
	if gold > 0 then
		Gold:AddGold(unitvar, gold)
	elseif gold < 0 then
		Gold:RemoveGold(unitvar, -gold)
	end
end

function Gold:RemoveGold(unitvar, gold)
	local playerID = UnitVarToPlayerID(unitvar)
	PLAYER_DATA[playerID].SavedGold = math.max((PLAYER_DATA[playerID].SavedGold or 0) - math.ceil(gold), 0)
	Gold:UpdatePlayerGold(playerID)
end

function Gold:AddGold(unitvar, gold)
	local playerID = UnitVarToPlayerID(unitvar)
	PLAYER_DATA[playerID].SavedGold = (PLAYER_DATA[playerID].SavedGold or 0) + math.floor(gold)
	Gold:UpdatePlayerGold(playerID)
end

function Gold:AddGoldWithMessage(unit, gold, optPlayerID)
	local player = optPlayerID and PlayerResource:GetPlayer(optPlayerID) or PlayerResource:GetPlayer(UnitVarToPlayerID(unit))
	SendOverheadEventMessage(player, OVERHEAD_ALERT_GOLD, unit, math.floor(gold), player)
	Gold:AddGold(optPlayerID or unit, gold)
end

function Gold:GetGold(unitvar)
	local playerID = UnitVarToPlayerID(unitvar)
	return math.floor(PLAYER_DATA[playerID].SavedGold or 0)
end