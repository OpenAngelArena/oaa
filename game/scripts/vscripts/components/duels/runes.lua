LinkLuaModifier('modifier_duel_rune_hill', 'modifiers/modifier_duel_rune_hill.lua', LUA_MODIFIER_MOTION_NONE)

-- Taken from bb template
if DuelRunes == nil then
  DebugPrint ( 'Creating new DuelRunes object.' )
  DuelRunes = class({})
  Debug.EnabledModules['duels:runes'] = true
end

function DuelRunes:Init ()

  for index,key in pairs(Duels.zones) do
    DebugPrint("Init rune hill for arena #" .. tostring(index))

    local runeHill = ZoneControl:CreateZone('duel_' .. tostring(index) .. '_rune_hill', {
      mode = ZONE_CONTROL_EXCLUSIVE_OUT,
      margin = 0,
      padding = 0,
      players = {
      }
    })

    runeHill.onStartTouch(DuelRunes.StartTouch)
    runeHill.onEndTouch(DuelRunes.EndTouch)
  end

  Duels.onEnd(function()
    Timers:RemoveTimer('DuelRunes')
  end)

  Duels.onStart(function()
    DuelRunes.active = false

    Timers:RemoveTimer('DuelRunes')
    Timers:CreateTimer('DuelRunes', {
      endTime = DUEL_RUNE_TIMER,
      callback = function()
        if not Duels.currentDuel then
          return
        end
        Notifications:TopToAll({text="#duel_highground_active", duration=10.0, style={color="red", ["font-size"]="86px"}})
        DuelRunes.active = true
      end
    })
  end)
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
  local modifier = event.activator:AddNewModifier(event.activator, nil, "modifier_duel_rune_hill", {})
  -- No idea how this can be nil if the previous line doesn't have an error, but it happens for some reason
  if modifier then
    modifier.zone = event.caller
  end
end

function DuelRunes:EndTouch(event)
  event.activator:RemoveModifierByName("modifier_duel_rune_hill")
end
