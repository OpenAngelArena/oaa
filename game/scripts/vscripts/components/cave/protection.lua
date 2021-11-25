LinkLuaModifier('modifier_is_in_offside', 'modifiers/modifier_offside.lua', LUA_MODIFIER_MOTION_NONE)

if ProtectionAura == nil then
  DebugPrint ( 'Creating new ProtectionAura object.' )
  ProtectionAura = class({})
  Debug.EnabledModules['cave:protection'] = false
end

function ProtectionAura:Init ()
  self.moduleName = "ProtectionAura (Offside protection and cave/base locking)"

  self.max_rooms = 0
  local legacy = GetMapName() == "oaa_legacy"
  if legacy then
    self.max_rooms = 4
  end

  self.zones = {
    [DOTA_TEAM_GOODGUYS] = {},
    [DOTA_TEAM_BADGUYS] = {},
  }

  local allGoodPlayers = {}
  local allBadPlayers = {}

  local function addToList (list, id)
    list[id] = true
  end
  each(partial(addToList, allGoodPlayers), PlayerResource:GetPlayerIDsForTeam(DOTA_TEAM_GOODGUYS))
  each(partial(addToList, allBadPlayers), PlayerResource:GetPlayerIDsForTeam(DOTA_TEAM_BADGUYS))

  HudTimer:At(-10, function ()
    local function removePlayerFromList (room, id)
      room.removePlayer(id)
    end
    local roomID = 0
    each(partial(removePlayerFromList, ProtectionAura.zones[DOTA_TEAM_GOODGUYS][roomID]), PlayerResource:GetPlayerIDsForTeam(DOTA_TEAM_GOODGUYS))
    each(partial(removePlayerFromList, ProtectionAura.zones[DOTA_TEAM_BADGUYS][roomID]), PlayerResource:GetPlayerIDsForTeam(DOTA_TEAM_BADGUYS))
  end)

  Duels.onEnd(function (data)
    ProtectionAura.zones[DOTA_TEAM_GOODGUYS][0].enable()
    ProtectionAura.zones[DOTA_TEAM_BADGUYS][0].enable()
  end)
  Duels.onStart(function (data)
    ProtectionAura.zones[DOTA_TEAM_GOODGUYS][0].disable()
    ProtectionAura.zones[DOTA_TEAM_BADGUYS][0].disable()
  end)

  for roomID = 0, self.max_rooms do
	local lockedPlayers = {}
    if not legacy then lockedPlayers = allGoodPlayers end
    ProtectionAura.zones[DOTA_TEAM_GOODGUYS][roomID] = ZoneControl:CreateZone('boss_good_zone_' .. roomID, {
      mode = ZONE_CONTROL_EXCLUSIVE_IN,
      margin = 0,
      padding = 50,
      players = lockedPlayers
    })

    ProtectionAura.zones[DOTA_TEAM_GOODGUYS][roomID].onStartTouch(ProtectionAura.StartTouch)
    ProtectionAura.zones[DOTA_TEAM_GOODGUYS][roomID].onEndTouch(ProtectionAura.EndTouch)
  end

  for roomID = 0, self.max_rooms do
    local lockedPlayers = {}
    if not legacy then lockedPlayers = allBadPlayers end
    ProtectionAura.zones[DOTA_TEAM_BADGUYS][roomID] = ZoneControl:CreateZone('boss_bad_zone_' .. roomID, {
      mode = ZONE_CONTROL_EXCLUSIVE_IN,
      margin = 0,
      padding = 0,
      players = lockedPlayers
    })

    ProtectionAura.zones[DOTA_TEAM_BADGUYS][roomID].onStartTouch(ProtectionAura.StartTouch)
    ProtectionAura.zones[DOTA_TEAM_BADGUYS][roomID].onEndTouch(ProtectionAura.EndTouch)
  end

  ProtectionAura.active = true
end

function ProtectionAura:IsInEnemyZone(teamID, entity)
  for roomID = 0, self.max_rooms do
    if ProtectionAura:IsInSpecificZone(teamID, roomID, entity) then
      return true
    end
  end
  return false
end

function ProtectionAura:IsInSpecificZone(teamID, roomID, entity)
  local zone = self.zones[teamID][roomID]
  return zone.handle:IsTouching(entity)
end

-- function ProtectionAura:StartTouchGood(event)
  -- if event.activator:GetTeam() ~= DOTA_TEAM_GOODGUYS and not Wanderer.radiant_offside_disabled then
    -- if not event.activator:HasModifier("modifier_is_in_offside") then
      -- return event.activator:AddNewModifier(event.activator, nil, "modifier_is_in_offside", {})
    -- end
  -- end
-- end

-- function ProtectionAura:EndTouchGood(event)
  -- if not ProtectionAura:IsInEnemyZone(DOTA_TEAM_GOODGUYS, event.activator) then
    -- event.activator:RemoveModifierByName("modifier_is_in_offside")
  -- end
-- end

-- function ProtectionAura:StartTouchBad(event)
  -- if event.activator:GetTeam() ~= DOTA_TEAM_BADGUYS and not Wanderer.dire_offside_disabled then
    -- if not event.activator:HasModifier("modifier_is_in_offside") then
      -- return event.activator:AddNewModifier(event.activator, nil, "modifier_is_in_offside", {})
    -- end
  -- end
-- end

-- function ProtectionAura:EndTouchBad(event)
  -- if not ProtectionAura:IsInEnemyZone(DOTA_TEAM_BADGUYS, event.activator) then
    -- event.activator:RemoveModifierByName("modifier_is_in_offside")
  -- end
-- end

function ProtectionAura:StartTouch(event)
  if not event.activator:HasModifier("modifier_is_in_offside") then
    return event.activator:AddNewModifier(event.activator, nil, "modifier_is_in_offside", {})
  end
end

function ProtectionAura:EndTouch(event)
  local activator = event.activator
  local origin = activator:GetAbsOrigin()
  local team = activator:GetTeam()

  -- Remove offside thinker if activator is not in offside
  if (team == DOTA_TEAM_GOODGUYS and not IsLocationInDireOffside(origin)) or (team == DOTA_TEAM_BADGUYS and not IsLocationInRadiantOffside(origin)) then
    if activator:HasModifier("modifier_is_in_offside") then
      activator:RemoveModifierByName("modifier_is_in_offside")
    end
  end
end
