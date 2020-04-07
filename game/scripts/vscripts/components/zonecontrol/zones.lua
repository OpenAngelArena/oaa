--[[

Zone control....

 - The map will have zones that the players are locked in/out of at given times
 - need to understand the zones at load in time and their initial state
 - expose and api for changing the lock state and the player list allowed / disallowed in/out of the zone

potential settings for a given zone:
whitelist / blacklist
in / out
active / inactive

]]

-- exclusive, only players on the list have rules enforced
-- players on the list will be locked in (or players not included are "allowed out")
-- this with a full list is the same as INCLUSIVE with a full list
ZONE_CONTROL_EXCLUSIVE_IN = 1
-- players on the list will be locked out (or players not included are "allowed in")
-- this with a full list is the same as INCLUSIVE with an empty list
ZONE_CONTROL_EXCLUSIVE_OUT = 2
-- ALL players have rules enforced (players on list are locked in, players not in list are locked out)
ZONE_CONTROL_INCLUSIVE = 3

-- Taken from bb template
if ZoneControl == nil then
    DebugPrint ( 'creating new zone control object' )
    ZoneControl = class({})
end

function ZoneControl:Init ()
  -- do initialization things....

  -- execute the zone control tester if it is enabled.
  -- gotta run after init in case init makes itself useful
  if ZoneControlTest ~= nil then
    ZoneControlTest:Init()
  end
end

