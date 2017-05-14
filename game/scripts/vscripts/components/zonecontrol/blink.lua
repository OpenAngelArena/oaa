
-- local AbilityMovementMap = {
--   [0] = {},
--   [1] = {},
--   [2] = {},
--   [3] = {},
--   [4] = {},
--   [5] = {},
--   [6] = {},
--   [7] = {},
--   [8] = {},
--   [9] = {}
-- }

-- Taken from bb template
if BlinkBlock == nil then
  DebugPrint ( 'creating new blink blocker object' )
  BlinkBlock = class({})

  Debug.EnabledModules['zonecontrol:blink'] = false
end

-- todo: support items

function BlinkBlock:Init ()
  ListenToGameEvent('dota_player_used_ability', Dynamic_Wrap(BlinkBlock, 'OnAbilityUsed'), self)
  ListenToGameEvent("dota_player_begin_cast", Dynamic_Wrap(BlinkBlock, 'OnAbilityCastBegins'), self)
end


-- An ability was used by a player
function BlinkBlock:OnAbilityCastBegins(keys)
  local player = PlayerResource:GetPlayer(keys.PlayerID)
  local abilityname = keys.abilityname

  -- AbilityMovementMap[keys.PlayerID].start = player:GetAssignedHero():GetAbsOrigin()
end

-- An ability was used by a player
function BlinkBlock:OnAbilityUsed(keys)
  local player = PlayerResource:GetPlayer(keys.PlayerID)
  local hero = player:GetAssignedHero()
  local abilityname = keys.abilityname

  local startPos = player:GetAssignedHero():GetAbsOrigin()

  -- todo: Meepo will break this
  -- todo: allow things like natures profit
  local function checkHeroPosition ()
    if hero:IsInvulnerable() then
      Timers:CreateTimer(0.01, checkHeroPosition)
    end
    local endPos = hero:GetAbsOrigin()
    -- AbilityMovementMap[keys.PlayerID].start = nil

    local shouldMoveUnit, moveLocaiton = BlinkBlock:CheckBlink(startPos, endPos)

    if shouldMoveUnit then
      FindClearSpaceForUnit(player:GetAssignedHero(), moveLocaiton, false)
    end
  end

  Timers:CreateTimer(0.01, checkHeroPosition)
end

function BlinkBlock:CheckBlink(startLoc, endLoc)
  local distanceV = (endLoc - startLoc)
  local halfDistance = distanceV / 2
  local radius = distanceV:Length2D()
  local spellCenter = startLoc + halfDistance
  local didEverHit = false

  -- DebugPrint('Blink vector is ' .. distanceV:__tostring())
  -- DebugPrint('Blink cast at ' .. spellCenter:__tostring())
  -- DebugPrint('Radius of ' .. radius)

  --  find all by name within sucks. it doesn't return everything in that box, so you have to widen the range quite a bit
  -- really, radius should even be halved...
  local blocks = Entities:FindAllByNameWithin('blink_block', spellCenter, radius + 1000)

  DebugPrint('Found ' .. #blocks)

  for _,block in pairs(blocks) do
    local blockOrigin = block:GetAbsOrigin()
    local minBounds = block:GetBoundingMins()
    local maxBounds = block:GetBoundingMaxs()
    local angle = block:GetAnglesAsVector()

    if angle ~= Vector(0, 0, 0) then
      DebugPrint('[zonecontrol/blink] ERROR !! Cant rotate blink blockers !!')
      return endLoc
    end

    -- DebugPrint(minBounds)
    -- DebugPrint(maxBounds)

    local xSide = 0
    local ySide = 0
    local ySideOffset = 0
    local xSideOffset = 0

    if distanceV.x > 0 then
      xSide = minBounds.x
      xSideOffset = 50
    else
      xSide = maxBounds.x
      xSideOffset = -50
    end
    xSide = xSide + xSideOffset

    if distanceV.y > 0 then
      ySide = minBounds.y
      ySideOffset = 50
    else
      ySide = maxBounds.y
      ySideOffset = -50
    end
    ySide = ySide + ySideOffset

    local sideApA = blockOrigin + Vector(minBounds.x - 10, ySide, 0)
    local sideApB = blockOrigin + Vector(maxBounds.x + 10, ySide, 0)

    local sideBpA = blockOrigin + Vector(xSide, minBounds.y - 10, 0)
    local sideBpB = blockOrigin + Vector(xSide, maxBounds.y + 10, 0)

    local didHit, hitResult = math.doLinesIntersect(startLoc, endLoc, sideApA, sideApB)
    if not didHit then
      didHit, hitResult = math.doLinesIntersect(startLoc, endLoc, sideBpA, sideBpB)
    end

    if didHit then
      DebugPrint('did hit blink blocker: result ' .. tostring(hitResult and (hitResult.x .. '/' .. hitResult.y) or '--'))

      endLoc.x = hitResult.x - xSideOffset
      endLoc.y = hitResult.y - ySideOffset
      didEverHit = true
    end
  end

  return didEverHit, endLoc
end
