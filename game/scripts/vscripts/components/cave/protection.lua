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

function ProtectionAura:StartTouchGood(event)
  if event.activator:GetTeam() ~= DOTA_TEAM_GOODGUYS then
    if not event.activator:HasModifier("modifier_offside") then
      return event.activator:AddNewModifier(event.activator, nil, "modifier_offside", {})
    end
  end
end

--[[function ProtectionAura:EndTouchGood(event)
  event.activator:RemoveModifierByName("modifier_offside")
end]]

function ProtectionAura:StartTouchBad(event)
  if event.activator:GetTeam() ~= DOTA_TEAM_BADGUYS then
    if not event.activator:HasModifier("modifier_offside") then
      return event.activator:AddNewModifier(event.activator, nil, "modifier_offside", {})
    end
  end
end


--[[function ProtectionAura:EndTouchBad(event)
  event.activator:RemoveModifierByName("modifier_offside")
end]]

