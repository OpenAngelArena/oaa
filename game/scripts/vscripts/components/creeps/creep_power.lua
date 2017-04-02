if CreepPower == nil then
  DebugPrint ( 'Creating new CreepPower object...' )
  CreepPower = class({})
end

function CreepPower:AddScaleValue (minute)
  table.insert(self.PowerTable, {
    minute,                                   -- minute
    ((minute / 8) ^ 2 / 75) + 1,              -- hp
    minute,                                   -- mana
    (minute / 20) + 1,                        -- damage
    minute ^ 0.5,                             -- armor
    (minute / 2) + 1,                         -- gold
    ((21 * minute^2 - 19 * minute + 3002) / 3002) * self.numPlayersXPFactor --xp
  })
end

function CreepPower:Init ()
  local maxTeamPlayerCount = 10 -- TODO: Make maxTeamPlayerCount based on values set in settings.lua (?)
  self.numPlayersXPFactor = PlayerResource:GetTeamPlayerCount() / maxTeamPlayerCount

  --defines creep property multipliers for power levels
  --nth power level corresponds to creeps spawned at minute n
  --if levels are not defined, GetPowerLevelPropertyMultiplier will interpolate values
  self.PowerTable = {
    --  LEVEL     HEALTH    MANA      DAMAGE    ARMOR     GOLD      EXP
    {   0,        1.0,      1.0,      1.0,      1.0,      1.0,      1.0 * self.numPlayersXPFactor}
  }

  for minute = 1,60 do
    self:AddScaleValue(minute)
  end

  self:AddScaleValue(100)
  self:AddScaleValue(500)
  self:AddScaleValue(1000)
end
