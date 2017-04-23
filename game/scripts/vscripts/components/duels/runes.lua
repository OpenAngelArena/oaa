LinkLuaModifier('modifier_duel_rune_hill', 'modifiers/modifier_duel_rune_hill.lua', LUA_MODIFIER_MOTION_NONE)

-- Taken from bb template
if DuelRunes == nil then
  DebugPrint ( 'Creating new DuelRunes object.' )
  DuelRunes = class({})
  Debug.EnabledModules['duels:runes'] = true
end

--[[
 TODO: Refactor this file into a few modules so that there's less of a wall of code here
]]

function DuelRunes:Init ()
  DuelRunes.zone1 = ZoneControl:CreateZone('duel_1_rune_hill', {
    mode = ZONE_CONTROL_EXCLUSIVE_OUT,
    margin = 0,
    padding = 0,
    players = {
    }
  })

  DuelRunes.zone2 = ZoneControl:CreateZone('duel_2_rune_hill', {
    mode = ZONE_CONTROL_EXCLUSIVE_OUT,
    margin = 0,
    padding = 0,
    players = {
    }
  })

  DuelRunes.zone1.onStartTouch(DuelRunes.StartTouch)
  DuelRunes.zone1.onEndTouch(DuelRunes.EndTouch)
  DuelRunes.zone2.onStartTouch(DuelRunes.StartTouch)
  DuelRunes.zone2.onEndTouch(DuelRunes.EndTouch)

end

function DuelRunes:StartTouch(event)
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
  event.activator:AddNewModifier(event.activator, nil, "modifier_duel_rune_hill", {})
end
function DuelRunes:EndTouch(event)
  event.activator:RemoveModifierByName("modifier_duel_rune_hill")
end
