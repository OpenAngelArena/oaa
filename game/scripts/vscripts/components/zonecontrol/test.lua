
function Log (msg)
  DebugPrint ( '[zonecontrol/test] ' .. msg )
end

-- Taken from bb template
if ZoneControlTest == nil then
    Log('zone control tester is enabled!!' )
    Log('zone control tester is enabled!!' )
    Log('zone control tester is enabled!!' )
    ZoneControlTest = class({})
end

function ZoneControlTest:Init ()
  Log('starting up zone control tests')

  ZoneControlTest.lockIn = ZoneControl:CreateZone('lock_in', {
    mode = ZONE_CONTROL_EXCLUSIVE_IN,
    players = {
      [0] = true,
      [1] = true,
      [2] = true,
      [3] = true,
      [4] = true,
      [5] = true,
      [6] = true,
      [7] = true,
      [8] = true,
      [9] = true
    }
  })
  ZoneControlTest.lockOut = ZoneControl:CreateZone('lock_out', {
    mode = ZONE_CONTROL_EXCLUSIVE_OUT,
    players = {
      [0] = true,
      [1] = true,
      [2] = true,
      [3] = true,
      [4] = true,
      [5] = true,
      [6] = true,
      [7] = true,
      [8] = true,
      [9] = true
    }
  })

  ZoneControl:DisableZone(ZoneControlTest.lockIn)
  -- ZoneControl:DisableZone(ZoneControlTest.lockOut)

  ChatCommand:LinkDevCommand("-enable_lock_in", Dynamic_Wrap(ZoneControlTest, "EnableLockIn"), ZoneControlTest)

  ChatCommand:LinkDevCommand("-enable_lock_out", Dynamic_Wrap(ZoneControlTest, "EnableLockOut"), ZoneControlTest)
end

function ZoneControlTest:EnableLockIn ()
  Log('Enabling lock in!')
  local lockIn = ZoneControlTest.lockIn
  local lockOut = ZoneControlTest.lockOut

  lockOut.disable()
  lockIn.enable()
end

function ZoneControlTest:EnableLockOut ()
  Log('Enabling lock out!')
  local lockIn = ZoneControlTest.lockIn
  local lockOut = ZoneControlTest.lockOut

  lockIn.disable()
  lockOut.enable()
end
