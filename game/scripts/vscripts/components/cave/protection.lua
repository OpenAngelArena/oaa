LinkLuaModifier('modifier_offside', 'modifiers/modifier_offside.lua', LUA_MODIFIER_MOTION_NONE)

if ProtectionAura == nil then
  DebugPrint ( 'Creating new ProtectionAura object.' )
  ProtectionAura = class({})
  Debug.EnabledModules['cave:protection'] = true
end

function ProtectionAura:Init ()
  for RoomID = 0,5 do
    ProtectionAura.zoneRoomID = ZoneControl:CreateZone('boss_good_zone_' .. RoomID, {
      mode = ZONE_CONTROL_EXCLUSIVE_OUT,
      margin = 0,
      padding = 0,
      players = {}
    })
    ProtectionAura.zoneRoomID.onStartTouch(ProtectionAura.StartTouchGood)
    ProtectionAura.zoneRoomID.onEndTouch(ProtectionAura.EndTouchGood)
  end

  for RoomID = 6,11 do
    ProtectionAura.zoneRoomID = ZoneControl:CreateZone('boss_bad_zone_' .. RoomID, {
      mode = ZONE_CONTROL_EXCLUSIVE_OUT,
      margin = 0,
      padding = 0,
      players = {}
    })


    ProtectionAura.zoneRoomID.onStartTouch(ProtectionAura.StartTouchBad)
--    ProtectionAura.zoneRoomID.onEndTouch(ProtectionAura.EndTouchBad)
  end

  ProtectionAura.active = true

end

function ProtectionAura:IsInEnemyZone(teamID, entity)
  local zoneOrigin = self.ProtectionAura.zoneRoomID.origin
  local bounds = self.ProtectionAura.zoneRoomID.bounds

  local origin = entity
  if entity.GetAbsOrigin then
    origin = entity:GetAbsOrigin()
  end

  if origin.x < bounds.Mins.x + zoneOrigin.x then
    -- DebugPrint('x is too small')
    return false
  end
  if origin.y < bounds.Mins.y + zoneOrigin.y then
    -- DebugPrint('y is too small')
    return false
  end
  if origin.x > bounds.Maxs.x + zoneOrigin.x then
    -- DebugPrint('x is too large')
    return false
  end
  if origin.y > bounds.Maxs.y + zoneOrigin.y then
    -- DebugPrint('y is too large')
    return false
  end

  return true
end

function ProtectionAura:StartTouchGood(event)
  if event.activator:GetTeam() ~= DOTA_TEAM_GOODGUYS then
    if not event.activator:HasModifier("modifier_offside") then
      return event.activator:AddNewModifier(event.activator, nil, "modifier_offside", {})
    end
  end
end

function ProtectionAura:EndTouchGood(event)
  Timers:CreateTimer(1)
   if not ProtectionAura:IsInEnemyZone(teamID, entity) then
    event.activator:RemoveModifierByName("modifier_offside")
  end
end

function ProtectionAura:StartTouchBad(event)
  if event.activator:GetTeam() ~= DOTA_TEAM_BADGUYS then
    if not event.activator:HasModifier("modifier_offside") then
      return event.activator:AddNewModifier(event.activator, nil, "modifier_offside", {})
    end
  end
end


function ProtectionAura:EndTouchBad(event)
  Timers:CreateTimer(1)
  if not ProtectionAura:IsInEnemyZone(teamID, entity) then
    event.activator:RemoveModifierByName("modifier_offside")
  end
end
