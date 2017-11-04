if CreepPower == nil then
  DebugPrint ( 'Creating new CreepPower object...' )
  CreepPower = class({})
end

function CreepPower:GetPowerForMinute (minute)
  local multFactor = 1

  local ExponentialGrowthOnset = {
    short = 40,
    normal = 60,
    long = 120
  }

  if minute == 0 then
    return {   0,        1.0,      1.0,      1.0,      1.0,      1.0,      1.0 * self.numPlayersXPFactor}
  end

  if minute > ExponentialGrowthOnset[PointsManager:GetGameLength()] then
    multFactor = 1.5 ^ (minute - ExponentialGrowthOnset[PointsManager:GetGameLength()])
  end

  return CreepPower:GetBasePowerForMinute(minute, multFactor)
end

function CreepPower:GetBasePowerForMinute (minute, multFactor)
  if minute == 0 then
    return {   0,        1.0,      1.0,      1.0,      1.0,      1.0,      1.0 * self.numPlayersXPFactor}
  end

  return {
    minute,                                   -- minute
    (20 * ((minute / 100) ^ 4) - 10 * ((minute/100) ^ 3) + 28 * ((minute/100) ^ 2) + 0 * (minute/100)) + 1,   -- hp
    (20 * ((minute / 100) ^ 4) - 10 * ((minute/100) ^ 3) + 28 * ((minute/100) ^ 2) + 0 * (minute/100)) + 1,   -- mana
    (80 * ((minute / 100) ^ 4) - 40 * ((minute/100) ^ 3) + 112 * ((minute/100) ^ 2) + 0 * (minute/100)) + 1,     -- damage
    (minute / 26) ^ 2 + minute / 6 + 1,       -- armor
    (23 * minute^2 + 375 * minute + 7116)/7116,                         -- gold
    ((45 * minute^2 + 67 * minute + 2500) / 2500) * self.numPlayersXPFactor * multFactor -- xp
  }
end

function CreepPower:Init ()
  local maxTeamPlayerCount = 10 -- TODO: Make maxTeamPlayerCount based on values set in settings.lua (?)
  self.numPlayersXPFactor = 1 -- PlayerResource:GetTeamPlayerCount() / maxTeamPlayerCount
end
