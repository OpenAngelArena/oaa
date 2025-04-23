if CreepPower == nil then
  DebugPrint ( 'Creating new CreepPower object...' )
  CreepPower = class({})
end

function CreepPower:GetPowerForMinute (minute)
  return CreepPower:GetBasePowerForMinute(minute)
end

function CreepPower:GetBasePowerForMinute (minute)
  local values = {   0,        1.0,      1.0,      1.0,      1.0,      1.0,      0.6} -- Values for first spawn (at 0:00 minute)

  if minute > 0 then
    values = {
      minute,                                                                                                           -- minute
      (24 * ((minute/100) ^ 2) + 1.5 * (minute/100)) + 1,                                                               -- hp
      (30 * ((minute/100) ^ 2) + 3 * (minute/100)) + 1,                                                                 -- mana
      (48 * ((minute/100) ^ 2) + 4.5 * (minute/100)) + 1,                                                               -- damage
      (minute / 6) + 1,                                                                                                 -- armor
      (10 * (minute/100)) + 1,                                                                                          -- gold
      ((9 * minute ^ 2 + 17 * minute + 607)/607) * 2/3                                                                  -- xp
    }
  end

  -- Lua tables start at 1; values[1] is minute;
  values[2] = self.numPlayersStatsFactor * values[2]
  values[3] = self.numPlayersStatsFactor * values[3]
  values[4] = self.numPlayersStatsFactor * values[4]
  --values[5] = self.numPlayersStatsFactor * values[5] -- Don't scale armor
  values[6] = self.BootGoldFactor * values[6]
  values[7] = self.numPlayersXPFactor * values[7]

  return values
end

-- NOT USED
function CreepPower:GetBaseCavePowerForMinute (minute)
  if minute == 0 then
    return {   0,        1.0,      1.0,      1.0,      1.0,      1.0 * self.BootGoldFactor,      1.0 * self.numPlayersXPFactor}
  end

  return {
    minute,                                                                                                           -- minute
    ((30 * ((minute/100) ^ 2) + 3 * (minute/100)) + 1) * 0.6,                                                         -- hp
    ((30 * ((minute/100) ^ 2) + 3 * (minute/100)) + 1),                                                               -- mana
    ((60 * ((minute/100) ^ 2) + 6 * (minute/100)) + 1) * 0.8,                                                         -- damage
    (minute / 6) + 1,                                                                                                 -- armor
    ((2 * minute + 15)/15) * self.BootGoldFactor,                                                                     -- gold
    ((9 * minute ^ 2 + 17 * minute + 607) / 607) * self.numPlayersXPFactor                                            -- xp
  }
end

function CreepPower:Init ()
  self.moduleName = "CreepPower (Creep Scaling)"

  local maxTeamPlayerCount = 10 -- TODO: Make maxTeamPlayerCount based on values set in settings.lua (?)
  if HeroSelection then
    if HeroSelection.is10v10 then
      maxTeamPlayerCount = 20
    end
    if HeroSelection.is6v6 then
      maxTeamPlayerCount = 12 -- alternate player count
    end
    if HeroSelection.lowPlayerCount and not HeroSelection.is10v10 and not HeroSelection.is6v6 then
      maxTeamPlayerCount = 8 -- tiny mode player count
    end
  end
  self.numPlayersXPFactor = 1 -- PlayerResource:SafeGetTeamPlayerCount() / maxTeamPlayerCount
  self.numPlayersStatsFactor = (PlayerResource:SafeGetTeamPlayerCount() + 5) / (maxTeamPlayerCount + 5)

  if PlayerResource:SafeGetTeamPlayerCount() == 1 then
    self.numPlayersStatsFactor = 1
  end

  self.BootGoldFactor = _G.BOOT_GOLD_FACTOR or 1
end
