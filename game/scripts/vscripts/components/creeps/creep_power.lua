
--defines creep property multipliers for power levels
--if levels are not defined, GetPowerLevelPropertyMultiplier will interpolate values
CreepPowerTable = {
  --  LEVEL     HEALTH    MANA      DAMAGE    ARMOR     GOLD      EXP
  {   0,        0.0,      0.0,      0.0,      0.0,      0.0,      0.0},
  {   1,        1.0,      1.0,      1.0,      1.0,      1.0,      1.0},
  {   3,        1.2,      1.0,      1.0,      1.0,      2.0,      1.2},
  {   1000,     100.0,    100.0,    100.0,   100.0,     500.5,    100.0}
}
