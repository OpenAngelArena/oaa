--[[
  Author:
    Angel Arena Blackstars
    Chronophylos
  Credits:
    Angel Arena Blackstars
]]


if Gold == nil then
  DebugPrint ( 'creating new Gold object' )
  Debug.EnabledModules["gold:*"] = false
  _G.Gold = class({})
end

local GOLD_CAP = 50000

function Gold:Init()
  -- a table for every player
  PlayerTables:CreateTable("gold", {
    gold = {}
  }, {0,1,2,3,4,5,6,7,8,9})

  ChatCommand:LinkCommand(
    "-goldc",
    "Interact with the Gold API",
    "Usage: -goldc [(add <amount> | set <amount> | remove <amount> | modify <amount> | clear) [PlayerID] | help]",
    ACCESSLEVEL_ADMIN,
    "handleChatCommand", Gold
  )

    -- start think timer
  Timers:CreateTimer(1, Dynamic_Wrap(Gold, "Think"))
end

function Gold:handleChatCommand (keys)
  local action = keys.command[2]
  local arg = tonumber(keys.command[3])
  local playerid = tonumber(keys.command[4]) or keys.playerid
  if not PlayerResource:IsValidPlayerID(playerid) then
    playerid = keys.playerid
  end

  if action == "add" then
    Gold:AddGold(playerid, arg)
  elseif action == "set" and arg then
    Gold:SetGold(playerid, arg)
  elseif action == "remove" then
    Gold:RemoveGold(playerid, arg)
  elseif action == "modify" then
    Gold:ModifyGold(playerid, arg)
  elseif action == "clear" then
    Gold:ClearGold(playerid)
  else
    ChatCommand:displayUsage(keys.command[1])
  end
end

function Gold:UpdatePlayerGold(unitvar, newGold)
  local playerID = UnitVarToPlayerID(unitvar)
  if playerID and playerID > -1 then
    local tableGold = PlayerTables:GetTableValue("gold", "gold")
    tableGold[playerID] = newGold
    PlayerTables:SetTableValue("gold", "gold", tableGold)
  end
end

--[[
  Author:
    Chronophylos
  Credits:
    Angel Arena Blackstar
  Description:
    Add Gold to all players via our custom Gold API
]]
function Gold:Think()
  for i = 0, 9 do
    if PlayerResource:IsValidPlayerID(i) then
      if GameRules:State_Get() == DOTA_GAMERULES_STATE_GAME_IN_PROGRESS then
        -- WORKAROUND!! PLS ADD CUSTOM SHOP !! !!
        local currentGold = Gold:GetGold(i)
        local currentDotaGold = PlayerResource:GetGold(i)

        local newGold = currentGold
        local newDotaGold = currentDotaGold

        if currentGold > GOLD_CAP then
          newGold = currentGold + currentDotaGold - GOLD_CAP
        else
          newGold = currentDotaGold
        end

        if newGold > GOLD_CAP then
          newDotaGold = GOLD_CAP
        else
          newDotaGold = newGold
        end

        if newGold ~= currentGold or newDotaGold ~= currentDotaGold then
          Gold:SetGold(i, newGold)
          PlayerResource:SetGold(i, newDotaGold, false)
          PlayerResource:SetGold(i, 0, true)
        end
      end
    end
  end
  return 0.2
end


function Gold:ClearGold(unitvar)
  DebugPrint("Clearing Gold of " .. unitvar)
  Gold:SetGold(unitvar, 0)
end

function Gold:SetGold(unitvar, gold)
  DebugPrint("Set Gold of " .. unitvar .. " to " .. gold)
  local playerID = UnitVarToPlayerID(unitvar)
  local newGold = math.floor(gold)
  Gold:UpdatePlayerGold(playerID, newGold)
end

function Gold:ModifyGold(unitvar, gold, bReliable, iReason)
  DebugPrint("Modify Gold of " .. unitvar .. " by " .. gold)
  if gold > 0 then
    Gold:AddGold(unitvar, gold)
  elseif gold < 0 then
    Gold:RemoveGold(unitvar, -gold)
  end
end

function Gold:RemoveGold(unitvar, gold)
  DebugPrint("Remove " .. gold .. " from " .. unitvar)
  local playerID = UnitVarToPlayerID(unitvar)
  local oldGold = PlayerTables:GetTableValue("gold", "gold")[playerID]
  local newGold = math.max((oldGold or 0) - math.ceil(gold), 0)
  Gold:UpdatePlayerGold(playerID, newGold)
end

function Gold:AddGold(unitvar, gold)
  DebugPrint("Add " .. gold .. " to " .. unitvar)
  local playerID = UnitVarToPlayerID(unitvar)
  local oldGold = PlayerTables:GetTableValue("gold", "gold")[playerID]
  local newGold = (oldGold or 0) + math.floor(gold)
  Gold:UpdatePlayerGold(playerID, newGold)
end

function Gold:AddGoldWithMessage(unit, gold, optPlayerID)
  local player = optPlayerID and PlayerResource:GetPlayer(optPlayerID) or PlayerResource:GetPlayer(UnitVarToPlayerID(unit))
  SendOverheadEventMessage(player, OVERHEAD_ALERT_GOLD, unit, math.floor(gold), player)
  Gold:AddGold(optPlayerID or unit, gold)
end

function Gold:GetGold(unitvar)
  local playerID = UnitVarToPlayerID(unitvar)
  local currentGold = PlayerTables:GetTableValue("gold", "gold")[playerID]
  return math.floor(currentGold or 0)
end
