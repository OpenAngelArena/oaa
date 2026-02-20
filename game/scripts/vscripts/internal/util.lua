--[[ This file provides the DebugPrint and DebugPrintTable functions, which are wrappers for print
with some added functionality useful for debugging. Documentation available in docs/debug_print_lua.md
]]
Debug = Debug or {
  EnabledModules = {
    ['internal:*'] = true,
    ['gamemode:*'] = true
  },
  EnableAll = false
}

function split(s, delimiter)
  local result = {}
  for match in (s..delimiter):gmatch("(.-)"..delimiter) do
    table.insert(result, match)
  end
  return result
end

function regexsplit(s, delimiter)
  local result = {}
  for match in s:gmatch("([^"..delimiter.."]+)") do
    table.insert(result, match)
  end
  return result
end

function TracesFromFilename (filename)
  local traces = {}


  if filename == 'components' then
    return {
      'components'
    }
  end

  local parts = regexsplit(filename, '%s/\\')
  local partialTrade = nil
  for i, part in ipairs(parts) do
    if partialTrade == nil and part ~= "components" then
      partialTrade = part
      table.insert(traces, partialTrade .. ":*")
    elseif partialTrade ~= nil then
      partialTrade = partialTrade .. ":" .. part
      table.insert(traces, partialTrade .. ":*")
    end
  end

  table.insert(traces, partialTrade)

  return traces
end

function IsAnyTraceEnabled (traces)
  if Debug.EnableAll then
    return true
  end

  for i, trace in ipairs(traces) do
    if Debug.EnabledModules[trace] then
      return true
    end
  end

  return false
end

