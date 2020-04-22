if CreepPower == nil then
  DebugPrint ( 'Creating new CreepPower object...' )
  CreepPower = class({})
end

function CreepPower:GetPowerForMinute (minute)
  return CreepPower:GetBasePowerForMinute(minute)
end

function CreepPower:GetBasePowerForMinute (minute)
  local values = {   0,        1.0,      1.0,      1.0,      1.0,      1.0,      1.0}

  if minute > 0 then
    values = {
      minute,                                   -- minute
      ((0 * ((minute / 100) ^ 4) - 0 * ((minute/100) ^ 3) + 30 * ((minute/100) ^ 2) + 3 * (minute/100)) + 1) * 0.6,     -- hp
      (0 * ((minute / 100) ^ 4) - 0 * ((minute/100) ^ 3) + 30 * ((minute/100) ^ 2) + 3 * (minute/100)) + 1,             -- mana
      ((0 * ((minute / 100) ^ 4) - 0 * ((minute/100) ^ 3) + 60 * ((minute/100) ^ 2) + 6 * (minute/100)) + 1) * 0.8,     -- damage
      (0 * (minute / 26) ^ 2 + minute / 6) + 1,                                                                         -- armor
      ((0 * minute ^ 2 + 16 * minute + 49)/90),                                                                         -- gold
      ((9 * minute ^ 2 + 17 * minute + 607)/607) * 2/3                                                                  -- xp
    }
  end

  values[1] = self.numPlayersStatsFactor * values[1]
  values[2] = self.numPlayersStatsFactor * values[2]
  values[3] = self.numPlayersStatsFactor * values[3]
  values[4] = self.numPlayersStatsFactor * values[4]
  values[5] = self.BootGoldFactor * values[5]
  values[6] = self.numPlayersXPFactor * values[6]

  return values
end

function CreepPower:GetBaseCavePowerForMinute (minute)
  -- NOT USED
  if minute == 0 then
    return {   0,        1.0,      1.0,      1.0,      1.0,      1.0 * self.BootGoldFactor,      1.0 * self.numPlayersXPFactor}
  end

  return {
    minute,                                   -- minute
    ((0 * ((minute / 100) ^ 4) - 0 * ((minute/100) ^ 3) + 30 * ((minute/100) ^ 2) + 3 * (minute/100)) + 1) * 0.6,     -- hp
    ((0 * ((minute / 100) ^ 4) - 0 * ((minute/100) ^ 3) + 30 * ((minute/100) ^ 2) + 3 * (minute/100)) + 1),           -- mana
    ((0 * ((minute / 100) ^ 4) - 0 * ((minute/100) ^ 3) + 60 * ((minute/100) ^ 2) + 6 * (minute/100)) + 1) * 0.8,     -- damage
    (0 * (minute / 26) ^ 2 + minute / 6) + 1,                                                                         -- armor
    ((0 * minute ^ 2 + 2 * minute + 15)/(15)) * self.BootGoldFactor,                                                  -- gold
    ((9 * minute ^ 2 + 17 * minute + 607) / 607) * self.numPlayersXPFactor                                            -- xp
  }
end

function CreepPower:Init ()
  local maxTeamPlayerCount = 10 -- TODO: Make maxTeamPlayerCount based on values set in settings.lua (?)
  if HeroSelection.is10v10 then
    maxTeamPlayerCount = 20
  end
  self.numPlayersXPFactor = 1 -- PlayerResource:GetTeamPlayerCount() / maxTeamPlayerCount
  self.numPlayersStatsFactor = (PlayerResource:GetTeamPlayerCount() + 5) / (maxTeamPlayerCount + 5)
  self.BootGoldFactor = _G.BOOT_GOLD_FACTOR
end