function ZoneControl:CreateZone (name, options)
  local handles = Entities:FindAllByName(name)
  options = options or {}

  DebugPrint('Creating new zone ' .. name)

  assert(#handles > 0, "Could not find an entity handle for (" .. name .. ")")
  if #handles > 1 then
    -- create group
    return ZoneControl:CreateGroupFromHandles(handles, options)
  else
    -- single instance
    return ZoneControl:CreateStateFromHandle(handles[1], options)
  end
end

function ZoneControl:CreateEmptyState (options)
  return {
    isZoneControlState = true,
    mode = options.mode,
    players = options.players,
    padding = options.padding or 100,
    margin = options.margin or 100
  }
end

function ZoneControl.onTrigger (state, eventName, zoneHandle, event)
  DebugPrint('Trigger is firing! ' .. eventName)
  DebugPrintTable(event)
  --[[
[   VScript  ]: activator:
[   VScript  ]:     __self: userdata: 0x002e20a8
[   VScript  ]:     bFirstSpawned: true
[   VScript  ]: caller:
[   VScript  ]:     __self: userdata: 0x00300a80
[   VScript  ]:     endTouchHandler: function: 0x00300ae0
[   VScript  ]:     startTouchHandler: function: 0x00147920
[   VScript  ]:     triggerHandler: function: 0x002d1300
[   VScript  ]: outputid: 0
]]
  ZoneControl:EnforceRulesOnEntity(state, event.activator:GetPlayerID(), event.activator)
end

function ZoneControl:CreateStateFromHandle (handle, options)
  local state = ZoneControl:CreateEmptyState(options)

  state.handle = handle

  -- don't move zones
  state.bounds = handle:GetBounds()
  state.origin = handle:GetAbsOrigin()

  -- api
  state.enable = partial(ZoneControl['EnableZone'], state)
  state.disable = partial(ZoneControl['DisableZone'], state)

  state.addPlayer = partial(ZoneControl['AddPlayer'], state)
  state.removePlayer = partial(ZoneControl['RemovePlayer'], state)

  state.setMode = partial(ZoneControl['SetMode'], state)

  -- handlers
  local startTouchEvent = Event()
  local endTouchEvent = Event()

  handle.startTouchHandler = startTouchEvent.broadcast
  handle.endTouchHandler = endTouchEvent.broadcast

  state.onStartTouch = startTouchEvent.listen
  state.onEndTouch = endTouchEvent.listen

  state.onStartTouch(partial(ZoneControl['onTrigger'], state, 'OnStartTouch'))
  state.onEndTouch(partial(ZoneControl['onTrigger'], state, 'OnEndTouch'))

  handle:RedirectOutput('OnStartTouch', 'startTouchHandler', handle)
  handle:RedirectOutput('OnEndTouch', 'endTouchHandler', handle)

  Timers:CreateTimer(5, function ()
    ZoneControl:EnforceRules(state)
    return 5
  end)

  return state;
end

function ZoneControl:MoveZone (state)
  -- fine, move zones
  state.bounds = state.handle:GetBounds()
  state.origin = state.handle:GetAbsOrigin()
end

function ZoneControl:CreateGroupFromHandles (handles, options)
  local state = ZoneControl:CreateEmptyState(options)

  state.isGroup = true
  state.states = {}

  for i,handle in ipairs(handles) do
    state.states[i] = ZoneControl:CreateStateFromHandle(handle, options)
  end

  return state;
end

-- API methods

function ZoneControl.EnableZone (state)
  if ZoneControl:SpreadZoneGroup(state, 'EnableZone') then
    return
  end
  state.handle:Enable()

  ZoneControl:EnforceRules(state)
  state.disabled = false
end

function ZoneControl.DisableZone (state)
  if ZoneControl:SpreadZoneGroup(state, 'DisableZone') then
    return
  end
  state.handle:Disable()
  state.disabled = true
end

function ZoneControl:SetMode (state, mode)
  if ZoneControl:SpreadZoneGroup(state, 'EnableZone') then
    return
  end
  state.mode = mode

  ZoneControl:EnforceRules(state)
end

function ZoneControl.AddPlayer (state, playerId, shouldEnforceRules)
  if ZoneControl:SpreadZoneGroup(state, 'AddPlayer') then
    return
  end
  state.players[playerId] = true

  if shouldEnforceRules ~= false then
    ZoneControl:EnforceRulesOnPlayerId(state, playerId)
  end
end

function ZoneControl.RemovePlayer (state, playerId, shouldEnforceRules)
  if ZoneControl:SpreadZoneGroup(state, 'RemovePlayer') then
    return
  end
  state.players[playerId] = false

  if shouldEnforceRules ~= false then
    ZoneControl:EnforceRulesOnPlayerId(state, playerId)
  end
end

-- rules enforcement


--[[

ZoneControl:EnforceRules (state)
called when a zone is activated or has its rules are changed

ZoneControl:EnforceRulesOnEntity (state, entity)
Called on events and internally in enforce rules

Enforce these rules (copy pasted from above) on a single state:

-- exclusive, only players on the list have rules enforced
-- players on the list will be locked in (or players not included are "allowed out")
-- this with a full list is the same as INCLUSIVE with a full list
ZONE_CONTROL_EXCLUSIVE_IN = 1
-- players on the list will be locked out (or players not included are "allowed in")
-- this with a full list is the same as INCLUSIVE with an empty list
ZONE_CONTROL_EXCLUSIVE_OUT = 2
-- ALL players have rules enforced (players on list are locked in, players not in list are locked out)
ZONE_CONTROL_INCLUSIVE = 3

]]
function ZoneControl:EnforceRules (state)
  -- this method is meant to be called with a single zone since it's the actual rules enforcement
  ZoneControl:AssertIsSingleState(state)

  if state.disabled then
    return
  end

  for playerId = 0,19 do
    ZoneControl:EnforceRulesOnPlayerId(state, playerId)
  end
end

function ZoneControl:EnforceRulesOnPlayerId (state, playerId)
  if state.disabled then
    return
  end
  local player = PlayerResource:GetPlayer(playerId)

  if player and player:GetAssignedHero() then
    local hero = player:GetAssignedHero()
    ZoneControl:EnforceRulesOnEntity(state, playerId, hero)


    local playerAdditionalUnits = FindUnitsInRadius(
        hero:GetTeam(),
        hero:GetAbsOrigin(),
        nil,
        FIND_UNITS_EVERYWHERE,
        DOTA_UNIT_TARGET_TEAM_FRIENDLY,
        bit.bor(DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_BASIC),
        DOTA_UNIT_TARGET_FLAG_PLAYER_CONTROLLED,
        FIND_ANY_ORDER,
        false)
    playerAdditionalUnits = playerAdditionalUnits or {} -- assign empty table instead of nil so iter can be called without errors

    iter(playerAdditionalUnits)
      :filter(function (unit)
        return unit:GetPlayerOwnerID() == hero:GetPlayerOwnerID() and unit:HasMovementCapability() and (not unit:IsCourier())
      end)
      :foreach(function (unit)
        ZoneControl:EnforceRulesOnEntity(state, playerId, unit)
      end)
  end
end

function ZoneControl:EnforceRulesOnEntity (state, playerId, entity)
  -- this method is meant to be called with a single zone since it's the actual rules enforcement
  ZoneControl:AssertIsSingleState(state)
  if state.disabled then
    return
  end

  local isTouching = state.handle:IsTouching(entity)
  local initialOrigin = entity:GetAbsOrigin()
  local origin = entity:GetAbsOrigin()
  local bounds = entity:GetBounds()

  local shouldBeLockedIn = false
  local shouldBeLockedOut = false

  if state.mode == ZONE_CONTROL_INCLUSIVE then
    -- ALL players have rules enforced (players on list are locked in, players not in list are locked out)
    shouldBeLockedIn = state.players[playerId]
    shouldBeLockedOut = not shouldBeLockedIn

    -- end inclusive
    -- exclusives, only players on the list have rules enforced
  elseif state.mode == ZONE_CONTROL_EXCLUSIVE_OUT then
    -- players on the list will be locked out (or players not included are "allowed in")
    shouldBeLockedOut = state.players[playerId]
  elseif state.mode == ZONE_CONTROL_EXCLUSIVE_IN then
    -- players on the list will be locked in (or players not included are "allowed out")
    shouldBeLockedIn = state.players[playerId]
  end

  -- now we know which rules to enforce!
  assert(not shouldBeLockedIn or not shouldBeLockedOut, "Cannot be locked in and out of a zone!")

  -- DebugPrint ('player locked in/out ' .. tostring(shouldBeLockedIn) .. '/' .. tostring(shouldBeLockedOut) .. ' and touching is ' .. tostring(isTouching))
  if shouldBeLockedOut then
    -- the player should be locked out, but there's an entity touching us!
    if isTouching then
      DebugPrint('Player is touching, but should be locked out')
      --[[
      we want to find the spot outside of the zone that the entity should be placed
      potential for FindPlaceWhatever to infinite loop rounding a player back into a zone?

      i don't think it makes sense to push the entity radially outwards, instead we want to just
      find the wall they're closest to and place them up against it... maybe with a margin?
                                                              x          y         z
[   VScript              ]: Maxs: Vector 00000000002DB5A8 [288.000000 256.000000 96.000000]
[   VScript              ]: Mins: Vector 00000000002DB540 [-288.000000 -256.000000 -96.000000]

      ]]
      -- these can't be rotated.....
      -- even fuck ez math tho

      -- i want to know how close we are to each edge, but it's kind of easier to think about it as the % away from the center you are

      local xDistance = (origin.x - state.origin.x) / state.bounds.Maxs.x
      local yDistance = (origin.y - state.origin.y) / state.bounds.Maxs.y

      -- positive values go right and up
      if math.abs(xDistance) > math.abs(yDistance) then
        -- we're snapping to an X wall
        if xDistance > 0 then
          -- we're snapping to the right wall
          origin = Vector(state.bounds.Maxs.x + bounds.Maxs.x + state.margin + state.origin.x, origin.y, origin.z)
        else
          -- we're snapping to the left wall
          origin = Vector(state.bounds.Mins.x + bounds.Mins.x - state.margin + state.origin.x, origin.y, origin.z)
        end
      else
        -- we're snapping to a Y wall
        if yDistance > 0 then
          -- we're snapping to the top wall
          origin = Vector(origin.x, state.bounds.Maxs.y + bounds.Maxs.y + state.margin + state.origin.y, origin.z)
        else
          -- we're snapping to the bottom wall
          origin = Vector(origin.x, state.bounds.Mins.y + bounds.Mins.y - state.margin + state.origin.y, origin.z)
        end
      end
    end
  elseif shouldBeLockedIn then
    if not isTouching then
      DebugPrint('Player is not touching, but should be!')
      local x = origin.x
      local y = origin.y
      local topWall = state.origin.y + state.bounds.Maxs.y - state.padding
      local rightWall = state.origin.x + state.bounds.Maxs.x - state.padding
      local bottomWall = state.origin.y + state.bounds.Mins.y + state.padding
      local leftWall = state.origin.x + state.bounds.Mins.x + state.padding

      if x > rightWall then
        x = rightWall
      elseif x < leftWall then
        x = leftWall
      end
      if y > topWall then
        y = topWall
      elseif y < bottomWall then
        y = bottomWall
      end

      origin = Vector(x, y, origin.z)
    end
  end

  if origin ~= initialOrigin then
    FindClearSpaceForUnit(entity, origin, true)
  end
end

-- utility methods

function ZoneControl:AssertIsState (state)
  assert(state.isZoneControlState, "is a zone control object")
end

function ZoneControl:AssertIsSingleState (state)
  assert(state.isZoneControlState and not state.isGroup, "is a single zone control object")
end

function ZoneControl:AssertIsGroup (state)
  assert(state.isZoneControlState and state.isGroup, "is a grouped zone control object")
end

function ZoneControl:SpreadZoneGroup (group, method)
  ZoneControl:AssertIsState(group)
  if not group.isGroup then
    return false;
  end

  for _,state in pairs(group.states) do
    ZoneControl[method](ZoneControl:InheritState(group, state))
  end

  return true;
end

function ZoneControl:InheritState (parent, state)
  return {
    isZoneControlState = true,
    isGroup = state.isGroup,
    players = state.players or parent.players,
    mode = state.mode or parent.mode
  }
end
