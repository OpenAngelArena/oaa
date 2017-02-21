--[[
  Author:
    Angel Arena Blackstars
    Chronophylos
  Credits:
    Angel Arena Blackstars
]]


if Gold == nil then
  DebugPrint( '[gold/gold] Creating new Gold object.' )
  _G.Gold = class({})
end


function Gold:Init ( )
  DebugPrint( '[gold/gold] Initializing..' )
  Gold.GoldCap = 50000
  -- a table for every player
  PlayerTables:CreateTable( 'gold',
                            { gold = {} },
                            {0,1,2,3,4,5,6,7,8,9} )

  Gold.debuggingEnabled = false

    -- start think timer
  Timers:CreateTimer( 0, Dynamic_Wrap( Gold, 'Think' ) )
end

function Gold:DebugPrint ( args )
  if Gold.debuggingEnabled then
    DebugPrint( args )
  end
end

function Gold:DebugPrintTable ( args )
  if Gold.debuggingEnabled then
    DebugPrintTable( args )
  end
end

function Gold:UpdatePlayerGold ( unitvar, newGold )
  local playerID = UnitVarToPlayerID( unitvar )

  if playerID and playerID > -1 then
    local tableGold = PlayerTables:GetTableValue( 'gold', 'gold' )

    tableGold[playerID] = newGold

    PlayerTables:SetTableValue( 'gold', 'gold', tableGold )
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
function Gold:Think ( )
  Gold:DebugPrint( '[gold/gold] Thinking..' )

  if GameRules:State_Get() == DOTA_GAMERULES_STATE_GAME_IN_PROGRESS then
    for player = 0, 9 do
      if PlayerResource:IsValidPlayerID( player ) then
        local currentGold = Gold:GetGold( player )
        local currentDotaGold = PlayerResource:GetGold( player )

        local newGold = currentGold
        local newDotaGold = currentDotaGold

        if currentGold > Gold.GoldCap then
          newGold = currentGold + currentDotaGold - Gold.GoldCap
        else
          newGold = currentDotaGold
        end

        if newGold > Gold.GoldCap then
          newDotaGold = Gold.GoldCap
        else
          newDotaGold = newGold
        end

        if newGold ~= currentGold or newDotaGold ~= currentDotaGold then
          Gold:SetGold( player, newGold )
          PlayerResource:SetGold( player, newDotaGold, false )
        end
      end
    end
  end

  return 0.2
end


function Gold:ClearGold ( unitvar )
  Gold:SetGold( unitvar, 0 )
end

function Gold:SetGold ( unitvar, gold )
  Gold:DebugPrint( '[gold/gold] SetGold' )

  local playerID = UnitVarToPlayerID( unitvar )
  local oldGold = PlayerTables:GetTableValue( 'gold', 'gold' )[playerID]
  local newGold = math.floor( gold )

  Gold:DebugPrint( 'playerID: ' .. playerID )
  Gold:DebugPrint( 'oldGold: ' .. oldGold )
  Gold:DebugPrint( 'newGold: ' .. newGold )

  Gold:UpdatePlayerGold( playerID, newGold )
end

function Gold:ModifyGold ( unitvar, gold, bReliable, iReason )
  if gold > 0 then
    Gold:AddGold( unitvar, gold )
  elseif gold < 0 then
    Gold:RemoveGold( unitvar, -gold )
  end
end

function Gold:RemoveGold ( unitvar, gold )
  Gold:DebugPrint( '[gold/gold] RemoveGold' )

  local playerID = UnitVarToPlayerID( unitvar )
  local oldGold = PlayerTables:GetTableValue( 'gold', 'gold' )[playerID]
  local newGold = math.max( (oldGold or 0) - math.ceil( gold ), 0)

  Gold:DebugPrint( 'playerID: ' .. playerID )
  Gold:DebugPrint( 'oldGold: ' .. oldGold )
  Gold:DebugPrint( 'newGold: ' .. newGold )

  Gold:UpdatePlayerGold( playerID, newGold )
end

function Gold:AddGold ( unitvar, gold )
  Gold:DebugPrint( '[gold/gold] AddGold' )

  local playerID = UnitVarToPlayerID( unitvar )
  local oldGold = PlayerTables:GetTableValue( 'gold', 'gold' )[playerID]
  local newGold = (oldGold or 0) + math.floor( gold )

  Gold:DebugPrint( 'playerID: ' .. playerID )
  Gold:DebugPrint( 'oldGold: ' .. oldGold )
  Gold:DebugPrint( 'newGold: ' .. newGold )

  Gold:UpdatePlayerGold( playerID, newGold )
end

function Gold:AddGoldWithMessage ( unit, gold, optPlayerID )
  local player = optPlayerID and PlayerResource:GetPlayer( optPlayerID ) or PlayerResource:GetPlayer( UnitVarToPlayerID( unit ) )

  SendOverheadEventMessage( player, OVERHEAD_ALERT_GOLD, unit, math.floor( gold ), player )

  Gold:AddGold( optPlayerID or unit, gold )
end

function Gold:GetGold ( unitvar )
  local playerID = UnitVarToPlayerID( unitvar )
  local currentGold = PlayerTables:GetTableValue( 'gold', 'gold' )[playerID]

  return math.floor( currentGold or 0 )
end
