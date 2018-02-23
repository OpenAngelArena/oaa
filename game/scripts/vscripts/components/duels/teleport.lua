-- This module contains functions for teleporting heroes including their summons
-- and with handling for special cases where heroes might be in an exiled state

local export = {}

local function SafeTeleport(unit, location, maxDistance)
  unit:Stop()
  if unit:FindModifierByName("modifier_life_stealer_infest") then
    DebugPrint("Found Lifestealer infesting")
    local ability = unit:FindAbilityByName("life_stealer_consume")
    if ability and ability:IsActivated() then
    ExecuteOrderFromTable({
      UnitIndex = unit:entindex(),
      OrderType = DOTA_UNIT_ORDER_CAST_NO_TARGET,
      AbilityIndex = ability:entindex(), --Optional.  Only used when casting abilities
      Queue = 0 --Optional.  Used for queueing up abilities
    })
    else
      print("Error: Could not find Consume ability on an Infesting unit")
      D2CustomLogging:sendPayloadForTracking(D2CustomLogging.LOG_LEVEL_INFO, "COULD NOT FIND CONSUME ABILITY", {
        ErrorMessage = "Tried to teleport an Infesting unit, but could not find Consume ability on that unit, or ability was not castable",
        ErrorTime = GetSystemDate() .. " " .. GetSystemTime(),
        GameVersion = GAME_VERSION,
        DedicatedServers = (IsDedicatedServer() and 1) or 0,
        MatchID = tostring(GameRules:GetMatchID())
      })
  end
  if unit:IsOutOfGame() then
    unit:RemoveModifierByName("modifier_obsidian_destroyer_astral_imprisonment_prison")
    unit:RemoveModifierByName("modifier_riki_tricks_of_the_trade") -- TODO: Check name
  end
  if unit:FindModifierByName("modifier_life_stealer_assimilate_effect") then
    DebugPrint("Found Lifestealer with assimilated unit")
    local ability = unit:FindAbilityByName("life_stealer_assimilate_eject")
    if ability and ability:IsActivated() then
      ExecuteOrderFromTable({
        UnitIndex = unit:entindex(),
        OrderType = DOTA_UNIT_ORDER_CAST_NO_TARGET,
        AbilityIndex = ability:entindex(), --Optional.  Only used when casting abilities
        Queue = 0 --Optional.  Used for queueing up abilities
      })
    else
      print("Error: Could not find Eject ability on an Assimilating unit")
      D2CustomLogging:sendPayloadForTracking(D2CustomLogging.LOG_LEVEL_INFO, "COULD NOT FIND EJECT ABILITY", {
        ErrorMessage = "Tried to teleport an Assimilating unit, but could not find Eject ability on that unit, or ability was not castable",
        ErrorTime = GetSystemDate() .. " " .. GetSystemTime(),
        GameVersion = GAME_VERSION,
        DedicatedServers = (IsDedicatedServer() and 1) or 0,
        MatchID = tostring(GameRules:GetMatchID())
      })
    end
  end
  location = GetGroundPosition(location, unit)
  FindClearSpaceForUnit(unit, location, true)
  Timers:CreateTimer(0.1, function()
    if not unit or unit:IsNull() then
      return
    end
    local distance = (location - unit:GetAbsOrigin()):Length2D()
    if distance > maxDistance then
      SafeTeleport(unit, location, maxDistance)
    end
  end)
end

local function SafeTeleportAll(mainUnit, location, maxDistance)
  SafeTeleport(mainUnit, location, maxDistance)
  local playerAdditionalUnits
  -- GetAdditionalOwnedUnits is unsuitable here as it apparently only returns hero-like units, like Lone Druid's Bear and such.
  -- It definitely does not return most normal unit summons, including Necronomicon and Broodmother Spiderlings.
  -- if mainUnit.GetAdditionalOwnedUnits then
  --   playerAdditionalUnits = mainUnit:GetAdditionalOwnedUnits() or {} -- assign empty table instead of nil so iter can be called without errors
  -- else
  playerAdditionalUnits = FindUnitsInRadius(mainUnit:GetTeam(),
                                            mainUnit:GetAbsOrigin(),
                                            nil,
                                            FIND_UNITS_EVERYWHERE,
                                            DOTA_UNIT_TARGET_TEAM_FRIENDLY,
                                            bit.bor(DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_BASIC),
                                            DOTA_UNIT_TARGET_FLAG_PLAYER_CONTROLLED,
                                            FIND_ANY_ORDER,
                                            false)
  playerAdditionalUnits = playerAdditionalUnits or {} -- assign empty table instead of nil so iter can be called without errors
  playerAdditionalUnits = iter(playerAdditionalUnits):filter(function (unit)
    return unit:GetPlayerOwnerID() == mainUnit:GetPlayerOwnerID()
  end)
  -- end

  iter(playerAdditionalUnits)
    :filter(CallMethod("HasMovementCapability"))
    :foreach(function (unit)
      SafeTeleport(unit, location, maxDistance)
    end)
end

-- Test SafeTeleport function
local function TestSafeTeleport(keys)
  local hero = PlayerResource:GetSelectedHeroEntity(keys.playerid)
  SafeTeleportAll(hero, Vector(0, 0, 0), 150)
end

ChatCommand:LinkCommand("-test_tp", TestSafeTeleport, nil)
export.SafeTeleport = SafeTeleport
export.SafeTeleportAll = SafeTeleportAll

return export
