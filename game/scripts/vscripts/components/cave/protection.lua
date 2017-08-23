LinkLuaModifier('modifier_offside', 'modifiers/modifier_offside.lua', LUA_MODIFIER_MOTION_NONE)

if ProtectionAura == nil then
  DebugPrint ( 'Creating new ProtectionAura object.' )
  ProtectionAura = class({})
  Debug.EnabledModules['cave:protection'] = true
end

function ProtectionAura:Init ()
  ProtectionAura.zone1 = ZoneControl:CreateZone('boss_good_zone_0', {
    mode = ZONE_CONTROL_EXCLUSIVE_OUT,
    margin = 0,
    padding = 0,
    players = {}
  })

  ProtectionAura.zone2 = ZoneControl:CreateZone('boss_bad_zone_0', {
    mode = ZONE_CONTROL_EXCLUSIVE_OUT,
    margin = 0,
    padding = 0,
    players = {}
  })

  ProtectionAura.zone1.onStartTouch(ProtectionAura.StartTouchGood)
  ProtectionAura.zone1.onEndTouch(ProtectionAura.EndTouchGood)
  ProtectionAura.zone2.onStartTouch(ProtectionAura.StartTouchBad)
  ProtectionAura.zone2.onEndTouch(ProtectionAura.EndTouchBad)

  ProtectionAura.active = true
end

function ProtectionAura:StartTouchGood(event)
  if event.activator:GetTeam() ~= DOTA_TEAM_GOODGUYS then
  return event.activator:AddNewModifier(event.activator, nil, "modifier_offside", {})
  end
end

function ProtectionAura:EndTouchGood(event)
  event.activator:RemoveModifierByName("modifier_offside")
end

function ProtectionAura:StartTouchBad(event)
  if event.activator:GetTeam() ~= DOTA_TEAM_BADGUYS then
    return event.activator:AddNewModifier(event.activator, nil, "modifier_offside", {})
  end
end

function ProtectionAura:EndTouchBad(event)
  event.activator:RemoveModifierByName("modifier_offside")
end

