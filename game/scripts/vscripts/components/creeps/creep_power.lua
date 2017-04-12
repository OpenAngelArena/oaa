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
    ((minute / 8) ^ 2 / 75) + 1,              -- hp
    minute,                                   -- mana
    (minute / 20) + 1,                        -- damage
    minute ^ 0.5,                             -- armor
    (minute / 2) + 1,                         -- gold
    ((21 * minute^2 - 19 * minute + 3002) / 3002) * self.numPlayersXPFactor * multFactor -- xp
  }
end

function CreepPower:Init ()
  local maxTeamPlayerCount = 10 -- TODO: Make maxTeamPlayerCount based on values set in settings.lua (?)
  self.numPlayersXPFactor = PlayerResource:GetTeamPlayerCount() / maxTeamPlayerCount
end
