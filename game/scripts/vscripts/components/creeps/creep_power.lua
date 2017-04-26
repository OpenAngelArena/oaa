if CreepPower == nil then
  DebugPrint ( 'Creating new CreepPower object...' )
  CreepPower = class({})
end

function CreepPower:GetPowerForMinute (minute)
  local multFactor = 1

  if minute == 0 then
    return {   0,        1.0,      1.0,      1.0,      1.0,      1.0,      1.0 * self.numPlayersXPFactor}
  end

  if minute > 60 then
    multFactor = 1.5 ^ (minute - 60)
  end

  return {
    minute,                                   -- minute
    (7.5 * ((minute / 100) ^ 4) + 15 * ((minute/100) ^ 3) - 0.45 * ((minute/100) ^ 2) + 0.3 * (minute/100)) + 1,   -- hp
    (7.5 * ((minute / 100) ^ 4) + 15 * ((minute/100) ^ 3) - 0.45 * ((minute/100) ^ 2) + 0.3 * (minute/100)) + 1,   -- mana
    (30 * ((minute / 100) ^ 4) + 60 * ((minute/100) ^ 3) - 1.8 * ((minute/100) ^ 2) + 1.2 * (minute/100)) + 1,     -- damage
    (minute / 30) ^ 3 + (minute / 20) ^ 2 + minute / 5 + 1,                                                        -- armor
    (minute / 2) + 1,                         -- gold
    ((21 * minute^2 - 19 * minute + 3002) / 3002) * self.numPlayersXPFactor * multFactor -- xp
  }
end

function CreepPower:Init ()
  local maxTeamPlayerCount = 10 -- TODO: Make maxTeamPlayerCount based on values set in settings.lua (?)
  self.numPlayersXPFactor = PlayerResource:GetTeamPlayerCount() / maxTeamPlayerCount
end
