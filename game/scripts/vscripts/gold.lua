--[[
  Author:
    Angel Arena Blackstars
    Chronophylos
  Credits:
    Angel Arena Blackstars
]]

PLAYER_GOLD = {
  [0] = {},
  [1] = {},
  [2] = {},
  [3] = {},
  [4] = {},
  [5] = {},
  [6] = {},
  [7] = {},
  [8] = {},
  [9] = {}
}


if Gold == nil then
  _G.Gold = class({})
end

function Gold:UpdatePlayerGold(unitvar)
  local playerID = UnitVarToPlayerID(unitvar)
  if playerID and playerID > -1 then
    local allgold = PlayerTables:GetTableValue("aaa", "gold")
    allgold[playerID] = PLAYER_GOLD[playerID].SavedGold
    PlayerTables:SetTableValue("aaa", "gold", allgold)
    local player = PlayerResource:GetPlayer(playerID)
    CustomGameEventManager:Send_ServerToAllClients("aaa_update_gold", { gold=allgold })
  end
end

function Gold:ClearGold(unitvar)
  Gold:SetGold(unitvar, 0)
end

function Gold:SetGold(unitvar, gold)
  local playerID = UnitVarToPlayerID(unitvar)
  PLAYER_GOLD[playerID].SavedGold = math.floor(gold)
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
  PLAYER_GOLD[playerID].SavedGold = math.max((PLAYER_GOLD[playerID].SavedGold or 0) - math.ceil(gold), 0)
  Gold:UpdatePlayerGold(playerID)
end

function Gold:AddGold(unitvar, gold)
  --[[DebugPrint("[Gold] AddGold")
  DebugPrint("arg.unitvar: " .. unitvar)
  DebugPrint("arg.gold: " .. gold)
  DebugPrintTable(PLAYER_GOLD)]]
  local playerID = UnitVarToPlayerID(unitvar)
  PLAYER_GOLD[playerID].SavedGold = (PLAYER_GOLD[playerID].SavedGold or 0) + math.floor(gold)
  Gold:UpdatePlayerGold(playerID)
end

function Gold:AddGoldWithMessage(unit, gold, optPlayerID)
  local player = optPlayerID and PlayerResource:GetPlayer(optPlayerID) or PlayerResource:GetPlayer(UnitVarToPlayerID(unit))
  SendOverheadEventMessage(player, OVERHEAD_ALERT_GOLD, unit, math.floor(gold), player)
  Gold:AddGold(optPlayerID or unit, gold)
end

function Gold:GetGold(unitvar)
  local playerID = UnitVarToPlayerID(unitvar)
  return math.floor(PLAYER_GOLD[playerID].SavedGold or 0)
end