function Debug:EnableDebugging()
  local trace, dir = GetCallingFile() --luacheck: ignore dir
  if trace then
    Debug.EnabledModules[trace[#trace]] = true
  end
end

-- written by yeahbuddy, taken from https://github.com/OpenAngelArena/oaa/pull/80
-- modified for clarity
function GetCallingFile (offset)
  if not debug then
    return nil, nil
  end
  offset = offset or 4

  local functionInfo = debug.getinfo(offset - 1, "Sl")
  local filePath = string.match(functionInfo.source, "scripts[/\\]vscripts[/\\](.+).lua")
  if functionInfo.currentline then
    return TracesFromFilename(filePath), filePath .. ":" .. functionInfo.currentline
  else
    return TracesFromFilename(filePath), filePath
  end
end

function DebugPrint(...)
  local spew
  if BAREBONES_DEBUG_SPEW then
    spew = 1
  end

  local trace, dir = GetCallingFile()

  if not trace or not dir then
    print("[traceback not available]", ...)
    return
  end

  if IsAnyTraceEnabled(trace) then
    spew = 1
  end

  local output = {...}
  if not output[1] then
    return
  end

  local prefix, msg = string.match(output[1], "%[([^%]]*)%]%s*(.*)")

  if prefix ~= nil then
    output[1] = msg
  end

  if spew == 1 then
    print("[" .. dir .. "]", unpack(output))
  end
end

function DebugPrintTable(...)
  local spew
  if BAREBONES_DEBUG_SPEW then
    spew = 1
  end

  local trace, dir = GetCallingFile()

  if not trace or not dir then
    PrintTable("[traceback not available]", ...)
    return
  end

  if IsAnyTraceEnabled(trace) then
    spew = 1
  end

  if spew == 1 then
    PrintTable("[" .. dir .. "]", ...)
  end
end

function DevPrintTable(...)
  local trace, dir = GetCallingFile() --luacheck: ignore trace
  if not dir then
    PrintTable("[traceback not available]", ...)
  else
    PrintTable("[" .. dir .. "]", ...)
  end
end

function PrintTable(prefix, t, indent, done)
  --print ( string.format ('PrintTable type %s', type(keys)) )
  if type(prefix) == "table" then
    -- shift
    done = indent
    indent = t
    t = prefix

    local trace = nil
    -- set prefix
    trace, prefix = GetCallingFile()

    if not prefix then
      prefix = "[no prefix] "
    else
      prefix = "[" .. prefix .. "] "
    end
  end
  if type(t) ~= "table" then return end

  done = done or {}
  done[t] = true
  indent = indent or 1

  local l = {}
  for k, v in pairs(t) do
    table.insert(l, k)
  end

  pcall(function()
    table.sort(l)
  end)

  for k, v in ipairs(l) do
    -- Ignore FDesc
    if v ~= 'FDesc' then
      local value = t[v]

      if type(value) == "table" and not done[value] then
        done [value] = true
        print(prefix .. string.rep ("\t", indent)..tostring(v)..":")
        PrintTable (prefix, value, indent + 2, done)
      elseif type(value) == "userdata" and not done[value] then
        done [value] = true
        print(prefix .. string.rep ("\t", indent)..tostring(v)..": "..tostring(value))
        PrintTable (prefix, (getmetatable(value) and getmetatable(value).__index) or getmetatable(value), indent + 2, done)
      else
        if t.FDesc and t.FDesc[v] then
          print(prefix .. string.rep ("\t", indent)..tostring(t.FDesc[v]))
        else
          print(prefix .. string.rep ("\t", indent)..tostring(v)..": "..tostring(value))
        end
      end
    end
  end
end

-- Colors
COLOR_NONE = '\x06'
COLOR_GRAY = '\x06'
COLOR_GREY = '\x06'
COLOR_GREEN = '\x0C'
COLOR_DPURPLE = '\x0D'
COLOR_SPINK = '\x0E'
COLOR_DYELLOW = '\x10'
COLOR_PINK = '\x11'
COLOR_RED = '\x12'
COLOR_LGREEN = '\x15'
COLOR_BLUE = '\x16'
COLOR_DGREEN = '\x18'
COLOR_SBLUE = '\x19'
COLOR_PURPLE = '\x1A'
COLOR_ORANGE = '\x1B'
COLOR_LRED = '\x1C'
COLOR_GOLD = '\x1D'


function DebugAllCalls()
  if not debug then
    print("debug not available!")
  end
  if not GameRules.DebugCalls then
      print("Starting DebugCalls")
      GameRules.DebugCalls = true

      debug.sethook(function(...)
          local info = debug.getinfo(2)
          local src = tostring(info.short_src)
          local name = tostring(info.name)
          if name ~= "__index" then
              print("Call: ".. src .. " -- " .. name .. " -- " .. info.currentline)
          end
      end, "c")
  else
      print("Stopped DebugCalls")
      GameRules.DebugCalls = false
      debug.sethook(nil, "c")
  end
end

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
function HideWearables( unit )
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
  assert(type(teamID) == "number", "teamID: " .. teamID .. " is not of type number but " .. type(teamID))
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

function IsPlayerTeam(teamID)
  assert(type(teamID) == "number", "teamID: " .. teamID .. " is not of type number but " .. type(teamID))
  return teamID == DOTA_TEAM_GOODGUYS or teamID == DOTA_TEAM_BADGUYS
end

function IsInTrigger(entity, trigger)
  local triggerOrigin = trigger:GetAbsOrigin()
  local bounds = trigger:GetBounds()

  local origin = entity
  if entity.GetAbsOrigin then
    origin = entity:GetAbsOrigin()
  end

  if origin.x < bounds.Mins.x + triggerOrigin.x then
    -- DebugPrint('x is too small')
    return false
  end
  if origin.y < bounds.Mins.y + triggerOrigin.y then
    -- DebugPrint('y is too small')
    return false
  end
  if origin.x > bounds.Maxs.x + triggerOrigin.x then
    -- DebugPrint('x is too large')
    return false
  end
  if origin.y > bounds.Maxs.y + triggerOrigin.y then
    -- DebugPrint('y is too large')
    return false
  end

  return true
end

function FindHeroesInRadius (...)
  local units = FindUnitsInRadius(...)

  local function isHero (hero)
    if hero.IsRealHero and hero:IsRealHero() and not hero:IsTempestDouble() and not hero:IsClone() and not hero:IsSpiritBearOAA() then
      return true
    end
    return false
  end

  return totable(filter(isHero, iter(units)))
end

function MoveCameraToPlayer(handle)
  local playerID = nil
  local entity = nil
  if IsValidEntity(handle) and handle:IsPlayer() then
    playerID = handle:GetPlayerID()
    entity = handle:GetAssignedHero()
  elseif IsValidEntity(handle) and handle:IsOwnedByAnyPlayer() then
    playerID = handle:GetPlayerOwnerID()
    entity = handle
  elseif tonumber(handle) and PlayerResource:IsValidPlayerID(handle) then
    playerID = handle
    entity = PlayerResource:GetSelectedHeroEntity(handle)
  else
    return
  end
  if playerID and entity then
    MoveCameraToEntity(playerID, entity)
  end
end

function MoveCameraToEntity(playerID, entity)
  if IsValidEntity(entity) and PlayerResource:IsValidPlayerID(playerID) then
    PlayerResource:SetCameraTarget(playerID, entity)
    Timers:CreateTimer(0.5, function ()
      PlayerResource:SetCameraTarget(playerID, nil)
    end)
  end
end

function IsLocationInOffside(location)
  return IsLocationInRadiantOffside(location) or IsLocationInDireOffside(location)
end

function IsLocationInRadiantOffside(pos)
  if not pos then
    print("Passed parameter to IsLocationInRadiantOffside is nil!")
    return nil
  end
  -- Radiant Offside trigger
  local trigger = Entities:FindByName(nil, 'boss_good_zone_0')
  if not trigger then
    print("Radiant Offside trigger not found or referenced name is wrong.")
    return false
  end
  if IsInTrigger(pos, trigger) then
    return true
  elseif GetMapName() == "oaa_legacy" then
    for i = 1, 4 do
      local triggerx = Entities:FindByName(nil, 'boss_good_zone_'..tostring(i))
      if triggerx then
        if IsInTrigger(pos, triggerx) then
          return true
        end
      end
    end
  end

  return false
end

function IsLocationInDireOffside(pos)
  if not pos then
    print("Passed parameter to IsLocationInDireOffside is nil!")
    return nil
  end
  -- Dire Offside trigger
  local trigger = Entities:FindByName(nil, 'boss_bad_zone_0')
  if not trigger then
    print("Dire Offside trigger not found or referenced name is wrong.")
    return false
  end
  if IsInTrigger(pos, trigger) then
    return true
  elseif GetMapName() == "oaa_legacy" then
    for i = 1, 4 do
      local triggerx = Entities:FindByName(nil, 'boss_bad_zone_'..tostring(i))
      if triggerx then
        if IsInTrigger(pos, triggerx) then
          return true
        end
      end
    end
  end

  return false
end

function IsLocationInFountain(location)
  if not location then
    print("Passed parameter to IsLocationInFountain is nil!")
    return nil
  end

  local fountains = Entities:FindAllByClassname("ent_dota_fountain")
  local radiant_fountain
  local dire_fountain
  for _, entity in pairs(fountains) do
    if entity:GetTeamNumber() == DOTA_TEAM_GOODGUYS then
      radiant_fountain = entity
    elseif entity:GetTeamNumber() == DOTA_TEAM_BADGUYS then
      dire_fountain = entity
    end
  end

  local radiant_fountain_trigger = Entities:FindByName(nil, "fountain_good_trigger")
  local dire_fountain_trigger = Entities:FindByName(nil, "fountain_bad_trigger")

  if radiant_fountain_trigger then
    if IsInTrigger(location, radiant_fountain_trigger) then
      return true
    end
  else
    print("Radiant fountain trigger not found or referenced name is wrong.")
    if radiant_fountain then
      if (radiant_fountain:GetAbsOrigin() - location):Length2D() <= 400 then
        return true
      end
    end
  end

  if dire_fountain_trigger then
    if IsInTrigger(location, dire_fountain_trigger) then
      return true
    end
  else
    print("Dire fountain trigger not found or referenced name is wrong.")
    if dire_fountain then
      if (dire_fountain:GetAbsOrigin() - location):Length2D() <= 400 then
        return true
      end
    end
  end

  return false
end

-- Calculates the distance between the fountain of the input team and the input location
function DistanceFromFountainOAA(location, team)
  if not location or not team then
    return nil
  end
  local fountains = Entities:FindAllByClassname("ent_dota_fountain")
  local fountain
  for _, entity in pairs(fountains) do
    if entity:GetTeamNumber() == team then
      fountain = entity
    end
  end
  if not fountain then
    print("Fountain not found for team "..tostring(team))
    return nil
  end

  return (fountain:GetAbsOrigin() - location):Length2D()
end

-- Calculates the approximate center of the map based on fountain locations
function GetMapCenterOAA()
  local defaultCenter = Vector(0, 0, 0)

  local fountains = Entities:FindAllByClassname("ent_dota_fountain")
  local radiant_fountain
  local dire_fountain
  for _, entity in pairs(fountains) do
    if entity:GetTeamNumber() == DOTA_TEAM_GOODGUYS then
      radiant_fountain = entity
    elseif entity:GetTeamNumber() == DOTA_TEAM_BADGUYS then
      dire_fountain = entity
    end
  end
  if not radiant_fountain then
    print("Radiant Fountain not found!")
    return defaultCenter
  end
  if not dire_fountain then
    print("Dire Fountain not found!")
    return defaultCenter
  end

  local distance_between_fountains = (radiant_fountain:GetAbsOrigin() - dire_fountain:GetAbsOrigin()):Length2D()
  -- Center should be between the fountains but fountains don't need to share the y axis
  -- The following code is true only if the real center of the map is somewhere in the playable non-duel area
  local center_according_to_radiant = radiant_fountain:GetAbsOrigin() + distance_between_fountains/2 * Vector(1, 0, 0)
  local center_according_to_dire = dire_fountain:GetAbsOrigin() - distance_between_fountains/2 * Vector(1, 0, 0)

  -- Calculate approximate center of the map
  local direction = center_according_to_radiant - center_according_to_dire
  local distance = direction:Length2D()
  direction.z = 0
  direction = direction:Normalized()
  local approx_center = center_according_to_dire + direction * distance/2

  return approx_center
end

function GetMainAreaBoundsX()
  local Xbounds = {minX = 0, maxX = 0}

  local fountains = Entities:FindAllByClassname("ent_dota_fountain")
  local radiant_fountain
  local dire_fountain
  for _, entity in pairs(fountains) do
    if entity:GetTeamNumber() == DOTA_TEAM_GOODGUYS then
      radiant_fountain = entity
    elseif entity:GetTeamNumber() == DOTA_TEAM_BADGUYS then
      dire_fountain = entity
    end
  end
  if radiant_fountain then
    Xbounds.minX = radiant_fountain:GetAbsOrigin().x + 100
  else
    print("Radiant Fountain not found!")
  end
  if dire_fountain then
    Xbounds.maxX = dire_fountain:GetAbsOrigin().x - 100
  else
    print("Dire Fountain not found!")
  end

  return Xbounds
end

function GetMainAreaBoundsY()
  local Ybounds = {minY = -3252, maxY = 4596} -- these numbers are good for all maps
  -- TODO: Figure out how to get Y coordinates of the main playable area
  return Ybounds
end
