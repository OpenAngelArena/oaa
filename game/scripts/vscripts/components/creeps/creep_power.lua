
--defines creep property multipliers for power levels
--nth power level corresponds to creeps spawned at minute n
--if levels are not defined, GetPowerLevelPropertyMultiplier will interpolate values
CreepPowerTable = {
  --  LEVEL     HEALTH    MANA      DAMAGE    ARMOR     GOLD      EXP
  {   0,        1.0,      1.0,      1.0,      1.0,      1.0,      1.0}
}

function AddScaleValue (minute)
  table.insert(CreepPowerTable, {
    minute, (minute ^ 2 / 100) + 1, minute, (minute / 10) + 1, minute ^ 0.5, (minute / 2) + 1, (3 * (minute^2) + (19 * minute) + 89)/89
  })
end

for minute = 1,60 do
  AddScaleValue(minute)
end

AddScaleValue(100)
AddScaleValue(500)
AddScaleValue(1000)
