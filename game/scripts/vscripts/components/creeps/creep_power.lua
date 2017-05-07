if CreepPower == nil then
  DebugPrint ( 'Creating new CreepPower object...' )
  CreepPower = class({})
end

function CreepPower:GetPowerForMinute (minute)
  local multFactor = 1

local ExponentialGrowthOnset = {
  [50] = 40,
  [100] = 60,
  [200] = 120
}

  if minute == 0 then
    return {   0,        1.0,      1.0,      1.0,      1.0,      1.0,      1.0 * self.numPlayersXPFactor}
  end

  if minute > ExponentialGrowthOnset[PointsManager:GetLimit()] then
    multFactor = 1.5 ^ (minute - ExponentialGrowthOnset[PointsManager:GetLimit()])
  end

  return {
    minute,                                   -- minute
    (45 * ((minute / 100) ^ 4) - 36 * ((minute/100) ^ 3) + 21 * ((minute/100) ^ 2) - 0 * (minute/100)) + 1,   -- hp
    (45 * ((minute / 100) ^ 4) - 36 * ((minute/100) ^ 3) + 21 * ((minute/100) ^ 2) - 0 * (minute/100)) + 1,   -- mana
    (180 * ((minute / 100) ^ 4) - 144 * ((minute/100) ^ 3) + 84 * ((minute/100) ^ 2) - 0 * (minute/100)) + 1,     -- damage
    (minute / 24) ^ 2 + minute / 7 + 1,       -- armor
    (minute / 2) + 1,                         -- gold
    ((21 * minute^2 - 19 * minute + 3002) / 3002) * self.numPlayersXPFactor * multFactor -- xp
  }
end

function CreepPower:Init ()
  local maxTeamPlayerCount = 10 -- TODO: Make maxTeamPlayerCount based on values set in settings.lua (?)
  self.numPlayersXPFactor = PlayerResource:GetTeamPlayerCount() / maxTeamPlayerCount
end
