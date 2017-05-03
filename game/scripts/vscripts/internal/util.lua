--[[ This file provides the DebugPrint and DebugPrintTable functions, which are wrappers for print
with some added functionality useful for debugging. Documentation available in docs/debug_print_lua.md
]]

require('internal/utils/init')

--[[
  Credits:
    Angel Arena Blackstar
  Description:
    Returns the player id from a given unit / player / table.
    For example, you should be able to pass in a reference to a lycan wolf and get back the correct player's ID.
    -- chrisinajar
]]
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

--[[Author: Noya
  Date: 09.08.2015.
  Hides all dem hats
]]
function HideWearables(unit)
  unit.hiddenWearables = {} -- Keep every wearable handle in a table to show them later
    local model = unit:FirstMoveChild()
    while model ~= nil do
        if model:GetClassname() == "dota_item_wearable" then
            model:AddEffects(EF_NODRAW) -- Set model hidden
            table.insert(unit.hiddenWearables, model)
        end
        model = model:NextMovePeer()
    end
end

function ShowWearables(unit)
  for i,v in pairs(unit.hiddenWearables) do
    v:RemoveEffects(EF_NODRAW)
  end
end


function GetShortTeamName(teamID)
  local teamNames = {
    [DOTA_TEAM_GOODGUYS] = "good",
    [DOTA_TEAM_BADGUYS] = "bad",
    [DOTA_TEAM_NEUTRALS] = "neutral",
    [DOTA_TEAM_CUSTOM_1] = "custom1",
    [DOTA_TEAM_CUSTOM_2] = "custom2",
    [DOTA_TEAM_CUSTOM_3] = "custom3",
    [DOTA_TEAM_CUSTOM_4] = "custom4",
    [DOTA_TEAM_CUSTOM_5] = "custom5",
    [DOTA_TEAM_CUSTOM_6] = "custom6",
    [DOTA_TEAM_CUSTOM_7] = "custom7",
    [DOTA_TEAM_CUSTOM_8] = "custom8",
  }
  return teamNames[teamID]
end
