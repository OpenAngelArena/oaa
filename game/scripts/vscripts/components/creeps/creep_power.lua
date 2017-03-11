
--defines creep property multipliers for power levels
--nth power level corresponds to creeps spawned at minute n
--if levels are not defined, GetPowerLevelPropertyMultiplier will interpolate values
CreepPowerTable = {
  --  LEVEL     HEALTH    MANA      DAMAGE    ARMOR     GOLD      EXP
  {   0,        1.0,      1.0,      1.0,      1.0,      1.0,      1.0}
}

function AddScaleValue (minute)
  table.insert(CreepPowerTable, {
    minute,                                   -- minute
    (minute ^ 2 / 75) + 1,                    -- hp
    minute,                                   -- mana
    (minute / 10) + 1,                        -- damage
    minute ^ 0.5,                             -- armor
    (minute / 2) + 1,                         -- gold
    (3 * (minute^2) + (19 * minute) + 89)/89  -- xp
  })
end

for minute = 1,60 do
  AddScaleValue(minute)
end

AddScaleValue(100)
AddScaleValue(500)
AddScaleValue(1000)
